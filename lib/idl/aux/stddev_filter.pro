FUNCTION stddev_filter,X,Y,width,Nsigma=N_sigma,Niter=Niter,Imod=Imod, $
				mY=mY, $
                       			ALL_POINTS=ALL_POINTS, $
                       			MED=MED, $
                       			NAN=NAN

;+
;NAME:
;		STDDEV_FILTER
;
;PURPOSE:
;		Replace points more than a specified points deviant from its neighbors.
;
; EXPLANATION:
;		Computes the mean and standard deviation of points in a box centered at
;		each point of the Y-axis vector, but excluding the center point. If the center
;		point value exceeds some # of standard deviations from the mean, it is
;		replaced by the mean in box.
;
; CALLING SEQUENCE:
;		Result = stddev_filter( X,Y,width, Nsigma=(#), /ALL_POINTS)
;
; INPUTS:
;		X = X-axis vector.
;		Y = Y-axis vector.
;
; OPTIONAL INPUTS:
;		width	- Width of filter box, in # points (default = 3).
;		Nsigma  = # standard deviations to define outliers, floating point,
;			recommend > 2, default = 3.
;       Niter  = # of iteration (default = 20.)
;
; KEYWORDS PARAMETERS:
;		/NAN        - Compute also the NAN points.
;       /MED 		- takes the median instead of the mean.
;       /ALL_POINTS - causes computation to include edges of Y vector.
;
; OUTPUT:
;		Y_out - The Y points after computing.
;
; OPTIONAL OUTPUT:
;		Imod - vector containing the subscripts of the pixels which have been modified.
;		mY - local mean/median Y values.
;
; CALL:
;		None.
;
; COMMON BLOCKS:
;		None.
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS/COMMENTS:
;		None.
;
; EXAMPLE:
;		None.
;
; MODIFICATION HISTORY:
;	Written by X.BONNIN:	12-SEP-2007.
;	29-SEP-2010, X.Bonnin:	Added /NAN keyword.
;
;-

if (n_params() lt 2) then begin
	print,'Call is:'
	print,'Result = STDDEV_FILTER(X,Y,width,N_sigma=N_sigma, $'
	print,'                                                  mY=mY, Niter=Niter,Imod=Imod,$'
	print,'                       /NAN,/ALL_POINTS,/MED)'
	return,0
endif

if (~keyword_set(width)) then width = 3
if (~keyword_set(N_sigma)) then N_sigma = 3
if (~keyword_set(Niter)) then Niter = 20
ALL_POINTS = keyword_set(ALL_POINTS)
MED = keyword_set(MED)
NAN = keyword_set(NAN)

nX = n_elements(X)
nY = n_elements(Y)
if (nX ne nY) then return,0
if (nX le width) then return,0

dX = long(width/2.) > 1L

Y_out = Y & Imod = -1 & mY = fltarr(nX)
for i=0L,Niter-1 do begin
	for j=1L,nX-2L do begin
		k = [j-reverse(indgen(dX))-1,j+indgen(dX)+1]
		k = k(where(k ge 0 and k le nX-1 and k ne j))

		if (~MED) then mY[j] = mean(Y_out(k),/NAN) else mY[j] = median(Y_out(k))
		sY = stddev(Y_out(k))

		threshold = N_sigma*sY

		if (abs(Y_out(j)-mY[j]) gt threshold) then begin
			Y_out(j) = mY[j]
			Imod = [Imod,j]
		endif
		if (NAN) and (~finite(Y_out(j))) then begin
			Y_out(j) = mY[j]
			Imod = [Imod,j]
		endif
	endfor
endfor
if (n_elements(Imod) gt 1) then begin
	Imod = Imod(1:*)
	Imod = Imod[uniq(Imod,sort(Imod))]
endif

if (ALL_POINTS) then Y_out = interpol(Y_out(1L:nX-2L),X(1L:nX-2L),X)

return,Y_out
END
