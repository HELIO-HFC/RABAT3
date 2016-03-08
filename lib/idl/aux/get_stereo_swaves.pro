;+
; NAME:
;		read_gsfc_shfr
;
; PURPOSE:
; 		Read STEREO/Waves hfr ascii data file swaves_average_yyyymmdd_(a/b)_hfr.dat
;		produced by the GSFC (NASA).
;		(see http://stereo-ssc.nascom.nasa.gov/data/ins_data/swaves/)
;
; CATEGORY:
;		I/O
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL> Data = read_gsfc_shfr(filename)
;
; INPUTS:
;		filename - Scalar of string type containing the name of the hfr data file.
;	
; OPTIONAL INPUTS:
;		input_dir - Specify the directory path of the input data file.
;
; KEYWORD PARAMETERS:
;		/SILENT	      - Quiet mode.
;					    Hence decompress input file (using gzip) before read it.
;
; OUTPUTS:
;		data - Structure containing radio data:
;					.time (UTC in seconds)
;					.frequency (in kHz)
;					.flux (in intensity on receiver background ratio)
;					.receiver background (in microVolts per root square Hz)
;
; OPTIONAL OUTPUTS:
;		header - Structure containing information about radio data:
;					.OBSERVATORY (STEREO)
;					.INSTRUMENT  (Swaves)
;					.RECEIVER    (HFR)
;					.TIME_UNITS  (Seconds)
;					.FREQ_UNITS  (kHz)
;					.FLUX_UNITS  (Int on Back ratio (db))
;					.DATE_OBS    
;					.DATE_END
;					.FILENAME
;					.URL
;					.COMMENT
;
;		error - Returns 1 if an error occurs during reading, 0 else.
;				
;
; COMMON BLOCKS:
;		None.
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS/COMMENTS:
;		None.
;	
; CALL:
;		None.		
;
; EXAMPLE:
;		None.
;
; MODIFICATION HISTORY:
;		Written by:		X.Bonnin, 26-JUL-2011.
;
;-

FUNCTION read_gsfc_shfr,filename,$
						input_dir=input_dir,$
						header=header,$
						error=error,$
						SILENT=SILENT

error = 1
if (~keyword_set(filename)) then begin
	message,/INFO,'Call is:'
	print,'data = read_gsfc_shfr(filename,input_dir=input_dir,$'
	print,'                      header=header,error=error,$'
	print,'                      /SILENT)'
	return,0
endif

SILENT = keyword_set(SILENT)

file = strtrim(filename[0],2)
if (keyword_set(input_dir)) then file = strtrim(input_dir[0],2) + path_sep() + file_basename(file)
if (~file_test(file)) then begin
	message,/INFO,'No input data file found!'
	return,0
endif

nf = 319
nt = 1440
frequency = fltarr(nf)
background = fltarr(nf)
flux = fltarr(nt,nf)
time = intarr(nt)

ON_IOERROR, bad_num

input_file = file
openr,lun,input_file,/GET_LUN
readf,lun,frequency,format='(319f9.1)'
readf,lun,background,format='(319f8.3)'
i = 0l
while not (eof(lun)) do begin
	a = '' & time_i = 0 & flux_i = fltarr(nf)
	readf,lun,a
	reads,a,time_i,flux_i,format='(i4,319f8.3)'
	time[i] = time_i
	flux[i,*] = flux_i
    i++
endwhile
close,lun
free_lun,lun

time = time*60. ;min to sec

basename = file_basename(file)

mission = 'Stereo_'+(strsplit(basename,'_',/EXTRACT))[3]
yyyymmdd = (strsplit(basename,'_',/EXTRACT))[2]
yyyy = strmid(yyyymmdd,0,4) & mm = strmid(yyyymmdd,4,2)
dd = strmid(yyyymmdd,6,2)
date = yyyy+'-'+mm+'-'+dd
date_obs = date+'T00:00:00.000'
date_end = date+'T23:59:59.999'

freq_min = min(frequency,max=freq_max,/NAN)
df = median(deriv(frequency))
dt = median(deriv(time))


;Integration time
tau = fltarr(nf)
tau[0:37] = 0.0200 ;sec
tau[38:*] = 0.0025 ;sec

;Bandwidth 
bandwidth = fltarr(nf) + 12.5 ;kHz

comment = '60 sec. average data produced by GSFC (NASA).'
url = 'ftp://stereowaves.gsfc.nasa.gov/swaves_data/'+yyyy+'/'+basename
header = {observatory:mission,instrument:'Swaves',receiver:'hfr',time_units:'seconds',freq_units:'kHz',$
		  flux_units:'Intensity above background (dB)',$
		  date_obs:date_obs,date_end:date_end,$
		  dt:dt,df:df,nt:nt,nf:nf,freq_min:freq_min,freq_max:freq_max,$
		  filename:file_basename(input_file),url:url,comment:comment}

data = {time:time,frequency:frequency,flux:flux,background:background,$
		tau:tau,bandwidth:bandwidth}

error = 0
return,data

bad_num:
message,/CONT,'Error reading input data file!'
return,0

END