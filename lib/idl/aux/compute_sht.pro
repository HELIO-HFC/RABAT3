FUNCTION compute_sht,array,$
				X=X,Y=Y,Z=Z,$
				sigma=sigma,$
				Mht=Mht,error=error,$
				GAUSSIAN=GAUSSIAN,NORMALIZE=NORMALIZE,$
				BACKPROJECTION=BACKPROJECTION,SILENT=SILENT

;+
; NAME:
;		compute_sht
;
; PURPOSE:
; 		Calculates the sweeping Hough transform of an input 2D array .
;		(See Lobzin et al., SW, 2009 for a description of the sweeping Hough transform).
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>sht = compute_sht(array)
;
; INPUTS:
;		array - The 2D array [X,Y] to process.
;				(if /BACKPROJECTION is set, array must be the
;				 2D Hough transform [X,Z]).
;
; OPTIONAL INPUTS:
;		X     - Vector containing the first dimension (X) coordinates of the
;			    input array/Hough transform.
;		Y     - Vector containing the second dimension (Y) coordinates of the
;				input array.
;		Z     - Vector containing the second dimension (Z) coordinates of the Hough transform.
;		sigma - If greater than 0, the Hough transform is computed as follows:

;					sht[X,Z] = Sum_j(Sum_i(array[Xi-X,Yj]*time_window[Xi-X])*delta(Xi,Yj,Z))

;				, where delta(Xi,Yj,Z) = 1,
;				  if Xi = (Z/(max(Y)-min(Y)))*Yj + (X - (Z*min(Y)/(max(Y)-min(Y))))
;				,and 0 else, and time_window[Xi-X] is normalized function centered on X.
;				if /GAUSSIAN is set, time_window is a gaussian function, else is
;				a rectangular function.
;
; KEYWORD PARAMETERS:
;		/GAUSSIAN       - Use gaussian to sum Hough transform over time axis.
;		/NORMALIZE      - Normalize the Hough transform returned using nY*Sum_i()
;		/BACKPROJECTION - If set, the back projection is computed.
;		/SILENT         - Quiet mode.
;
; OUTPUTS:
;		sht - The sweeping Hough transform [X,Z] of the input array.
;			 (If /BACKPROJECTION is set, return the backprojection
;			  of the input Hough transform.)
;
; OPTIONAL OUTPUTS:
;		Mht		- The 3D matrix mht[X,Y,Z].
;		error   - Equal to 1 if an error occurs, 0 else.
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
;		Written by X.Bonnin,	26-JUL-2010.
;
;		10-SEP-2011, X.Bonnin:	Added /BACKPROJECTION keyword.
;		20-SEP-2014, X.Bonnin:	Renamed function name from
;						compute_hough to compute_sht.
;
;-

;[1]:Initialize the input parameters
;[1]:===============================
error = 1

if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'sht=compute_sht(array,$'
	print,'                X=X,Y=Y,Z=Z,'
	print,'                Mhg=Mhg,sigma=sigma,$'
	print,'                error=error,/NORMALIZE,$'
	print,'                /BACKPROJECTION,/GAUSSIAN,/SILENT)'
	return,0
endif
SILENT = keyword_set(SILENT)
GAUSSIAN = keyword_set(GAUSSIAN)
NORMALIZE = keyword_set(NORMALIZE)
BACKPROJECTION = keyword_set(BACKPROJECTION)

sz = size(array,/DIM)
if (n_elements(sz) ne 2) then message,'ARRAY input argument must have two dimensions!'
nX = sz[0]
if (BACKPROJECTION) then begin
	nZ = sz[1]
	if (~keyword_set(Y)) then nY = nX
endif else begin
	nY = sz[1]
	if (~keyword_set(Z)) then nZ = nX
endelse

if (~keyword_set(X)) then X = findgen(nX)
if (~keyword_set(Y)) then Y = findgen(nY)
if (~keyword_set(Z)) then Z = findgen(nZ)
dX = median(deriv(X))
dZ = median(deriv(Z))
nX = n_elements(X)
nY = n_elements(Y)
nZ = n_elements(Z)

if (~keyword_set(sigma)) then sigma = 0.
isigma = round(sigma/dX)
;[1]:===============================

;[2]:Calculate the Hough transform (if /BACKPROJECTION is not set)
;[2]:=============================
dk = findgen(nZ)*(dZ/dX)
dj = findgen(nY)/(nY-1.)
Zoffset = long(min(Z)/dX)

if not (BACKPROJECTION) then begin

	;array = 0 at time edges
	arr = array
	arr[0:isigma,*] = 0
	arr[nX-1L-isigma,*] = 0

	Xc = mean(X)
	if (GAUSSIAN) then wdw0 = exp(-0.5*((X - Xc)/sigma)^2) else wdw0 = fltarr(nX)
	iXc = round(Xc/dX)

	Mhg = fltarr(nX,nY,nZ)
	for i=0,nX-1 do begin
		for j=0,nY-1 do begin
			di = i + dj[j]*(dk + Zoffset)
			ldi = round(di)>(0L)<(nX-1L)
			if (sigma le 0.) then Mhg[i,j,*] = arr[ldi,j] else begin
				for k=0L,nZ-1L do begin
					if (GAUSSIAN) then begin
						wdw = shift(wdw0,ldi[k]-iXc)
					endif else begin
						wdw = wdw0
						i0 = round(ldi[k] - isigma)>(0)
						i1 = round(ldi[k] + isigma)<(nX-1L)
						wdw[i0:i1] = 1.
					endelse
					Mhg[i,j,k] = total(arr[*,j]*wdw)
				endfor
			endelse
		endfor
		;if not (SILENT) then begin
		;	printl,'Computing Hough transform: '+string(100.*(i+1L)/float(nX),$
		;		  format='(f6.2)')+'% completed.'
		;endif
	endfor

	;Sum on second dimension Y of array
	sht = total(Mhg,2)

	if (NORMALIZE) then begin
		if (GAUSSIAN) then nrm = float(ny)*total(exp(-0.5*((X-Xc)/sigma)^2)) $
			else $
		nrm = float(nY)*(2.*round(sigma/dX) + 1.)
	endif else nrm = 1.

	sht = sht/nrm
endif else begin

	;Compute the backprojection of the Hough transform
	sht = fltarr(nX,nY)
	count = fltarr(nX,nY)
	for i=0L,nX-1L do begin
		;if (~SILENT) then $
		;	printl,'Computing backprojection Hough transform: '+$
		;	string(100.*(i+1L)/float(nX),$
		;	format='(f6.2)')+'% completed.'
		for k=0L,nZ-1L do begin
			di = i + dj*(dk[k] + Zoffset)
			ldi = round(di)>(0L)<(nX-1L)
			for j=0,nY-1L do begin
				sht[ldi[j],j] = sht[ldi[j],j]+array[i,k]
				count[ldi[j],j]++
			endfor
		endfor
	endfor

	wok = where(count ne 0.)
	sht[wok] = sht[wok]/count[wok]
endelse
;if (~SILENT) then print,''

error = 0
return,sht
END
