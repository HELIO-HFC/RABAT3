;+
; NAME:
;		read_gsfc_rad1
;
; PURPOSE:
; 		Read Wind/Waves Rad1 ascii data file YYYYMMDD.R1(.Z)
;		produced by the GSFC (NASA).
;		(see http://ssed.gsfc.nasa.gov/waves/data_products.html)
;
; CATEGORY:
;		I/O
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL> Data = read_gsfc_rad1(filename)
;
; INPUTS:
;		filename - Scalar of string type containing the name of the rad 1 data file.
;	
; OPTIONAL INPUTS:
;		input_dir - Specify the directory path of the input data file.
;
; KEYWORD PARAMETERS:
;		/SILENT	      - Quiet mode.
;					    Hence decompress input file (using gzip) before read it.
;		/DECOMPRESS	  - If input file is compressed, decompress it on current 
;						directory using gzip  .
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
;					.OBSERVATORY (Wind)
;					.INSTRUMENT  (Waves)
;					.RECEIVER    (Rad1)
;					.TIME_UNITS  (Seconds)
;					.FREQ_UNITS  (kHz)
;					.FLUX_UNITS  
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
;		gzip software must be installed if input file is compressed. 
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

FUNCTION read_gsfc_rad1,filename,$
						input_dir=input_dir,$
						header=header,$
						error=error,$
						DECOMPRESS=DECOMPRESS,$
						SILENT=SILENT

error = 1
if (~keyword_set(filename)) then begin
	message,/INFO,'Call is:'
	print,'data = read_gsfc_rad1(filename,input_dir=input_dir,$'
	print,'                      header=header,error=error,$'
	print,'                      /DECOMPRESS,/SILENT)'
	return,0
endif

SILENT = keyword_set(SILENT)
DECOMPRESS = keyword_set(DECOMPRESS)

file = strtrim(filename[0],2)
if (keyword_set(input_dir)) then file = strtrim(input_dir[0],2) + path_sep() + file_basename(file)
if (~file_test(file)) then begin
	message,/INFO,'No input data file found!'
	return,0
endif

input_file = file
dotpos = strpos(file,'.',/REVERSE_SEARCH)
ext = strtrim(strmid(file,dotpos),2)
if (ext eq '.Z') then begin
	spawn,'gzip -dc '+input_file,content
	if (DECOMPRESS) then spawn,'gzip -dc '+input_file+' > '+file_basename(file,ext)
endif else begin
	nlines = file_lines(input_file)
	content = strarr(nlines)
	openr,lun,input_file,/GET_LUN
	readf,lun,content
	close,lun
	free_lun,lun
endelse

nf = 256
nt = 1441
flux = fltarr(nt,nf)
for j=0,nf-1 do flux[*,j] = 10.*alog10(float(strsplit(content[j],/EXTRACT)))

background = reform(flux[1440,*])
flux = flux[0:1439,*]
nt = nt - 1
dt = 60.
time = (findgen(nt) + 0.5)*dt 

basename = file_basename(file)
date = strmid(basename,0,4)+'-'+strmid(basename,4,2)+'-'+strmid(basename,6,2)
date_obs = date+'T00:00:00.000'
date_end = date+'T23:59:59.999'

freq_min = 20. 
freq_max = 1040.
df = 4.
frequency = df*findgen(nf) + freq_min

;Integration time for dipole S
tau = fltarr(nf) + 0.154 ;sec

;Bandwidth for dipole S
bandwidth = fltarr(nf) + 3. ;kHz 

comment = '60 sec. average data produced by GSFC (NASA).'
url = 'ftp://stereowaves.gsfc.nasa.gov/wind_rad1/rad1a/'
header = {observatory:'Wind',instrument:'Waves',receiver:'Rad1',time_units:'seconds',freq_units:'kHz',$
		  flux_units:'Intensity above background (dB)',$
		  date_obs:date_obs,date_end:date_end,$
		  dt:dt,df:df,nt:nt,nf:nf,freq_min:freq_min,freq_max:freq_max,$
		  filename:file_basename(input_file),url:url,comment:comment}

data = {time:time,frequency:frequency,flux:flux,background:background,$
		tau:tau,bandwidth:bandwidth}

error = 0
return,data
END