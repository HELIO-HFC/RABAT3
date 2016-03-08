FUNCTION read_waves_gsfc_rad2,file,header,$
                              background=background, $
                              time=time,frequency=frequency, $
                              VERBOSE=VERBOSE, ASCII=ASCII, $
                              REMOVE_CAL=REMOVE_CAL

;+
; NAME:
;	read_waves_gsfc_rad2
;
; PURPOSE:
; 	Read Wind/Waves Rad2 data file YYYYMMDD.R2(.Z)
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
;	IDL> intensity = read_waves_gsfc_rad2(file,header)
;
; INPUTS:
;	file - Scalar of string type containing the pathname of the rad2 data file.
;	
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:       
;       /ASCII            - Read input file as an ascii format file.
;	/VERBOSE	  - Verbose mode.	    
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
;                       .DT_MAX = full rad2 time resolution in seconds.
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
;	gzip software must be installed.
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

nf = 256
nt = 1440
dt_min = 16.192 ;sec
dt = 60.
time = dt*findgen(nt)

freq_min = 1075. 
freq_max = 13825.
df = 50.
frequency = df*findgen(nf) + freq_min

bandwidth = 20000. ;Hz
integration_time = 20.0e-3 ; sec

intensity=0b
header=0b
if not (keyword_set(file)) then begin
   message,/INFO,'Call is:'
   print,'intensity = read_waves_gsfc_rad2(file, header, $'
   print,'                           time=time, frequency=frequency, $'
   print,'                           background=background, $'
   print,'                           /ASCII,/VERBOSE, $'
   print,'                           /REMOVE_CAL)'
   return,0b
endif
ASCII=keyword_set(ASCII)
VERBOSE = keyword_set(VERBOSE)
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
   ASCII=1b
endif else if (ASCII) then begin
   nlines = file_lines(input_file)
   content = strarr(nlines)
   openr,lun,input_file,/GET_LUN
   readf,lun,content
   close,lun
   free_lun,lun
   url=file_basename(file)+'.Z'
endif else begin
   restore,input_file
   intensity=arrayb
endelse

if (ASCII) then begin
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
endif
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
