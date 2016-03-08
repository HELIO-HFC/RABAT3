FUNCTION GET_QUANTILE,V,Q, $
                      binsize=binsize, $
                      max=max,min=min, $
                      nbins=nbins, $
                      missing=missing, $
                      histo=histo, $
                      bins=bins

;+
; NAME:
;		get_quantile	
;
; PURPOSE:
; 		Calculates the given quantile.
;
; CATEGORY:
;		Mathematics, Statistics
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>Result = get_quantile(V,Q)
;
; INPUTS:
;		V	-	Vector of values for which the quantile must be calculated.
;		Q       - 	Quantile ratio.
;	
; OPTIONAL INPUTS: 
;   binsize - Size of bins. Default is 1.
;		nbins	  - Number of bins of the histogram of V used
;             for the calculation. 
;             Ignored if binsize input is provided.
;   max     - Bin maximum value to use to compute the
;             histogram. Default is max(V).
;   min     - Bin minimum value to use to compute the
;             histogram. Default is min(V).
;   missing - Scalar providing the value of missing
;             samples in V vector. Default is !values.f_nan.
;             Missing samples will not be used for the computation.
;
; KEYWORD PARAMETERS:
;		None.
;
; OUTPUTS:
;		The function returns the quantile value
;   of the V vector for the given quantile ratio.		
;
; OPTIONAL OUTPUTS:
;		histo  - Returns the histogram of V.
;   bins   - Returns the histogram bins.
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
; CALL:
;		None.
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin,	26-JUL-2006.
;
;   30-OCT-2013, X.Bonnin:    Renamed xhisto optional
;                             output in bins.
;                      			  Added missing, binsize,
;                             max, and min optional inputs.
;									
;-

IF n_params() LT 2 THEN BEGIN
   message,/info,'Call is:'
   print,'Result = GET_QUANTILE(V,Q,binsize=binsize, $'
   print,'                      nbins=nbins,max=max,min=min, $'
   print,'                      missing=missing,histo=histo,bins=bins)'
   return,0
ENDIF

X=V & nx=n_elements(X) ; use local variable
if not (keyword_set(missing)) then missing=!values.f_nan
if (n_elements(max) eq 0) then max=max(X,/NAN)
if (n_elements(min) eq 0) then min=min(X,/NAN)
if (max le min) then return,0
if not (keyword_set(binsize)) then begin
	if not (keyword_set(nbins)) then nbins=100
endif

w = where(X EQ missing OR finite(X) EQ 0.,nw)
IF (nw EQ nx) THEN return,0
if (w[0] ne -1) then X[w]=!values.f_nan

h = histogram(X,min=min,max=max,binsize=binsize,nbins=nbins,locations=xh,/NAN)

th = total(h,/NAN) & nh = 0. & l = 0L & frac = Q
WHILE l NE n_elements(h)-1 DO BEGIN
   nh = nh+h(l)
   IF nh GE th*frac THEN break
   l = l + 1L
ENDWHILE

histo=h & bins=xh
quantile = xh(l)

return,quantile
END
