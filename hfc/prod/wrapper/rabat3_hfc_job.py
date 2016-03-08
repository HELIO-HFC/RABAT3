#! /usr/bin/env python
# -*- coding: latin-1 -*-

import os,sys
import subprocess
import time, logging
from datetime import datetime, timedelta
from waves import waves,swaves
from frc_toolkit import ordered_dict, parse_configfile, write_csv
from ssw import tim2jd, tim2carr

# Institut information
CODE = "RABAT3"

# RABAT3 Version
VERSION = "2.03"

# RUN DATE
RUN_DATE = datetime.today()

# Default paths
CURRENT_DIRECTORY=os.getcwd()
OUTPUT_DIRECTORY=CURRENT_DIRECTORY
DATA_DIRECTORY=CURRENT_DIRECTORY

# Date and time formats
HELIO_TFORMAT = '%Y-%m-%dT%H:%M:%S'
OUTPUT_TFORMAT = '%Y%m%dT%H%M%S'

# IDL executable path
IDL_EXE_PATH = "idl"

# Open logger
RABAT3_HFC_LOGGER="rabat3_hfc_processing"
LOG=logging.getLogger(RABAT3_HFC_LOGGER)

class processing():
	
	def __init__(self,idl_bin_file,
                 code=CODE,version=VERSION,
                 data_directory=DATA_DIRECTORY,
                 output_directory=OUTPUT_DIRECTORY):
	
		self.code = code
		self.version = version
		self.observatory=""
		self.idl_bin_file=idl_bin_file
		self.config_file=""
		self.args = dict()
		self.dataset = None
		self.output_file=""
		self.data_directory = data_directory
		self.output_directory = output_directory
		
	def load_config(self,config_file):
		self.args = parse_configfile(config_file)
		observatory = self.args["OBSERVATORY"].lower()	
		
		if (observatory == "wind"):
			self.observatory="win"
			self.data_set = waves(receiver="rad2")
		elif (observatory == "stereo_a"):
			self.observatory="sta"
			self.data_set = swaves(receiver="hfr")
		elif (observatory == "stereo_b"):
			self.observatory="stb"
			self.data_set = swaves(receiver="hfr")
		elif (observatory == "nancay"):
			self.observatory="nan"
			self.data_set = nda()
		
		if (len(self.args) > 0):
			self.config_file=config_file
			return True
		else:
			return False

	# Method to build the list of data files to process			
	def build_filelist(self,starttime,endtime):
		data_set = self.data_set
		data_directory = self.data_directory
		
		dateList = [starttime] 
		fileList = [os.path.join(data_directory,data_set.get_filename(starttime))]
		while (dateList[-1] < endtime):
			next_date = dateList[-1] + timedelta(days=1)
			fileList.append(os.path.join(data_directory,data_set.get_filename(next_date)))
			dateList.append(next_date)			
		return fileList

# Method to execute the RABAT3 code in a IDL session
	def run_idl(self,data_file,
		    output_file=None):
		
		if not (os.path.isfile(data_file)):
			LOG.error("%s does not exist, please check!",data_file)
			return None

		rabat3_idl_bin=self.idl_bin_file
		if not (os.path.isfile(rabat3_idl_bin)):
			LOG.error("%s does not exist, please check!",rabat3_idl_bin)
			return None

		if (output_file is None):
			filename = "_".join(["rabat3",
					     "".join(str(self.version).split(".")),
					     str(long(time.time())),
					     self.observatory,"feat"])+".csv"
			output_file = os.path.join(self.output_directory,
						   filename)

		idl_args = [data_file,self.config_file,
			    "output_file="+output_file]
		idl_args.append("/VERBOSE")	

		idl_cmd = [IDL_EXE_PATH]+["-quiet","-rt="+rabat3_idl_bin,"-args"]
		idl_cmd.extend(idl_args)
		LOG.info("Running --> "+ " ".join(idl_cmd))
		idl_process = subprocess.Popen(idl_cmd, 
					       stdout=subprocess.PIPE,
					       stderr=subprocess.PIPE)
		output, errors = idl_process.communicate()
		if (idl_process.wait() == 0):
			if not (os.path.isfile(output_file)):
				LOG.error("%s has not been saved correclty, please check!",output_file)
				LOG.error("Error running idl command %s, output: %s, errors: %s" %
				  (' '.join(idl_cmd), str(output), str(errors)))
				return False
			self.output_file=output_file
			return True
		else:
			LOG.error("Error running idl command %s, output: %s, errors: %s" %
				  (' '.join(idl_cmd), str(output), str(errors)))
			return False
	
# Class to deal with the HFC outputs 	
class hfc():
	
	def __init__(self):
		self.observatory=[]
		self.frc_info=[]
		self.observations=[]
		self.features=[]

        # Fill a HFC table list
	def add_row(self,table_name,**kwarg):
		table = table_name.lower()
		
		if (table in self.__dict__):
			current_dict = dict()
			for key,value in kwarg.iteritems(): 
				current_dict[key.upper()] = value
			self.__dict__[table].append(current_dict)
			return True
		else:
			return False
					
