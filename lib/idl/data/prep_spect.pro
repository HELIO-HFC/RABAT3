PRO prep_spect,intensity, snr, background, sigma, $
               filter_width=filter_width, $
               N_sigma=N_sigma, threshold=threshold, $
               q=q, nbins=nbins, gauss_noise=gauss_noise, $
               ichannels=ichannels, pp_intensity=pp_intensity, $
               pp_background=pp_background, pp_snr=pp_snr, $
               INTERPOL=INTERPOL, FILL=FILL

;+
; NAME:
;	prep_spect
;
; PURPOSE:
;	Pre-processes a dynamical spectrum by removing
;       bad/noisy frequency channels. 	  	
;
; CATEGORY:
;	Radio processing
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL>prep_spect,intensity,snr,background, sigma, pp_intensity=pp_intensity
;
; INPUTS:
;	intensity    - 2d array containing the intensity values 
;                      as a function of time and frequency.
;       snr          - 2d array containing the signal on noise ratio
;                      to prep.
;       background   - vector containing the background spectrum to
;                      prep.
;       sigma        - vector containing the average signal fluctuation values.
;	
; OPTIONAL INPUTS:
;       filter_width - Width of the filter window to
;                      use to remove bad frequencies on
;                      the background spectrum.
;       threshold    - Threshold to apply on snr to remove parasited
;                      channels.
;       q            - Value of the quantile to use to compute
;                      snr histograms. Default is 0.1.
;       nbins        - Number of bins to use to compute snr
;                      histograms. Default is 10000.
;
; KEYWORD PARAMETERS:
;	/INTERPOL - Interpol bad/missing pixels
;       /FILL     - Fill bad/missing pixels with a gaussian noise.
;
; OUTPUTS:
;       None.
;
; OPTIONAL OUTPUTS:
;	ichannels    - Vector containing the subscripts of the 
;                      bad/noisy frequency channels.
;       gauss_noise  - 2d array containing a gaussian noise
;                      computed using 
;                      the pp_background and pp_sigma new parameters.
;                   
;
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
;       stddev_filter
;       get_quantile
;
; EXAMPLE:
;	None.	
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2011.
;											
;-

;[1]:Initialization of the program
;[1]:=============================
;On_error,2

;Check the input arguments
if (n_params() lt 4) then begin
   message,/INFO,'Call is:'
   print,'prep_spect,intensity,snr,background, sigma, $'
   print,'           filter_width=filter_width, N_sigma=N_sigma, $'
   print,'           threshold=threshold,q=q,nbins=nbins, $'
   print,'           ichannels=ichannels,gauss_noise=gauss_noise, $'
   print,'           pp_background=pp_background,pp_snr=pp_snr, $'
   print,'           pp_intensity=pp_intensity, /FILL,/INTERPOL'
   return
endif
FILL=keyword_set(FILL)
INTERPOL=keyword_set(INTERPOL)
if (FILL) and (INTERPOL) then FILL=0b

if not (keyword_set(q)) then q = 0.1
if not (keyword_set(nbins)) then nbins = 5000

pp_intensity = intensity
pp_snr = snr
pp_background=background

sz = size(intensity)
if (sz[0] ne 2) then message,'Input argument intensity must be a 2d array!'
nt = sz[1] & nf = sz[2]
n = nt*nf

;Detect and remove noisy channels on background spectrum 
pp_background = stddev_filter(background,width=filter_width, $
                              Nsigma=N_sigma,/MED,imod=ibg)

;Produce gaussian noise background
imid = nt/2l
gauss_noise = fltarr(nt,nf)
; split dynamical spectrum into 2 sub spectra along time axis.
snr05_1 = fltarr(nf) & snr05_2 = fltarr(nf)
for j=0l,nf-1l do begin 
   gauss_noise[*,j] = sigma[j]*randomn(seed,nt) + pp_background[j]
   snr05_1[j] = 10.0^(0.1*(get_quantile(10.0*alog10(snr[0:imid-1l,j]),q,nbins=nbins))[0])
   snr05_2[j] = 10.0^(0.1*(get_quantile(10.0*alog10(snr[imid:*,j]),q,nbins=nbins))[0])
endfor

;Detect and remove parasited channels
snr50_1 = median(snr[0:imid-1l,*],dim=1)
snr50_2 = median(snr[imid:*,*],dim=1)

dsnr_1 = 100.*abs(snr50_1 - snr05_1)/snr05_1
dsnr_2 = 100.*abs(snr50_2 - snr05_2)/snr05_2
ichan_1 = where(dsnr_1 gt threshold)
ichan_2 = where(dsnr_2 gt threshold)
ichan = [ibg,ichan_1,ichan_2]
ichan = ichan[uniq(ichan,sort(ichan))]
wchan = where(ichan ge 0l,nichan)
if (wchan[0] ne -1) then ichannels=ichan[wchan] else begin
   ichannels=-1
   return
endelse

pp_intensity[*,ichannels] = !values.f_nan
pp_snr[*,ichannels] = !values.f_nan
pp_background[ichannels] = !values.f_nan
where_notnan = where(finite(pp_background) eq 1)
pp_background = interpol(pp_background[where_notnan],where_notnan,lindgen(nf))
if (FILL) then begin
   pp_intensity[*,ichannels] = gauss_noise[*,ichannels]
   pp_snr[*,ichannels] = 1.0
endif 
if (INTERPOL) then begin
   X = rebin(lindgen(nt),nt,nf) 
   Y = transpose(rebin(lindgen(nf),nf,nt))
   pp_intensity = reform(pp_intensity,n)
   pp_snr = reform(pp_snr,n)
   where_ok = where(finite(pp_intensity) eq 1)
   if (where_ok[0] eq -1) then return
   pp_intensity = pp_intensity[where_ok]
   pp_snr = pp_snr[where_ok]
   X = X[where_ok] & Y = Y[where_ok]
   triangulate,x,y,tr,b
   pp_intensity=trigrid(x,y,pp_intensity,tr,xout=lindgen(nt),yout=lindgen(nf))
   pp_snr=trigrid(x,y,pp_snr,tr,xout=lindgen(nt),yout=lindgen(nf))
endif

return
END
