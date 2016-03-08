FUNCTION resample,Array,X,$
                  dimension=dimension,$
                  error=error

;+
; NAME:
;		resample
;
; PURPOSE:
; 		Resample a vector or an array, along the dimension
;		specified as an input, according to the input vector.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>new_array = resample(Array,X)
;
; INPUTS:
;		Array - 1D or 2D array to resample.
;		X	  - Vector containing the sampling values
;			    along X axis (or Y if dimension=2). 
;
; OPTIONAL INPUTS:
;		dimension - If array has 2 dimensions, scalar of integer type 
;					specifying the dimension along with the sampling 
;					must be performed. Default is 1.
;
; KEYWORD PARAMETERS:
;		None.
;
; OUTPUTS:
;		new_array - Same than input array, but resampled along the
;					axis specified by input dimension.	
;
; OPTIONAL OUTPUTS:
;		error 	- Equal to 1 if an error occurs, 0 else.
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
;		Written by X.Bonnin,	26-JUL-2011.
;					
;-

error = 1
if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'new_array = resample(array,X,dimension=dimension,error=error)'
	return,0
endif					   

if (~keyword_set(dimension)) then dimension = 1
sz = size(array)
nX = n_elements(X)
if (dimension eq 1) then begin
	if (nX ne sz[1]) then begin
		message,/INFO,'Array and X have incompatible dimensions!'
		return,0
	endif
endif else begin
	if (sz[0] ne 2) then begin
		message,/INFO,'Array must have 2 dimensions!'
		return,0
	endif
	if (nX ne sz[2]) then begin
		message,/INFO,'Array and X have incompatible dimensions!'
		return,0
	endif
endelse

jp = findgen(nX) * (max(X) - min(X)) / (nX-1L) + min(X)
js = interpol(findgen(nX), X, jp)

if (sz[0] eq 1) then begin
	new_array = interpolate(array,js) 
endif else begin
	if (dimension eq 1) then $
		new_array = interpolate(array,js,lindgen(sz[2]),/GRID) $
	else $
		new_array = interpolate(array,lindgen(sz[1]),js,/GRID)
endelse

error = 0
return,new_array
END
