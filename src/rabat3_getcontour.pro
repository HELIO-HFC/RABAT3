FUNCTION rabat3_getcontour,intensity,time,frequency,tskeleton, $
                           smooth_width=smooth_width, $
                           Pdrift=Pdrift,min_val=min_val, $
                           nmin=nmin, $
                           chain=chain, cc_pix=cc_pix, $
                           VERBOSE=VERBOSE

;+
; NAME:
;	rabat3_getcontour
;
; PURPOSE:
; 	This function extracts the burst's contour
;       providing the times of the burst skeleton
;       at each frequency.
;
; CATEGORY:
;	Image processing
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>cpix = rabat3_getcontour(intensity,time,frequency,tske)
;
; INPUTS:
;	intensity  - 2d array containing the radio intensity values 
;                    as a function of the time and frequency 
;                    (i.e., dynamical spectrum).
;       time       - Vector containing the first dimension variable
;                    of the 2d array (i.e., time in seconds).
;       frequency  - Vector containing the second dimension variable
;                    of the 2d array (i.e., frequency in MHz).
;       tskeleton  - Vector containing the time values of the burst skeleton
;                    at each frequency.
;
; OPTIONAL INPUTS:
;       Pdrift       - 2-elements vector containing the parameters to
;                      compute the type 3 burst drift correction.
;                      (Only applied if Pdrift ne [0,0].)
;	smooth_width - Integer that provides the window width to use for the
;                      smoothing process along time dimension.
;                      Default is 0 (no smoothing).
;       min_val      - Minimum intensity value allowed for 
;                      the burst time profile peak.
;       nmin         - Minimal number of frequencies above which the event
;                      is selected. Default is 0.
;
; KEYWORD PARAMETERS:
;	/VERBOSE     - Talkative mode.
;
; OUTPUTS:
;	cpix	- [2,n] array providing the (n times [X,Y]) pixels of the
;                 burst's contour.
;
; OPTIONAL OUTPUTS:
;	chain	- returns a string containing the chain code of the contour.
;       cc_pix  - 2-elements vector providing the starting pixel location
;                 of the chain code.
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
;	type3_driftrate_func
;       get_localmax 
;       morph_oprec
;       image2chain    
;
; EXAMPLE:
;	None.		
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2011.
;					
;-


cpix = -1
if (n_params() lt 4) then begin
   message,/INFO,'Call is:'
   print,'contour = rabat3_getcontour(intensity,time,frequency,tskeleton, $'
   print,'                            smooth_width=smooth_width, $'
   print,'                            Pdrift=Pdrift,min_val=min_val, $'
   print,'                            chain=chain,cc_pix=cc_pix,nmin=nmin,/VERBOSE)'
   return,-1
endif						   
VERBOSE=keyword_set(VERBOSE)
if not (keyword_set(Pdrift)) then Pdrift=[0.0,0.0]
if not (keyword_set(min_val)) then min_val=0.0
if not (keyword_set(smooth_width)) then smooth_width=0		
if not (keyword_set(nmin)) then nmin=0l		

nt = n_elements(time)
nf = n_elements(frequency)		
tske=tskeleton

array = (smooth(intensity,smooth_width))>0.0			   
;Correct binary mask from type iii average drift rate
if (total(Pdrift) ne 0.0) then begin
   if (VERBOSE) then print,'Shifting time axis...'
   tdrift = type3_driftrate_func(frequency,$
                                 [Pdrift,0])
   tske = tske - tdrift
   dt = median(abs(deriv(time)))
   idrift = round((tdrift)/dt)
   for j=0L,nf-1L do array[*,j] = shift(array[*,j],-idrift[j])
	
   if (VERBOSE) then print,'Shifting time axis...done'
endif else idrift=fltarr(nf)
ipeak = round(tske/dt)
array[0,*] = 0.0 & array[nt-1l,*]=0.0

ilocmax = get_localmax(array,1,$
                       localmax=lm, $
                       VERBOSE=VERBOSE)

n=0l & k0_min=nt & k1_max=-1 & imax=lonarr(nf)
mask = bytarr(nt,nf)
for j=0,nf-1 do begin
   ipeak_j = ipeak[j]
   if (ipeak_j le 0) or (ipeak_j ge nt-1) then continue
   dtmin = min(abs(ipeak_j + j*nt - ilocmax),imin)
   imax_i = ilocmax[imin] mod nt
   if (array[imax_i,j] lt min_val) then continue
   print,ipeak_j,imax_i
   didt = deriv(time,array[*,j])
   didt[0] = 0.0 & didt[nt-1] = 0.0
   
   k0=imax_i
   repeat begin
      k0-- 
      flag = ((didt[k0] le 0.0) and (array[k0,j] ge min_val))
   endrep until (flag eq 0b)
	
   k1=imax_i
   repeat begin
      k1++
      flag = ((didt[k1] ge 0.0) and (array[k1,j] ge min_val))
   endrep until (flag eq 0b)

; Autre possibilité à tester (X.B)
   ;; i_onset=intarr(nf) & i_offset=intarr(nf)
   ;; for j=0,nf-1 do begin
   ;;    ifit_j = long((tfit[j] - min(time,/NAN))/dt)
      
   ;;    k=ifit_j-1l
   ;;    while (k gt 0l) and (spectra[k,j] gt spectra[k-1,j]) do k--
   ;;    i_onset[j]=k-1l

   ;;    k=ifit_j+1l
   ;;    while (k lt nt-1l) and (spectra[k,j] lt spectra[k-1,j]) do k++
   ;;    i_offset[j]=k+1l
   ;; endfor

   where_in = where(time ge time[k0] and time le time[k1])
   mask[where_in,j] = 1b
   n++ 
   k0_min=min([k0_min,k0])
   k1_max=max([k1_max,k1])
   imax[j] = imax_i
endfor
if (n lt nmin) then return,-1
stop
; Merge possible parts of the burst separated by bad channels
kernel = transpose([1,1,1,1,1])
mask = morph_close(mask,kernel)

; Remove isolated pixels
K = bytarr(3,3) + 1b
mask=morph_oprec(mask,K,K)

; Correct from burst time drifting
for j=0L,nf-1L do mask[*,j] = shift(mask[*,j],+idrift[j])

; Build contour
cont = mask - erode(mask,K)

chain = image2chain(cont,start_pix=cc_pix,X=X,Y=Y)
npix = n_elements(X)
cpix = lonarr(2,npix)
cpix[0,*] = X & cpix[1,*] = Y

return,cpix
END
