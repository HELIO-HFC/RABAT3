PRO rabat3_processing,data_file, config_file, results, $
                      output_dir=output_dir, $
                      nburst=nburst, $
                      frc_info=frc_info, $
                      data=data, $
                      QUIET=QUIET, $
                      DEBUG=DEBUG, $
                      PREP=PREP, $
                      GET_FRC_INFO=GET_FRC_INFO


;+
; NAME:
;       rabat3_processing
;
; PURPOSE:
;       The RAdio Burst Automated Tracking 3 software (RABAT3) is dedicated
;       to the type III solar radio burst detection on a dynamical
;       spectrum.
;
;       Datasets that can be processed using this program are:
;           Wind/Waves (Rad1,Rad2)
;           STEREO/Waves (HFR)
;           Nancay Decametric Array
;
;        Two methods are implemented:
;           - LIG (Local Intensity Gradient)
;           - SHT (Sweeping Hough Transform ; Lobzin et al., 2009, 2014)
;
; CATEGORY:
;       Feature recognition
;
; GROUP:
;       RABAT3
;
; CALLING SEQUENCE:
;       IDL>rabat3_processing, data_file, config_file, results
;
; INPUTS:
;       data_file   - Scalar of string type specifying the
;                     pathname of the data file to process for a
;                     given day.
;
;       config_file - Scalar of string type specifying the
;                     pathname of the configuration file.
;                     The configuration file provides the
;                     input parameters to use for the
;                     current recognition process.
;
;
; OPTIONAL INPUTS:
;       output_dir - If set, produce output files in the output_dir directory.
;                            No file is saved if this input is not provided.
;
; KEYWORD PARAMETERS:
;       /PREP                        - Run prep-processings
;       /GET_FRC_INFO     - Returns information about the code.
;       /DEBUG                     - Debug mode.
;       /QUIET                       - Quiet mode.
;
; OUTPUTS:
;       results - Structure array providing results
;                 of the detections.
;
; OPTIONAL OUTPUTS:
;       frc_info - Structure containing information about the code.
;       data      - Structure containing input radio data.
;       nburst   - Integer providing the number of bursts detected.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS/COMMENTS:
;       None.
;
; CALL:
;       rabat3_parseconfig
;       rabat3_getdata
;       rabat3_detect_lig
;       rabat3_detect_sht
;       rabat3_merge
;       display2d
;       mpfitfun
;       logging
;
; EXAMPLE:
;       None.
;
; MODIFICATION HISTORY:
;       Written by X.Bonnin,  26-JUL-2010.
;
; Version 1.0.0
;       26-JUL-2010, X.Bonnin:  First release.
;
; Version 1.1.0
;       05-MAY-2011, X.Bonnin:  Added chain code encoding method.
;
; Version 1.2.0
;       28-JUL-2011, X.Bonnin:  Added data_file as an input argument
;                               instead of date and instrum.
;
; Version 2.0.0
;       02-AUG-2011, X.Bonnin:  Major modifications in the code.
;                               Added STEREO/Waves/HFR data set.
;
; Version 2.0.1
;       18-DEC-2011, X.Bonnin:  Added Nancay/Decametric Array data set.
;
; Version 2.0.2
;       19-DEC-2011, X.Bonnin:  Added /DEBUG and /QUIET keywords.
;
; version='2.0.3'
;       10-JAN-2012, X.Bonnin:  Added the output parameter results.
;                               Added /GET_FRC_INFO and frc_info parameters.
;
version='2.0.4'
;       19-NOV-2014, X.Bonnin:  Both methods LIG and SHT can be applied.
;                                                     Remove /DISPLAY keyword.
;                                                     Remove output_file optional input.
;                                                     Add output_dir optional input.
;                                                     Add logging management.
;-

; CONSTANT PARAMETERS
code = 'RABAT3'
description='IDL software dedicated to Type 3 Solar Radio Burst Detection.'

; Current date
spawn,'date +%Y-%m-%dT%H:%M:%S',run_date

if (keyword_set(output_dir)) then begin
    output_rootname = 'rabat3_' + strjoin(strsplit(run_date,'-T:',/EXTRACT))
    log_file = output_rootname + '.log'
    NO_OUTPUT=0b
endif else begin
    NO_OUTPUT=1b
endelse

frc_info={code:code,version:version,description:description}
results=frc_info
if (keyword_set(GET_FRC_INFO)) then return
results=0b & nburst=0

!QUIET = 1
starting_syst = systime(/SEC)
quote = string(39b)

;[1]:Initialization of the program
;[1]:=============================
;On_error,2

;Check the number of input parameters
if not (keyword_set(data_file)) and not (keyword_set(config_file)) then begin
   message,/INFO,'Call is:'
   print,'IDL>rabat3_processing,data_file, config_file, results, $'
   print,'                      output_dir=output_dir, $'
   print,'                      nburst=nburst, $'
   print,'                      /QUIET, /DEBUG, $'
   print,'                      /PREP'
   return
endif
PREP=keyword_set(PREP)
DEBUG = keyword_set(DEBUG)
QUIET = keyword_set(QUIET) xor DEBUG
VERBOSE = 1 - QUIET

; Initializing logging
log = OBJ_NEW('logging')
log->setup,info='INFO - %Y-%m-%D %H:%M:%S - ', $
           warning='WARNING - %Y-%m-%D %H:%M:%S - ', $
           error='ERROR - %Y-%m-%D %H:%M:%S - ', $
           VERBOSE=VERBOSE
if not (NO_OUTPUT) then begin
  log->info, 'Opening log file ' +  log_file + ' ...'
  log->open,filename=log_file
endif

; Parsing configuration file
syst0=systime(/SEC)
log->info,'Parsing '+config_file+'...'
args = rabat3_parseconfig(config_file,VERBOSE=VERBOSE)
if (size(args,/TNAME) ne 'STRUCT') then $
    log->error, 'Can not read '+config_file+'!', /FORCE

elapsed = strtrim(long(systime(/SEC) - syst0),2)
log->info,'Parsing '+config_file+'...done ('+elapsed+' sec.)'
method = strupcase(strtrim(args.method,2))

; Read data file(s)
syst0=systime(/SEC)
log->info,'Reading and pre-processing ('+strjoin(data_file,',')+')...'
data = rabat3_getdata(args,data_file, $
                         VERBOSE=VERBOSE,PREP=PREP)
if (size(data,/TNAME) ne 'STRUCT') then $
  log->error,'Can not read ('+strjoin(data_file,',')+')!', /FORCE

nt=n_elements(data.time) & dt=abs(median(deriv(data.time)))
nf=n_elements(data.freq)
elapsed = strtrim(long(systime(/SEC) - syst0),2)
log->info,'Reading and prep-processing ('+strjoin(data_file,',')+')...done ('+elapsed+' sec.)'

NO_DRIFT = (args.drift_param[0] eq 0.0) and (args.drift_param[1] eq 0.0)
if not (NO_DRIFT) then begin
    array=fltarr(nt,nf)
    if (VERBOSE) then print,'Shifting time axis...'
    tdrift = type3_driftrate_func(data.freq,$
                                  [args.drift_param,0])
    idrift = tdrift/dt
    for j=0L,nf-1L do $
        array[*,j] = shift(data.spectra[*,j],-idrift[j])
    if (VERBOSE) then print,'Shifting time axis...done'
endif else array = data.spectra

if (VERBOSE) then print,'Performing detection...'
syst0 = systime(/SEC)

nf_band=args.nf_band
df_band=nf_band/2
n_band=(nf/df_band)-1
burst_indices=-1 & nburst=0l & lvl_trust=-1.0
burst_delay=-1.0
for j=0,n_band-1 do begin

   array_j=array[*,j*df_band:j*df_band+nf_band-1l]
   freq_j=data.freq[j*df_band:j*df_band+nf_band-1l]

   case method of
    'LIG':begin
        it_j = rabat3_detect_lig(array_j, data.time, freq_j, args.threshold, $
                            model_param=args.model_param, $
                            xgrad=xgrad,ygrad=ygrad,$
                            ymodel=ymodel, $
                            lvl_trust=lvl_j, $
                            scale=data.scale, max_val=data.max_val, $
                            VERBOSE=VERBOSE, $
                            DEBUG=DEBUG)
        burst_delay = [burst_delay,0.0]
    end
    'SHT':begin
         it_j = rabat3_detect_sht(array_j, data.time, freq_j, args.threshold, $
                            sweep_step=args.sweep_step, $
                            sht=sht,  delay_at_max=delay_at_max, $
                            lvl_trust=lvl_j, missing_pix=data.missing_pix, $
                            scale=data.scale, max_val=data.max_val, $
                            VERBOSE=VERBOSE, $
                            DEBUG=DEBUG)
         burst_delay = [burst_delay,delay_at_max[it_j]]
    end
    else:message,'Unknow detection method, available methods are: \n' + $
                              ' - LIG (Local Intensity Gradient) \n '+ $
                              ' - SHT (Sweeping Hough Transform)'
    endcase

   burst_indices=[burst_indices,it_j]
   lvl_trust=[lvl_trust,lvl_j]
   nburst=nburst+n_elements(it_j)
endfor
if (nburst eq 0) then begin
   print,'No burst detected!'
   return
endif
burst_indices=burst_indices[1:*]
lvl_trust=lvl_trust[1:*]
isort=uniq(burst_indices,sort(burst_indices))
burst_indices=burst_indices[isort]
lvl_trust=lvl_trust[isort]
nburst=n_elements(burst_indices)

if (method eq 'SHT') then burst_delay = ((burst_delay[1:*])[isort])

burst_times=data.time[burst_indices]
if (DEBUG) then begin
   if (data.scale eq 'linear') then dB=10.0*alog10(data.spectra>0.1) $
    else dB = data.spectra
   display2d,dB,Xin=data.time/3600.0,Yin=data.freq, $
             xtitle='UT (hours)',ytitle='Freq. (kHz)', $
             title=args.observatory+'/'+args.instrument+'/'+args.receiver+' - '+data.date_obs, $
             /REV,min_val=0,max_val=data.max_val,col=0
   loadct,39,/SILENT
   for j=0,nburst-1 do oplot,burst_times[j]/3600.0+fltarr(2),minmax(data.freq),color=254,line=2,thick=0.1
   stop
   ;wdelete,!D.WINDOW
endif
elapsed = strtrim(long(systime(/SEC) - syst0),2)
if (VERBOSE) then begin
   print, strtrim(nburst,2)+' possible burst(s) found.'
   print,'Performing detection...done ('+elapsed+' sec.)'
endif

; Get bursts parameters
if (VERBOSE) then print,'Extracting bursts parameters...'
syst0 = systime(/SEC)

nf=n_elements(data.freq) & nt=n_elements(data.time)

dw = dt*5
results={data_file:data_file, $
         config_file:config_file, $
         config_args:args, $
         date_obs:data.date_obs, $
         burst_time:fltarr(nf), $
         burst_freq:fltarr(nf), $
         lvl_trust:0.0, $
         fitting:fltarr(3), $
         run_date:run_date}
results=replicate(results,nburst)
for i=0,nburst-1 do begin

    if (VERBOSE) then print,"Extracting burst #" + strtrim(i+1,2)
    if (NO_DRIFT) then $
        t_i = burst_times[i] + fltarr(nf) $
    else t_i=burst_times[i]+tdrift

    if (method eq 'SHT') then t_i = t_i + burst_delay[i]*(1 - (findgen(nf)/float(nf-1)))

   tmax=fltarr(nf) + !values.f_nan
   smax=fltarr(nf) + !values.f_nan
   for j=0,nf-1 do begin
      s_j = data.spectra[*,j]
      where_in=where(data.time ge t_i[j]-0.5*dw and $
                     data.time le t_i[j]+0.5*dw,n_in)
      if (where_in[0] eq -1) then continue
      smax_j = max(s_j[where_in],jmax)
      tmax[j]=data.time[where_in[jmax]]
      smax[j]=smax_j
   endfor

   A0=[args.drift_param,burst_times[i]] & terr=fltarr(nf)+1.0 & weights=smax/max(smax,/NAN)
   Ai = mpfitfun('type3_driftrate_func',data.freq,tmax,terr,A0,yfit=tfit,weights=weights,/QUIET)

   if (DEBUG) then begin
      xr=burst_times[i]+[-1800,1800]
      display2d,dB,Xin=data.time,Yin=data.freq, $
                /REV,col=0,xr=xr,$
                max_val=data.max_val, $
                min_val=0
      loadct,39,/SILENT
      oplot,t_i,data.freq,line=2,color=200,thick=0.1
      oplot,burst_times[i]-dw+fltarr(2),minmax(data.freq,/NAN),line=3,color=50,thick=0.1
      oplot,burst_times[i]+dw+fltarr(2),minmax(data.freq,/NAN),line=3,color=50,thick=0.1
      oplot,tmax,data.freq,color=254,/PSYM,symsize=0.1
      oplot,tfit,data.freq,color=150,thick=0.1

      stop,'Enter .c to continue'
   endif

   results[i].burst_freq=data.freq
   results[i].lvl_trust=lvl_trust[i]
   results[i].burst_time=t_i
   results[i].fitting=Ai
endfor
elapsed = strtrim(long(systime(/SEC) - syst0),2)
if (VERBOSE) then print,'Extracting bursts parameters...done ('+elapsed+' sec.)'

if keyword_set(output_file) then begin
  save,results,description='Results of RABAT3 detections', $
       filename=output_file,/COMPRESS
  if (VERBOSE) then print,output_file+" saved."
endif

log->info,'Exiting program...'
log->close
OBJ_DESTROY, log
if (DEBUG) then stop

END