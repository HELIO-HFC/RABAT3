FUNCTION rabat3_detect_lig,intensity,time,freq,threshold, $
                            model_param=model_param, $
                            ymodel=ymodel, $
                            lsr=lsr, scale=scale, $
                            max_val=max_val, $
                            tburst=tburst,lvl_trust=lvl_trust,  $
                            xgrad=xgrad,ygrad=ygrad, $
                            YLOG=YLOG, $
                            VERBOSE=VERBOSE,$
                            DEBUG=DEBUG

;+
; NAME:
;	rabat3_detect_lig
;
; PURPOSE:
; 	This function performs type III solar radio burst
;       detections using a local intensity gradient method.
;
; CATEGORY:
;	Image processing
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>iburst = rabat3_detect_lig(intensity,time,freq,threshold)
;
; INPUTS:
;	intensity - 2d array containing the radio intensity values
;                   as a function of the time and frequency
;                   (i.e., dynamical spectrum).
;       time      - Vector containing the first dimension variable
;                   of the 2d array (i.e., time in seconds of the day,
;                   UTC).
;       freq      - Vector containing the second dimension variable
;                   of the 2d array (i.e., frequency in MHz).
;       threshold - Scalar of float type providing the threshold value
;                   to use for the thresholding process.
;
; OPTIONAL INPUTS:
;       model_param  - 3-elements vector containing the parameters
;                      required to compute the sinusoidal model.
;                      Order is [time_resolution,time_window,amplitude].
;       scale - String containing the intensity scale ('db' or 'linear')
;       max_val - Maximal intensity value to display.
;
; KEYWORD PARAMETERS:
;       /VERBOSE - Talkative mode.
;       /DEBUG   - Debug mode.
;
; OUTPUTS:
;	iburst   - Vector providing the indices of the type III bursts
;                  along the time axis.
;
;
; OPTIONAL OUTPUTS:
;       ymodel        - Provides the sinusoidal model values
;                       used to find events.
;       lsr           - Provides the results of the least squares root
;                       method applied using the sin. model over
;                       xmodel axis.
;       tburst        - Vector time[iburst]
;       lvl_trust     - Vector containing the detection level of trust.
;       xgrad         - X components of the array gradient.
;       ygrad         - Y components of the array gradient.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS/COMMENTS:
;	None.
;
; CALL:
;       pixel_gradient
;       rabat3_thresholding
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2011.
;
;-

burst_indices=-1 & lvl_trust=-1.0
if (n_params() lt 4) then begin
   message,/CONT,'Call is:'
   print,'iburst = rabat3_detect_lig(intensity,time,freq,threshold, $'
   print,'                            model_param=model_param, $'
   print,'                            scale=scale, max_val=max_val, $'
   print,'                            ymodel=ymodel,lsr=lrs, $'
   print,'                            xgrad=xgrad,ygrad=ygrad, $'
   print,'                            tburst=tburst,lvl_trust=lvl_trust, $'
   print,'                            /YLOG,/VERBOSE,/DEBUG)'
   return,-1
endif
YLOG=keyword_set(YLOG)
DEBUG=keyword_set(DEBUG)
VERBOSE = keyword_set(VERBOSE) or DEBUG

if not (keyword_set(model_param)) then mparam=[1.0,180.0,90.0] $
else mparam=float(model_param[0:2])

array=intensity
nf = n_elements(freq)
nt = n_elements(time)
n = nt*nf
dt = float(median(deriv(time)))
dx = float(mparam[0])

if not (keyword_set(scale)) then scale='linear'

if (scale eq 'linear') then dB=10.0*alog10(array>1.0) else dB = array

; Compute image gradient
pixel_gradient,array,xgrad,ygrad
; Gradient direction angle in degrees
theta = atan(ygrad,xgrad)*!radeg

stop
; Compute average theta over the frequency band
mth=total(theta,2)/float(nf)

if (dx ne dt) then begin
   nx=long((max(time)-min(time))/dx) + 1l
   x=dx*findgen(nx) + min(time)
   mth=interpol(mth,time,x)
endif else begin
   nx=nt
   x=time
endelse

; Compute model
xmin_mod=0.0
xmax_mod=mparam[1]
nx_mod=long((xmax_mod-xmin_mod)/dx)
xmodel=dx*findgen(nx_mod)
ymodel=90.0*cos(!pi*indgen(nx_mod)/float(nx_mod-1l))
ix2=long(nx_mod/2)

;weights=abs(ymodel)
weights=1.0
;Nw=total(1./(weights^2))
Nw=1.0

nxm=nx-nx_mod
lsr=fltarr(nxm)
for i=0l,nxm-1l do begin
   mth_i=mth[i:i+nx_mod-1l]
   lsr[i] = sqrt(Nw*total(weights*(mth_i-ymodel)^2,/NAN))
   ;lsr[j,i] = sqrt(total((mth_interp_i-ymodel)^2,/NAN))
endfor

if (DEBUG) then begin
   xr=[0.0,8.64]*1.e4
   ;xr=[6.0,7.0]*1e4
   window,2
   display2d,dB,Xin=time,/REV, $
      col=0,xr=xr,max_val=max_val
   loadct,39,/SILENT
   window,3
   plot,x,mth,/XS,xr=xr
   oplot,minmax(x),[90.0,90.0],line=3
   oplot,minmax(x),[-90.0,-90.0],line=3
   window,4
   plot,x,lsr,/XS,xr=xr
   oplot,minmax(x),[threshold,threshold],col=50,line=3
   stop
endif
lsr=interpol(lsr,lindgen(nxm),indgen(nt))

; Keep samples for which
; the lsr are below the threshold
iburst=rabat3_thresholding(lsr,threshold, $
                           nburst=nburst,/GET_MAX)
if (iburst[0] eq -1) then return,-1
lsr=lsr[iburst]
lvl_trust=((-0.5/threshold)*lsr + 1.0)*100.0>0.0
iburst=iburst + ix2
tburst=time[iburst]

return,iburst
END
