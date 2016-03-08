PRO rabat3_hfc_launcher,starttime,endtime,$
                        inputs_file=inputs_file,$
                        data_dir=data_dir,$
                        script_dir=script_dir,$
                        input_dir=input_dir,$
                        output_dir=output_dir,$
                        username=username,password=password, $
                        write_fits=write_fits,$
                        write_png=write_png, $
                        WAV_RAD1=WAV_RAD1,WAV_RAD2=WAV_RAD2,$
                        SWA_HFR=SWA_HFR,SWB_HFR=SWB_HFR,$
                        NAN_DAM=NAN_DAM,$
                        WRITE_CSV=WRITE_CSV,$
                        CLEAN_DATA=CLEAN_DATA,$
                        DOWNLOAD_DATA=DOWNLOAD_DATA,$
                        NOLOG=NOLOG,SILENT=SILENT,DEBUG=DEBUG

;+
; NAME:
;		rabat3
;
; PURPOSE:
; 		Launcher for the rabat3 software. 
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		RABAT3
;
; CALLING SEQUENCE:
;		IDL>rabat3_launcher,starttime,endtime
;
; INPUTS:
;		starttime   - First date of time range to process.
;					  (Format is YYYY-MM-DD.)
;		endtime     - Last date of time range to process.
;					  (Format is YYYY-MM-DD.) 
;	
; OPTIONAL INPUTS:
;		inputs_file		- Scalar of string type containing the name of the file
;					      where the inputs for the code are written.
;		data_dir		- Scalar of string type providing the path to the input data file directory.
;		input_dir 		- Scalar of string type providing the path to the inputs file directory.
;		script_dir		- Scalar of string type providing the path to the scripts directory.
;		trange			- 2 elements vector of double type containing the time range (in UTC)
;						  to process for the input dynamical spectrum.
;		write_fits 		- Define type of fits file to produce:
;							write_fits = 0 -> No fits file produced.
;							write_fits = 1 -> Only dynamical spectrum is returned.
;							write_fits = 2 -> dynamical spectrum + detection results.
;							write_fits = 3 -> Produce both fits files 
;											  (i.e., one file with dyn. spect. only, and
;											   an other with dyn. spect. + detection results).
;		output_dir      - Scalar of string type containing the path to the 
;					      directory where output data files will be saved.
;					      (If output_dir is not specified, then the program
;					      will create a directory Products in the current 
;					      folder.)
;		write_png       - Write png image file:
;							 write_png = 1 --> write only the cleaned dynamical spectrum 
;							 write_png = 2 --> write the cleaned dynamical spectrum +
;											   detection results
;       username        - User name to loggin the Nancay/DAM data ftp server.
;       password        - Password to loggin the Nancay/DAM data ftp server.
;
; KEYWORD PARAMETERS:
;		/WAV_RAD1      - Process Wind/Waves/Rad1 data.
;		/WAV_RAD2      - Process Wind/Waves/Rad2 data.
;		/SWA_HFR       - Process STEREO_A/Swaves/HFR data.
;		/SWB_HFR       - Process STEREO_B/Swaves/HFR data.
;		/NAN_DAM       - Process Nancay/DAM/ASB data.
;		/DOWNLOAD_DATA - allow program to use wget command to download data
;						 from distant ftp server (if available).
;		/CLEAN_DATA	   - Remove data file after process.
;       /DEBUG         - Debug mode.
;       /SILENT        - Quiet mode.
;
; OUTPUTS:
;		None.		
;
; OPTIONAL OUTPUTS:
;		None.
;		
; COMMON BLOCKS:		
;		None.	
;	
; SIDE EFFECTS:
;		None.
;		
; RESTRICTIONS/COMMENTS:
;		The Solar SoftWare (SSW) library as well as
;		rabat3 IDL routines must be loaded.
;			
; CALL:
;		rabat3
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin,	26-JUL-2010.
;
;		20-NOV-2011, X.Bonnin:	Added /WAV_RAD1, /WAV_RAD2, /SWA_HFR, $
;								/SWB_HFR, and /NAN_DAM keywords.			
;               30-JAN-2012, X.Bonnin: Added username and password optional inputs.				
;-

if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'rabat3_launcher,starttime,endtime,$'
	print,'                inputs_file=inputs_file,$'
	print,'                data_dir=data_dir,input_dir=input_dir,$'
	print,'                output_dir=output_dir,write_fits=write_fits,$'
	print,'                username=username,password=password,write_png=write_png,$'
	print,'                /WAV_RAD1,/WAV_RAD2,/SWA_HFR,/SWB_HFR,/NAN_DAM,$'
	print,'                /DOWNLOAD_DATA,/CLEAN_DATA,$'
	print,'                /SILENT,/WRITE_CSV,/NOLOG,/DEBUG'
	return
endif

DOWNLOAD_DATA = keyword_set(DOWNLOAD_DATA)
SILENT = keyword_set(SILENT)
WRITE_CSV = keyword_set(WRITE_CSV)
CLEAN_DATA = keyword_set(CLEAN_DATA)
NOLOG = keyword_set(NOLOG)
DEBUG = keyword_set(DEBUG)
if (DEBUG) then SILENT = 0

WRAD1 = keyword_set(WAV_RAD1)
WRAD2 = keyword_set(WAV_RAD2)
SAHFR  = keyword_set(SWA_HFR) 
SBHFR  = keyword_set(SWB_HFR) 
NDAM = keyword_set(NAN_DAM)
if (WRAD1 + WRAD2 + SAHFR + SBHFR + NDAM ne 1) then begin
	message,/CONT,'You must select (only) one receiver:'
	print,'/WAV_RAD1, /WAV_RAD2, /SWA_HFR, /SWB_HFR, or /NAN_DAM.'
	return
endif

if not (keyword_set(username)) then user = "anonymous" else user = strtrim(username[0],2)
if not (keyword_set(password)) then pass = "" else pass = strtrim(password[0],2)

startt = strjoin(strsplit(strtrim(starttime[0],2),'-',/EXTRACT))
endt = strjoin(strsplit(strtrim(endtime[0],2),'-',/EXTRACT))
date = countday(startt,endt,nday=nday)

case 1 of
	WRAD1:begin
		inst_name = 'Wind/Waves/Rad1' 
		data_file = date+'.R1.Z'
		in_file = 'rabat3_inputs_win_rad1.txt'
	end
	WRAD2:begin
		inst_name = 'Wind/Waves/Rad2' 
		data_file = date+'.R2.Z'
		in_file = 'rabat3_inputs_win_rad2.txt'
	end
	SAHFR:begin
		inst_name = 'STEREO_A/SWaves/HFR' 
		data_file = 'swaves_average_'+date+'_a_hfr.dat'
		in_file = 'rabat3_inputs_sta_hfr.txt'
	end
	SBHFR:begin
		inst_name = 'STEREO_B/SWaves/HFR' 
		data_file = 'swaves_average_'+date+'_b_hfr.dat'
		in_file = 'rabat3_inputs_stb_hfr.txt'
	end
	NDAM:begin
		inst_name = 'Nancay/DAM/ASB' 
		data_file = 'S'+strmid(date,2)+'.RT1'
		in_file = 'rabat3_inputs_nan_dam.txt'
	end
	else:message,'Unknown observatory or receiver!'
endcase

cd,current=curdir
if (~keyword_set(data_dir)) then datdir=curdir else datdir = strtrim(data_dir[0],2)
if (~keyword_set(output_dir)) then outdir=curdir else outdir = strtrim(output_dir[0],2)
if (~keyword_set(inputs_file)) then ifile=in_file else ifile = strtrim(inputs_file[0],2)
if (~keyword_set(input_dir)) then indir = file_dirname(ifile) else indir = strtrim(input_dir[0],2)
if (~keyword_set(script_dir)) then scptdir = curdir else scptdir = strtrim(script_dir[0],2) 

ex_flag = 0
ex_file = outdir + path_sep() + 'rabat3_' + $
			 strjoin(strsplit(anytim(!stime, /ccsds),':.T-',/EXTRACT)) + '.log'
openw,lun_ex,ex_file, $
			 /GET_LUN

for i=0L,nday-1L do begin
	yyyy = strmid(date[i],0,4)
	mm = strmid(date[i],4,2)
	dd = strmid(date[i],6,2)
	date_obs_i = yyyy+'-'+mm+'-'+dd

	print,strtrim(nday-i,2)+': Processing '+inst_name+' data for the date '+date_obs_i

	if (DOWNLOAD_DATA) then begin
		if (~file_test(datdir + path_sep() + data_file[i])) then begin
            Popt = " -P "+datdir
			case 1 of
				WRAD1:spawn,'wget stereowaves.gsfc.nasa.gov:/wind_rad1/rad1a/'+data_file[i]+Popt
				WRAD2:spawn,'wget stereowaves.gsfc.nasa.gov:/wind_rad2/rad2a/'+data_file[i]+Popt
				SAHFR:spawn,'wget stereowaves.gsfc.nasa.gov:/swaves_data/'+$
									  yyyy+'/'+data_file[i]+Popt
				SBHFR:spawn,'wget stereowaves.gsfc.nasa.gov:/swaves_data/'+$
									  yyyy+'/'+data_file[i]+Popt
				NDAM:spawn,'wget --user='+user+' --password='+pass+' mesolr.obspm.fr:../decam/data/decam/'+$
                            strmid(yyyy,2)+mm+'/'+data_file[i]+Popt
			endcase
		endif
	endif
	
	if (~file_test(datdir + path_sep() + data_file[i])) then continue

	rabat3,date_obs_i,ifile,$
		   input_dir=indir,$
		   data_dir=datdir,$
		   output_dir=outdir,$
		   exceptions=exceptions,$
		   write_fits=write_fits,$
		   write_png=write_png,$
		   WRITE_CSV=WRITE_CSV,$
		   SILENT=SILENT,NOLOG=NOLOG, $
           DEBUG=DEBUG

	if (exceptions[0] ne '') then begin
		ex_flag = 1
		printf,lun_ex,exceptions
	endif 
			   

	if (CLEAN_DATA) then spawn,'rm -f '+datdir+path_sep()+data_file[i]
endfor

close,lun_ex
free_lun,lun_ex
if (ex_flag eq 0) then spawn,'rm -f ' + ex_file  

END
