FUNCTION prep_gsfc_rad2,intensity,frequency,background, $
                        b=b, tau=tau, nsample=nsample, $
                        width=width , dsnr=dsnr, $
                        nsplit=nsplit,threshold=threshold, $
                        quantile=quantile, nbins=nbins, $
                        pp_background=pp_background, $
                        gauss_noise=gauss_noise, snr=snr, $
                        sigma=sigma,noisy_channel=noisy_channel, $
                        REMOVE_PARASITES=REMOVE_PARASITES

noisy_channel=-1
if (n_params() lt 3) then begin
   message,/INFO,'Call is:'
   print,'pp_intensity = prep_gsfc_rad2(intensity,frequency,background, $'
   print,'                              b=b, tau=tau, nsample=nsample, $'
   print,'                              width=width, quantile=quantile, $'
   print,'                              nbins=nbins, dsnr=dsnr, $'
   print,'                              gauss_noise=gauss_noise, $'
   print,'                              threshold=threshold,nsplit=nsplit, $'
   print,'                              pp_background=pp_background, $'
   print,'                              sigma=sigma, snr=snr, $'
   print,'                              noisy_channel=noisy_channel, $'
   print,'                              /REMOVE_PARASITES)'
   return,0b
endif
REMOVE_PAR = keyword_set(REMOVE_PARASITES)
if not (keyword_set(width)) then width=9
if not (keyword_set(threshold)) then threshold=200
if not (keyword_set(nsplit)) then nsplit=1
if not (keyword_set(quantile)) then quantile=0.1
if not (keyword_set(nbins)) then nbins=5000
if not (keyword_set(b)) then b = 20000. ;Hz
if not (keyword_set(tau)) then tau = 20.0e-3 ; sec
if not (keyword_set(nsample)) then nsample=3

int=intensity & bg = background
dim = size(int,/DIM)
nt = dim[0] & nf = dim[1]

; Detect and remove noisy channels on background spectrum 
pp_background = stddev_filter(frequency,bg,width,/MED,imod=ibg)

; Compute signal on noise ratio
snr = get_snr(int,pp_background,b,tau, $
              nsample=nsample, sigma=sigma, $
              /REMOVE_BACKGROUND)

; Remove parasited channels
if (REMOVE_PAR) then begin

; Produce gaussian noise + bg above bg
   nband=long(nt/nsplit)
   gauss_noise = fltarr(nt,nf) 
   dsnr = fltarr(nsplit,nf) & ichan=ibg
   for j=0l,nf-1l do begin
      gauss_noise[*,j] = pp_background[j] + sigma[j]*randomn(seed,nt)
      k0=0l
      for k=0,nsplit-1 do begin
         k1=k0 + nband
         snr_k = snr[k0:k1-1l,j]
         sub_snr = 10.0^(0.1*get_quantile(10.0*alog10(snr_k),quantile,nbins=nbins))
         dsnr_k = 100.*abs(median(snr_k) - sub_snr)/sub_snr
         dsnr[k,j]=dsnr_k
         if (dsnr_k gt threshold) then begin
            int[*,j] = gauss_noise[*,j]
            snr[*,j] = (int[*,j] - pp_background[j])/sigma[j]
            ichan = [ichan,j]
         endif
         k0=k1
      endfor 
   endfor
   ichan = ichan[uniq(ichan,sort(ichan))]
   wchan = where(ichan ge 0l,nichan)
   if (wchan[0] ne -1) then noisy_channel=ichan[wchan]
endif    

return,int
END                        
