#! /usr/bin/env python
# -*- coding: latin-1 -*-

"""
Python program to run the RABAT3 code in the framework of the HFC.
@author: X.Bonnin (LESIA)
"""
__author__="Xavier Bonnin"
__date__="08-MAY-2013"
__version__ = "2.03"


import os, sys, subprocess, socket
from datetime import datetime, timedelta
import time, threading
import logging, copy
import argparse, csv
	
from rabat3_hfc_job import processing, hfc
from frc_toolkit import ordered_dict, setup_logging, write_csv, \
    check_history
from ssw import tim2jd, tim2carr
from waves import split_time
	
# Code information
FRC_META={}
FRC_META['CODE'] = "RABAT3"
FRC_META['INSTITUT'] = "OBSPM"
FRC_META['PERSON'] = "Xavier Bonnin"
FRC_META['CONTACT'] = "xavier.bonnin@obspm.fr"
FRC_META['FEATURE'] = "TYPE III"
FRC_META['ENC_MET'] = "CHAINCODE"
FRC_META['REFERENCE'] = "doi:10.1029/2008SW000425"

# RABAT3 Version
FRC_META['VERSION'] = __version__

# Dates and times
LAUNCH_TIME = time.time()
TODAY = datetime.today()
INPUT_TFORMAT = '%Y%m%d'
OUTPUT_TFORMAT = '%Y%m%dT%H%M%S'
WIND_TFORMAT = '%Y%m%d'
HELIO_TFORMAT = '%Y-%m-%dT%H:%M:%S'

# Current directory
CURRENT_DIRECTORY=os.getcwd()
OUTPUT_DIRECTORY=CURRENT_DIRECTORY
DATA_DIRECTORY=CURRENT_DIRECTORY

# Hostname
HOSTNAME = socket.gethostname()

RABAT3_HFC_LOGGER="rabat3_hfc_processing"

# Wind/Waves Rad2 meta-data
WIN_META={}
WIN_META['ID_OBSERVATORY']=1
WIN_META['OBSERVAT']="Wind"
WIN_META['INSTRUME']="Waves"
WIN_META['TELESCOP']="Rad2"
WIN_META['UNITS']="dB above background"
WIN_META['WAVEMIN']="1.075"
WIN_META['WAVEMAX']="13.825"
WIN_META['WAVENAME']="Decametric/Hectometric"
WIN_META['WAVEUNIT']="MHz"
WIN_META['SPECTRAL_NAME']="Radio"
WIN_META['OBS_TYPE']="Remote-sensing"
WIN_META['COMMENT']="NULL"		
# STEREO_A/Swaves HFR meta-data
STA_META={}
STA_META['ID_OBSERVATORY']=1
STA_META['OBSERVAT']="STEREO_A"
STA_META['INSTRUME']="Swaves"
STA_META['TELESCOP']="HFR"
STA_META['UNITS']="dB above background"
STA_META['WAVEMIN']="0.125"
STA_META['WAVEMAX']="16.025"
STA_META['WAVENAME']="Decametric/Hectometric"
STA_META['WAVEUNIT']="MHz"
STA_META['SPECTRAL_NAME']="Radio"
STA_META['OBS_TYPE']="Remote-sensing"
STA_META['COMMENT']="NULL"
# STEREO_B/Swaves HFR meta-data
STB_META={}
STB_META['ID_OBSERVATORY']=1
STB_META['OBSERVAT']="STEREO_B"
STB_META['INSTRUME']="Swaves"
STB_META['TELESCOP']="HFR"
STB_META['UNITS']="dB above background"
STB_META['WAVEMIN']="0.125"
STB_META['WAVEMAX']="16.025"
STB_META['WAVENAME']="Decametric/Hectometric"
STB_META['WAVEUNIT']="MHz"
STB_META['SPECTRAL_NAME']="Radio"
STB_META['OBS_TYPE']="Remote-sensing"
STB_META['COMMENT']="NULL"	
# Nancay decametric array meta-data
NAN_META={}
NAN_META['ID_OBSERVATORY']=1
NAN_META['OBSERVAT']="Nancay"
NAN_META['INSTRUME']="Decametric Array"
NAN_META['TELESCOP']="ASB"
NAN_META['UNITS']="dB above background"
NAN_META['WAVEMIN']="0.125"
NAN_META['WAVEMAX']="16.025"
NAN_META['WAVENAME']="Decametric"
NAN_META['WAVEUNIT']="MHz"
NAN_META['SPECTRAL_NAME']="Radio"
NAN_META['OBS_TYPE']="Remote-sensing"
NAN_META['COMMENT']="NULL"


# Method to setup RABAT3
def setup_rabat3(idl_bin_file,config_file,
                 code=FRC_META['CODE'],
                 version=FRC_META['VERSION'],
                 data_directory=DATA_DIRECTORY,
                 output_directory=OUTPUT_DIRECTORY):
		     	 
	rabat3_instance = processing(idl_bin_file,
                                 code=code,version=version,
                                 data_directory=data_directory,
                                 output_directory=output_directory)
	if (rabat3_instance.load_config(config_file)):
		LOG.info("Configuration file loaded: %s",config_file)
	else:
		LOG.error("Can not read the configuration file: %s!",config_file)
	
	return rabat3_instance

# Class to run the RABAT3 IDL code
class run_rabat3(threading.Thread):

    def __init__(self,file,job,hfc,
                 output_file=None,
                 thread_id=1,
                 quicklook=True,
                 download_data=True,
                 remove_data=False):
		
        threading.Thread.__init__(self)
        self.terminated =False
        self.success=False
        self._stopevent = threading.Event()
	
        self.thread_id = thread_id
        self.file = file
        self.job = job
        self.hfc=hfc
        self.output_file = output_file
        self.quicklook = quicklook
        self.download_data=download_data
        self.remove_data=remove_data
				 
	def run(self):
	
		file = self.file
		job = self.job
		hfc = self.hfc
		output_file = self.output_file 
		
		obs = job.observatory ; code = job.code.lower()
        version = job.version
        ver = "".join(str(version).split("."))

		# Get url of the data provider
        url = job.data_set.get_url(filename=file)

		# Read data file
        LOG.info("Loading data file %s...",file)
        data = job.data_set.get_data(filename=file,
                                     data_directory=self.job.data_directory,
                                     download_file=self.download_data,
                                     delete_file=False,
                                     verbose=False,prep=True,
                                     dB=True,interpolate=True)
        if (data is None):
            LOG.error("Can not load %s!",file)
            self.terminated = True
            return False
        else:
            LOG.info("Loading data file %s...done",file)

		# Write quicklook file is asked
        if (self.quicklook):
            LOG.info("Saving quicklook image...")
            qclk_path = job.data_set.write_img(filename=file,data=data,
                                               min_val=1,max_val=10,
                                               data_directory=self.job.data_directory,
                                               output_directory=self.job.output_directory,
                                               download_file=False,
                                               verbose=False,prep=False)
            if (os.path.isfile(qclk_path)):
				LOG.info("%s saved",qclk_path)
				LOG.info("Saving quicklook image...done")
            else:
				LOG.warning("Quicklook has not been saved correctly!",qclk_path)
        else:
			qclk_path="NULL"
				
		
		# Writing a CSV format file containing the observations meta-data
        jdint,jdfrac = tim2jd(data.date_obs)
        c_rotation = int(tim2carr(data.date_obs,DC=True))
        table_name = "OBSERVATIONS"
        if not (hfc.add_row(table_name,
                            id_observations=1,observatory_id=1,
                            date_obs=data.date_obs.strftime(HELIO_TFORMAT),
                            date_end=data.date_end.strftime(HELIO_TFORMAT),
                            jdint=jdint,jdfrac=jdfrac,
                            c_rotation=c_rotation,
                            cdelt1=data.cdelt[0],cdelt2=data.cdelt[1],
                            naxis1=data.naxis[0],naxis2=data.naxis[1],
                            center_x=data.naxis[0]/2,center_y=data.naxis[1]/2,
                            url=url,filename=os.path.basename(file),
                            loc_filename=file,
                            qclk_fname=os.path.basename(qclk_path),
                            comment=data.comment,
                            bscale="NULL",bzero="NULL",
                            bitpix="NULL",exp_time="NULL",
                            quality="NULL",r_sun="NULL")):
			LOG.error("hfc_instance has no attribute %s!",table_name)
			sys.exit(1)

        fieldnames = ["ID_OBSERVATIONS","OBSERVATORY_ID","DATE_OBS","DATE_END","JDINT",
                      "JDFRAC","C_ROTATION","BSCALE","BZERO","BITPIX","EXP_TIME",
                      "NAXIS1","NAXIS2","CDELT1","CDELT2","R_SUN","CENTER_X","CENTER_Y",
                      "QUALITY","FILENAME","FILE_FORMAT","COMMENT","LOC_FILENAME","URL",
                      "QCLK_FNAME","QCLK_URL"]

        output_filename = "_".join([code,ver,obs,data.date_obs.strftime(OUTPUT_TFORMAT),"init"])+".csv"
        output_path = os.path.join(output_directory,output_filename)
        if not (write_csv(hfc.observations,output_path,fieldnames=fieldnames)):
			LOG.error("%s has not been written correctly!",output_path)
			sys.exit(1)
        else:
			LOG.info("%s saved",output_path)
			

		# Run rabat3 in a IDL session using pidly
        LOG.info("Running rabat3 code in IDL...")
        output_filename= "_".join([code,ver,obs,data.date_obs.strftime(OUTPUT_TFORMAT),"feat"])+".csv"
        output_path = os.path.join(output_directory,output_filename)
        success = job.run_idl(file,output_file=output_path)
        LOG.info("Running rabat3 code in IDL...done")

		# Write rabat3 detection results in a CSV format file
        table_name = "FEATURES"
        if (success) and (os.path.isfile(job.output_file)):
            nfeat=0
			with open(job.output_file) as fr:
				reader = csv.DictReader(fr, delimiter=';')
				for i,current_row in enumerate(reader):
					if ((current_row['CC'] != "NULL") and
					    (len(current_row['CC']) != 0)):
						hh_start, mm_start, ss_start=split_time(current_row['TIME_START'])
						hh_end, mm_end, ss_end=split_time(current_row['TIME_END'])
						time_start="T".join([data.date_obs.split("T")[0],hms_start])
						time_end="T".join([data.date_obs.split("T")[0],hms_end])
						if not (hfc.add_row(table_name,
								    id_type_iii=i+1,
								    frc_info_id=1,
								    observations_id=1,
								    cc_x_pix=current_row['CC_X_PIX'],
								    cc_y_pix=current_row['CC_Y_PIX'],
								    cc_x_utc=current_row['CC_X_UTC'],
								    cc_y_utc=current_row['CC_Y_MHZ'],
								    cc=current_row['CC'],
								    cc_length=len(current_row['CC']),
								    ske_cc_x_pix=current_row['SKE_CC_X_PIX'],
								    ske_cc_y_pix=current_row['SKE_CC_Y_PIX'],
								    ske_cc_x_utc=current_row['SKE_CC_X_UTC'],
								    ske_cc_y_utc=current_row['SKE_CC_Y_MHZ'],
								    ske_cc=current_row['SKE_CC'],
								    ske_cc_length=len(current_row['SKE_CC']),
								    br_x0_pix=current_row['BR_X0_PIX'],
								    br_y0_pix=current_row['BR_Y0_PIX'],
								    br_x1_pix=current_row['BR_X0_PIX'],
								    br_y1_pix=current_row['BR_Y3_PIX'],
								    br_x2_pix=current_row['BR_X3_PIX'],
								    br_y2_pix=current_row['BR_Y0_PIX'],
								    br_x3_pix=current_row['BR_X3_PIX'],
								    br_y3_pix=current_row['BR_Y3_PIX'],
								    br_x0_utc=current_row['BR_X0_UTC'],
								    br_y0_utc=current_row['BR_Y0_MHZ'],
								    br_x1_utc=current_row['BR_X0_UTC'],
								    br_y1_utc=current_row['BR_Y3_MHZ'],
								    br_x2_utc=current_row['BR_X3_UTC'],
								    br_y2_utc=current_row['BR_Y0_MHZ'],
								    br_x3_utc=current_row['BR_X3_UTC'],
								    br_y3_utc=current_row['BR_Y3_MHZ'],
								    time_start=time_start,
								    time_end=time_end,
								    feat_max_int=current_row['FEAT_MAX_INT'],
								    feat_mean_int=current_row['FEAT_MEAN_INT'],
								    fit_a0=current_row['FIT_A0'],
								    fit_a1=current_row['FIT_A1'],
								    drift_start=current_row['DRIFT_START'],
								    drift_end=current_row['DRIFT_END'],
								    lvl_trust=current_row['LVL_TRUST'],
								    mulitple=1,
								    snapshot_fn="NULL",
								    snapshot_path="NULL",
								    feat_filename=output_path,
								    helio_id="NULL",
								    run_date=TODAY.strftime(HELIO_TFORMAT))):
								LOG.error("hfc_instance has no attribute %s!",table_name)
								sys.exit(1)
						else:
							nfeat+=1
                                                        
                        ## List of the feature parameters to save into a csv format file
 			fieldnames=["ID_TYPE_III","FRC_INFO_ID","OBSERVATIONS_ID","CC_X_PIX","CC_Y_PIX","CC_X_UTC","CC_Y_MHZ",
				    "CC","CC_LENGTH","SKE_CC_X_PIX","SKE_CC_Y_PIX","SKE_CC_X_UTC","SKE_CC_Y_MHZ",
				    "SKE_CC","SKE_CC_LENGTH","BR_X0_PIX","BR_Y0_PIX","BR_X1_PIX","BR_Y1_PIX",
				    "BR_X2_PIX","BR_Y2_PIX","BR_X3_PIX","BR_Y3_PIX","BR_X0_UTC","BR_Y0_MHZ",
				    "BR_X1_UTC","BR_Y1_MHZ","BR_X2_UTC","BR_Y2_MHZ","BR_X3_UTC","BR_Y3_MHZ",
				    "TIME_START","TIME_END","FEAT_MAX_INT","FEAT_MEAN_INT","FIT_A0","FIT_A1",
				    "DRIFT_START","DRIFT_END","LVL_TRUST","MULTIPLE","SNAPSHOT_FN","SNAPSHOT_PATH",
				    "FEAT_FILENAME","HELIO_ID","RUN_DATE"]
			
			if (nfeat > 0):
				if not (write_csv(hfc.features,output_path,fieldnames=fieldnames)):
					LOG.error("%s has not been written correctly!",output_path)
					sys.exit(1)
				else:
					LOG.info("%s saved",output_path)
			else:
				LOG.info("No feature extracted from %s",file)
				os.remove(job.output_file)
				

		if (self.remove_data):
			if (os.path.isfile(file)): 
				os.remove(file)
				LOG.info("%s deleted",file)

		time.sleep(0.1)
		self.success=success
		self.terminated = True	
		
	def stop(self):
		self._stopevent.set()
    	
	def setTerminated(self,terminated):
		self.terminated = terminated
	

	
if (__name__ == "__main__"):

	parser = argparse.ArgumentParser(add_help=True,conflict_handler="resolve")
	parser.add_argument('config_file',nargs=1,help="Pathname of the configuration file to load.")
	parser.add_argument('-s','--starttime',nargs='?', 
                        default=None,
                        help="First date of the the time range to process.")
	parser.add_argument('-e','--endtime',nargs='?',
                        default=None,
                        help="Last date of the time range to process.")
	parser.add_argument('-p','--processings',nargs='?',default=1,type=int,
                        help='Number of processings allowed to run in the same time.')
	parser.add_argument('-i','--idl_bin_file',nargs='?',
                        default=IDL_BIN_FILE,
                        help="Pathname of the IDL binary file used to run rabat3.")
	parser.add_argument('-o','--output_directory',nargs='?',
                        default=CURRENT_DIRECTORY,help="output directory.")
	parser.add_argument('-d','--data_directory',nargs='?',
                        default=CURRENT_DIRECTORY,help="data directory.")
	parser.add_argument('-h','--history_file',nargs='?',default=None,
                        help='Pathname of the rabat3 history file used to check processed data files.')
	parser.add_argument('-l','--log_file',nargs='?',default=None,
                        help="Pathname of the log file to create.")
	parser.add_argument('-Q','--Quicklook',action='store_true',help='produce quicklook images')
	parser.add_argument('-D','--Download_data',action="store_true",
                        help="If set, download data file from a distant server.")
	parser.add_argument('-R','--Remove_data',action="store_true",
                        help="If set, remove data file after processing.")
	parser.add_argument('-V','--Verbose',action="store_true",help="Verbose mode.")
	
	Namespace = parser.parse_args()
	config_file = Namespace.config_file[0]
	starttime = Namespace.starttime
	endtime = Namespace.endtime
	processings = Namespace.processings
	idl_bin_file = Namespace.idl_bin_file
	output_directory = Namespace.output_directory
	data_directory = Namespace.data_directory
	history_file = Namespace.history_file
	quicklook = Namespace.Quicklook
	download = Namespace.Download_data
	remove = Namespace.Remove_data
	verbose = Namespace.Verbose
	log_file = Namespace.log_file
	

	if (starttime is None) and (endtime is not None):
		endtime = datetime.strptime(endtime,INPUT_TFORMAT)
		starttime = endtime - timedelta(days=7)
	elif (starttime is not None) and (endtime is None):
		starttime = datetime.strptime(starttime,INPUT_TFORMAT)
		endtime = starttime + timedelta(days=7)
	elif (starttime is not None) and (endtime is not None):
		starttime = datetime.strptime(starttime,INPUT_TFORMAT)
		endtime = datetime.strptime(endtime,INPUT_TFORMAT)
	else:
		endtime = TODAY
		starttime = endtime - timedelta(days=7)
	
	# Setup the logging
	setup_logging(filename=log_file,quiet = False, verbose = verbose)	

	# Create a logger 
	global LOG
	LOG=logging.getLogger(RABAT3_HFC_LOGGER)

	if (history_file is None):
		history_file = os.path.join(output_directory,"rabat3_hfc_%s.history" \
									% (TODAY.strftime(OUTPUT_TFORMAT)))
		LOG.info("Creating a new history file: %s",history_file)
	else:
		LOG.info("%s history file already exists",history_file)

	# Create an instance of rabat3_hfc_job with the given input parameters
	rabat3_job = setup_rabat3(config_file,
                              idl_bin_file=idl_bin_file,
                              output_directory=output_directory,
                              data_directory=data_directory)
	obs = rabat3_job.observatory ; code = rabat3_job.code.lower()
	ver = "".join(str(VERSION).split("."))
	
		
	# Load meta-data for the current observatory
	if (rabat3_job.observatory == "win"):
		obyDict = WIN_META
	elif (rabat3_job.observatory == "sta"):
		obyDict = STA_META
	elif (rabat3_job.observatory == "stb"):
		obyDict = STB_META
	elif (rabat3_job.observatory == "nan"):
		obyDict = NAN_META
	else:
		LOG.error("Unknown observatory: %s!",rabat3_job.observatory)
		sys.exit(1)
				  
  	# Create an HFC instance for outputs
  	hfc_instance = hfc()

	# Write a CSV format file containing the Observatory meta-data
	table_name = "OBSERVATORY"
	if not (hfc_instance.add_row(table_name,
				     id_observatory=obyDict['ID_OBSERVATORY'],
				     observat=obyDict['OBSERVAT'],
				     instrume=obyDict['INSTRUME'],
				     telescop=obyDict['TELESCOP'],
				     units=obyDict['UNITS'],
				     wavemin=obyDict['WAVEMIN'],
				     wavemax=obyDict['WAVEMAX'],
				     wavename=obyDict['WAVENAME'],
				     waveunit=obyDict['WAVEUNIT'],
				     spectral_name=obyDict['SPECTRAL_NAME'],
				     obs_type=obyDict['OBS_TYPE'],
				     comment=obyDict['COMMENT'])):
		LOG.error("hfc_instance has no attribute %s!",table_name)
		sys.exit(1)

        fieldnames = ["ID_OBSERVATORY","OBSERVAT","INSTRUME","TELESCOP","UNITS","WAVEMIN","WAVEMAX",
                      "WAVENAME","WAVEUNIT","SPECTRAL_NAME","OBS_TYPE","COMMENT"]

	output_filename = "_".join([code,ver,obs,"observatory"])+".csv"
	output_path = os.path.join(output_directory,output_filename)
  	if not (write_csv(hfc_instance.observatory,output_path,fieldnames=fieldnames)):
            LOG.error("%s has not been written correctly!",output_path)
            sys.exit(1)
	else:
            LOG.info("%s saved",output_path)


	# Write a CSV format file containing the frc_info meta-data
	table_name = "FRC_INFO"
	if not (hfc_instance.add_row(table_name,
				     id_frc_info=1,code=code.upper(),
				     version=VERSION,enc_met=ENC_MET,
				     institut=INSTITUT,person=PERSON,
				     feature_name=FEATURE,contact=CONTACT,
				     reference=REFERENCE)):
		LOG.error("hfc_instance has no attribute %s!",table_name)
		sys.exit(1)

	fieldnames = ["ID_FRC_INFO","INSTITUT","CODE","VERSION","FEATURE_NAME","ENC_MET","PERSON",
                      "CONTACT","REFERENCE"]

	output_filename = "_".join([code,ver,obs,"frc_info"])+".csv"
	output_path = os.path.join(output_directory,output_filename)
  	if not (write_csv(hfc_instance.frc_info,output_path,fieldnames=fieldnames)):
            LOG.error("%s has not been written correctly!",output_path)
            sys.exit(1)
	else:
            LOG.info("%s saved",output_path)

	fileList = rabat3_job.build_filelist(starttime,endtime)
	if (len(fileList) == 0):
		LOG.warning("Empty file set!")
		sys.exit()
	else:
		LOG.info("%i file(s) to process",len(fileList))

	# Check if the data files have been already processed in the history file
	if (os.path.isfile(history_file)):
		processed, unprocessed = check_history(history_file,fileList,log=LOG)
		if not (unprocessed):
			LOG.warning("All of the files have been already processed.")
			sys.exit(0)
		else:
			fileList = list(unprocessed)
			del unprocessed
			LOG.info("%i file(s) to process.",len(fileList))
			
	#Initialize rabat3 threads for the unprocessed files
	threadList = []
	for i,current_file in enumerate(fileList):
		threadList.append(run_rabat3(current_file,rabat3_job,
                                             copy.deepcopy(hfc_instance),
                                             thread_id=i+1,
                                             quicklook=quicklook,
                                             download_data=download,
                                             remove_data=remove))

	nthread = len(threadList) 
	if (nthread == 0):
		LOG.warning("Empty processing list!")
		sys.exit(1)
	else:
		LOG.info("%i processings to run.",nthread)
	

	# Launch rabat3 sessions
	LOG.info("Starting rabat3 executions...")
	running = []
	nremaining = nthread 
	for current_thread in threadList:
		if (len(running) < nprocessings):
			LOG.info("Processing %s (%i) - started on %s",
					 current_thread.file, 
					 current_thread.thread_id,
					 datetime.today().strftime(HELIO_TFORMAT))
			LOG.info("%i/%i current running/remaining executions(s).",
					 len(running),nremaining)
			current_thread.start()
			running.append(current_thread)
			nremaining-=1	
			time.sleep(3)			
		
		i=0
		while(len(running) >= nprocessings):
			if (running[i].terminated):
				if (running[i].success):
					fw = open(history_file,'a')
					fw.write(running[i].file+"\n")
					fw.close()
					LOG.info("Processing %s (%i) - done on %s",
					 	     current_thread.file, 
					         current_thread.thread_id,
					         datetime.today().strftime(HELIO_TFORMAT))
				else:
					LOG.error("Processing %s (%i) - failed on %s",
					 	     current_thread.file, 
					         current_thread.thread_id,
					         datetime.today().strftime(HELIO_TFORMAT))
				running.remove(running[i])
				time.sleep(3)
			i=(i+1)%nprocessings

	LOG.info("Rabat3 executions completed")
	LOG.info("Total elapsed time: %f min.",(time.time() - LAUNCH_TIME)/60.0)
				
