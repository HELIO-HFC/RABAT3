FUNCTION rabat3_detect_sht,intensity,time,freq,threshold, $
                            sweep_step=sweep_step, $
                            missing_pix=missing_pix, $
                            k=k, scale=scale, $
                            max_val=max_val, $
                            sht=sht, s=s, delay=delay, $
                            delay_at_max=delay_at_max, $
                            lbg=lbg, mask=mask, $
                            tburst=tburst,lvl_trust=lvl_trust,  $
                            YLOG=YLOG, $
                            VERBOSE=VERBOSE, $
                            DEBUG=DEBUG

;+
; NAME:
; rabat3_detect_sht
;
; PURPOSE:
;   This function performs  type III solar radio burst
;       detections using a sweeping Hough transform method.
;
; CATEGORY:
; Image processing
;
; GROUP:
; RABAT3
;
; CALLING SEQUENCE:
; IDL>iburst = rabat3_detect_sht(intensity,time,freq,threshold)
;
; INPUTS:
;       intensity - 2d array containing the radio intensity values
;                   as a function of the time and frequency
;                   (i.e., dynamical spectrum).
;       time      - Vector containing the first dimension variable
;                   of the 2d array (i.e., time in seconds of the day,
;                   UTC).
;       freq      - Vector containing the second dimension variable
;                   of the 2d array (i.e., frequency in MHz).
;       threshold - Scalar of float type providing the threshold value
;                   to use for the thresholding process.
;       k           - Local background lbg at time t_i is computed over
;                       [i-k,i+k] range.
;
; OPTIONAL INPUTS:
;       sweep_step  - A scalar given the number of step of the sweeping.
;                                 Default is 0.
;       missing_pix - List of missing pixels.
;                                Detections are not valid for missing pixels.
;       scale - String containing the intensity scale ('db' or 'linear').
;       max_val - Maximal intensity value to display.
;
; KEYWORD PARAMETERS:
;       /VERBOSE - Talkative mode.
;       /DEBUG   - Debug mode.
;
; OUTPUTS:
; iburst   - Vector providing the indices of the type III bursts
;                  along the time axis.
;
;
; OPTIONAL OUTPUTS:
;       sht             - 2D Sweeping Hough transform
;       s                - sht values over time at max(sht)_delay
;       mask        - 2D binary mask
;       delay        - Vector containing the delay time values used
;                           to compute the Hough transform
;                           (i.e., the 2nd dimension of the Hough transform).
;       delay_at_max - Values of the delay at the Hough transform maxima.
;                                    along time axis.
;       tburst        - Vector time[iburst]
;       lvl_trust     - Vector containing the detection level of trust.
;       lbg             - Local background of s.
;
; COMMON BLOCKS:
; None.
;
; SIDE EFFECTS:
; None.
;
; RESTRICTIONS/COMMENTS:
; None.
;
; CALL:
;       compute_sht
;       get_localmax
;       rabat3_thresholding
;
; EXAMPLE:
; None.
;
; MODIFICATION HISTORY:
; Written by X.Bonnin,  26-JUL-2011.
;
;-

burst_indices=-1 & lvl_trust=-1.0
if (n_params() lt 4) then begin
   message,/CONT,'Call is:'
   print,'iburst = rabat3_detect_sht(intensity,time,freq,threshold, $'
   print,'                            sweep_step=sweep_step, $'
   print,'                            missing_pix=missing_pix, $'
   print,'                            sht=sht, scale=scale, max_val=max_val, $
   print,'                            delay=delay, delay_at_max=delay_at_max, $'
   print,'                            tburst=tburst,lvl_trust=lvl_trust, $'
   print,'                            /YLOG,/VERBOSE,/DEBUG)'
   return,-1
endif
YLOG=keyword_set(YLOG)
DEBUG=keyword_set(DEBUG)
VERBOSE = keyword_set(VERBOSE) or DEBUG

if not (keyword_set(missing_pix)) then missing_pix = -1
array = intensity

if not (keyword_set(sweep_step)) then sweep_step=0
sstep = long(sweep_step)

if not (keyword_set(k)) then k=sstep

if not (keyword_set(scale)) then scale='linear'

if (scale eq 'linear') then dB=10.0*alog10(array>1.0) else dB = array

; Compute binary mask
nt = n_elements(time)
nf = n_elements(freq)
mask = fltarr(nt,nf)
imax = get_localmax(array,1)
if (imax[0] eq -1) then begin
  message,/CONT,'No local maxima in the spectra!'
  return,-1
endif
mask[imax] = 1.0

if (sstep eq 0) then begin
  s = total(mask,2)
  delay_at_max = fltarr(nt)
endif else begin
  dt = abs(round(median(deriv(time))))
  delay = dt*findgen(sstep)
  sht = compute_sht(mask, X=time, Y=freq, Z=delay)
  s = max(sht, jmax, dim=2)
  jj = array_indices([nt,sstep], jmax, /DIM)
  delay_at_max = delay[jj[1,*]]
endelse

where_miss = [0,nt-1]
if (missing_pix[0] ne -1) then begin
    Amiss = bytarr(nt,nf) + 1b
    Amiss[missing_pix] = 0b
    where_miss=[where_miss, where(total(Amiss,2) eq 0b)]
endif

; Remove local background from s
s3 = fltarr(nt) & lbg = fltarr(nt)
for i=0l,nt-1l do begin
    i0 = (i - k)>0l & i1 = (i + k)<nt-1l
    miss_inside = (where(where_miss ge i0-5l and where_miss le i1+5l))[0]
    if (miss_inside eq  -1) then begin
        lbg[i] = min(s[i0:i1])
        s3[i] = s[i] - lbg[i]
    endif
endfor

if (DEBUG) then begin
   tmin = min(time, max=tmax,/NAN)
   window,2
   display2d,dB,Xin=time, $
      /REV,/XS,/YS,col=0, $
      max_val=max_val, $
      min_val=0
   window,3
   display2d,mask,Xin=time,$
    /REV,/XS,/YS,col=0, $
    max_val=1
   window,4
  loadct,39,/SILENT
   plot,time,s,/PSYM,/XS,/YS
   oplot,time,s3,col=250
   oplot,[tmin,tmax],[threshold,threshold],line=2,color=200
   oplot,time[where_miss],s3[where_miss],psym=2,color=50,thick=0.25
   stop,'Press .c to continue'
endif

; Keep samples for which
;  s3 is below the threshold
iburst=rabat3_thresholding(s3,threshold, $
                           nburst=nburst,/GET_MAX)
if (iburst[0] eq -1) then return,-1
s3=s3[iburst]
lvl_trust=((-0.5/threshold)*s3 + 1.0)*100.0>0.0
tburst=time[iburst]

return,iburst
END
