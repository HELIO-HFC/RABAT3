FUNCTION local_mean,X,width,$
                    Xmed=Xmed,$
                    Xmin=Xmin,Xmax=Xmax,$
                    Xstd=Xstd,Xtot=Xtot,$
                    EDGES_INTERPOLATION=EDGES_INTERPOLATION,$
                    ONLY_NEIGHBOURS=ONLY_NEIGHBOURS,$
                    NAN=NAN

if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'Xmean = local_mean(X,width,$)'
	print,'                   Xmed=Xmed,$'
	print,'                   Xmin=Xmin,Xmax=Xmax,$'
	print,'                   Xstd=Xstd,Xtot=Xtot,$'
	print,'                   /EDGES_INTERPOLATION,$'
	print,'                   /ONLY_NEIGHBOURS,/NAN'
	return,0
endif
			
EDGES = keyword_set(EDGES_INTERPOLATION)
ONLY = keyword_set(ONLY_NEIGHBOURS)
NAN = keyword_set(NAN)

if (~keyword_set(width)) then width = 5					
if (width le 1) then begin
	message,/INFO,'Input argument WIDTH must greater than 1'
	return,0
endif

nX = n_elements(X)
if (nX lt width) then begin
	message,/INFO,'Number of elements of X is lesser than width!'
	return,0
endif
wdth = long(0.5*width[0])

Xmean = fltarr(nX) + !VALUES.F_NAN
Xstd = fltarr(nX) + !VALUES.F_NAN
Xmin = fltarr(nX) + !VALUES.F_NAN
Xmax = fltarr(nX) + !VALUES.F_NAN
Xmed = fltarr(nX) + !VALUES.F_NAN
Xtot = fltarr(nX) + !VALUES.F_NAN
for i=0L,nX-1L do begin
	i0 = (i - wdth)>0L
	i1 = (i + wdth)<(nX-1L)
	
	Xi = X[i0:i1]
	if (ONLY) then $
		Xi = [X[i0:(i-1L)>0L],X[(i+1L)<(nX-1L):i1]]	
		
	Xmean[i] = mean(Xi,NAN=NAN)
	Xstd[i] = stddev(Xi,NAN=NAN)
	Xmin[i] = min(Xi,NAN=NAN)
	Xmax[i] = max(Xi,NAN=NAN)
	Xmed[i] = median(Xi)
	Xtot[i] = total(Xi)
endfor

if (EDGES) then begin
	i = lindgen(nX - 2L*wdth) + wdth
	Xmean = interpol(Xmean[wdth:nX-1L-wdth],i,lindgen(nX))
	Xstd = interpol(Xstd[wdth:nX-1L-wdth],i,lindgen(nX))
	Xmin = interpol(Xmin[wdth:nX-1L-wdth],i,lindgen(nX))
	Xmax = interpol(Xmax[wdth:nX-1L-wdth],i,lindgen(nX))
	Xmed = interpol(Xmed[wdth:nX-1L-wdth],i,lindgen(nX))
	Xtot = interpol(Xtot[wdth:nX-1L-wdth],i,lindgen(nX))
endif


return,Xmean					
END
