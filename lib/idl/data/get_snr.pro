FUNCTION get_snr,intensity,background,b,tau, $
                 nsample=nsample, sigma=sigma
                        
;+
; NAME:
;	get_snr
;
; PURPOSE:
;	Compute the average signal on noise ratio 
;       of radio signals.
;
; CATEGORY:
;	Radio astronomy
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL>snr = get_snr(intensity,background,b,tau)
;
; INPUTS:
;	intensity  - 2d array providing the radio intensity
;                    as a function of time and frequency 
;                    (including total background).
;                    as a function of the time and frequency.
;       background - Vector providing the background spectrum.
;       b          - Frequency Bandwidth (in Hz).
;       tau        - Integration time (in sec).
;	
; OPTIONAL INPUTS:
;       nsample    - Number of data samples between two spectra.
;                    Default is 1 (full cadence). 
;
; KEYWORD PARAMETERS:
;      None.
;
; OUTPUTS:
;	snr - 2 array providing the signal on noise ratio.
;
; OPTIONAL OUTPUTS:
;       sigma - Averaged intensity fluctuations.
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
;       None.
;
; EXAMPLE:
;	None.	
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin (LESIA),	26-JUL-2011.
;
;-
						
snr=0b
if (n_params() lt 4) then begin
   message,/INFO,'Call is:'
   print,'snr = get_snr(intensity, background, b ,tau, $'
   print,'              nsample=nsample,sigma=sigma)'
   return,snr
endif 
if not (keyword_set(nsample)) then nsample = 1
ns = float(nsample)
sz = size(intensity)
if (sz[0] ne 2) then message,'Input argument intensity must be a 2d array!'
nt = sz[1] & nf = sz[2]

rms = 1./sqrt(b*tau*ns)

;Compute signal on noise ratio (snr)
nf = n_elements(background)
snr = fltarr(nt,nf) & sigma = fltarr(nf)

for j=0L,nf-1L do begin
   int_j = intensity[*,j]
   bg_j = background[j]
   snr[*,j] = int_j - bg_j
   sigma_j = bg_j*rms
   snr[*,j] = snr[*,j]/sigma_j
   sigma[j] = sigma_j
endfor

return,snr
END
