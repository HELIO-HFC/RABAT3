FUNCTION read_waves_gsfc_tnr,file,header,$
                             background=background, $
                             time=time,frequency=frequency, $
                             DECOMPRESS=DECOMPRESS,$
                             VERBOSE=VERBOSE, $
                             REMOVE_CAL=REMOVE_CAL

;+
; NAME:
;	read_waves_gsfc_tnr
;
; PURPOSE:
; 	Read Wind/Waves TNR ascii data file YYYYMMDD.tnr(.Z)
;	produced by the GSFC (NASA).
;	(see http://ssed.gsfc.nasa.gov/waves/data_products.html)
;
; CATEGORY:
;	I/O
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL> intensity = read_waves_gsfc_tnr(file,header)
;
; INPUTS:
;	file - Scalar of string type containing the pathname of the TNR data file.
;	
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:       
;	/VERBOSE	  - Verbose mode.	    
;	/DECOMPRESS	  - If input file is compressed, decompress it on current 
;			    directory using gzip  .
;       /REMOVE_CAL       - Remove calibration spectra.
;
; OUTPUTS:
;	intensity - Returns an array containing the intensity
;                   above background level
;                   as a function of time and frequency.
;
; OPTIONAL OUTPUTS:
;       time       - Returns a vector containing the UT values in seconds.
;       frequency  - Returns a vector containing the frequencies in kHz. 
;	background - Returns a vector containing the receiver background
;                    values (in microVolts.Hz^(-1/2)). 
;	header     - Structure containing information about radio data:
;              		.NT     = Number of spectra along the time axis.
;                       .NF     = Number of frequency channels.
;                       .DT     = Current time resolution (in seconds).
;                       .DT_MAX = full rad1 time resolution in seconds.
;                       .DF     = Frequency step (in kHz).
;                       .FMIN   = frequency minimum (in kHz).
;                       .FMAX   = frequency maximum (in kHz).
;                       .TMIN   = beginning time (in seconds).
;                       .TMAX   = ending time (in seconds).
;                       .B      = bandwidth (in kHz).
;                       .TAU    = integration time (in seconds).
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS/COMMENTS:
;	gzip software must be installed 
;	if /DECOMPRESS is set. 
;	
; CALL:
;	None.
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin (LESIA), 26-JUL-2011.
;
;-

nf = 96
nt = 1440
dt_min = 1.472 ;sec
dt = 60.
time = dt*findgen(nt)

freq_min = 4. 
freq_max = 245.148
df = 0.0188144
frequency=10.^(findgen(nf)*df+alog10(freq_min))

bandwidth = 11.264 ;Hz
integration_time = 0.736 ; sec

intensity=0b
header=0b
if not (keyword_set(file)) then begin
   message,/INFO,'Call is:'
   print,'intensity = read_waves_gsfc_tnr(file, header, $'
   print,'                                time=time, frequency=frequency, $'
   print,'                                background=background, $'
   print,'                                /DECOMPRESS,/VERBOSE, $'
   print,'                                /REMOVE_CAL)'
   return,0b
endif
VERBOSE = keyword_set(VERBOSE)
DECOMPRESS = keyword_set(DECOMPRESS)
REMOVE_CAL=keyword_set(REMOVE_CAL)

if (~file_test(file)) then begin
   message,/INFO,file+' not found!'
   return,0b
endif

input_file = file
dotpos = strpos(file,'.',/REVERSE_SEARCH)
ext = strtrim(strmid(file,dotpos),2)
if (ext eq '.Z') then begin
   spawn,'gzip -dc '+input_file,content
   if (DECOMPRESS) then spawn,'gzip -dc '+input_file+' > '+file_basename(file,ext)
   url=file_basename(file)
endif else begin
   nlines = file_lines(input_file)
   content = strarr(nlines)
   openr,lun,input_file,/GET_LUN
   readf,lun,content
   close,lun
   free_lun,lun
   url=file_basename(file)+'.Z'
endelse

intensity = fltarr(nt+1,nf)
if (n_elements(content) ne nf) then begin
   message,/CONT,'Something goes wrong in the input file!'
   return,0b
endif

for j=0,nf-1 do begin
   content_i = float(strsplit(content[j],/EXTRACT))
   if (n_elements(content_i) ne nt+1) then continue
   intensity[*,j] = content_i
endfor
background = reform(intensity[1440,*])
intensity = intensity[0:1439,*]

; Remove calibration spectra
if (REMOVE_CAL) then begin
   wind = fltarr(nt)
   where_tcal = where(time ge 3420.0 and time le 4680.0)
   wind[where_tcal] = 1.0
   tot_int=total(intensity,2)*wind
   where_cal = where(tot_int gt 1000.)
   if (where_cal[0] ne -1) then intensity[where_tcal,*] = 0.0
endif

date_obs = strmid(file_basename(strtrim(input_file,2)),0,8)
date_obs = strmid(date_obs,0,4)+'-'+$
           strmid(date_obs,4,2)+'-'+$
           strmid(date_obs,6,2)
header = {date_obs:date_obs, $
          tmin:min(time),tmax:max(time), $
          fmin:freq_min,fmax:freq_max, $
          nt:nt,nf:nf,dt:dt,df:df, $
          b:bandwidth, $
          tau:integration_time, $
          dt_min:dt_min}

return,intensity
END
