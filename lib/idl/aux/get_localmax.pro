FUNCTION get_localmax,array,dimension,$
                      ilocalmin=ilocmin, $
                      localmax=localmax, nmax=nmax, $
                      localmin=localmin, nmin=nmin, $
                      VERBOSE=VERBOSE

;+
; NAME:
;	get_localmax
;
; PURPOSE:
; 	Returns the subscripts of the local maxima of 
;	the input array along a given dimension.
;
; CATEGORY:
;	Image processing
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL>ilocalmax = get_localmax(array,dimension)
;
; INPUTS:
;	array	  - 2d array or vector for which 
;		        the local maxima must be identified.	
;	dimension - Dimension along which the local maxima are returned.
;               Default is 1.
;
; OPTIONAL INPUTS:
;   None.
;
; KEYWORD PARAMETERS:
;	/VERBOSE - Talkative mode.
;
; OUTPUTS:
;	ilocalmax - Vector of long type containing the subscripts of the local maxima.
;
;
; OPTIONAL OUTPUTS:
;   ilocalmin           - Vector of long type containing the local minima subscripts.
;   localmax            - 2d binary array or vector where locmax[ilocmax] = 1b, 0b otherwise.
;   localmin            - 2d binary array or vector where locmin[ilocmin] = 1b, 0b otherwise.
;   nmax                - Number of maxima found.
;   nmin                - Number of minima found.
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
;	None.
;
; EXAMPLE:
;	None.		
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2010.
;
;       20-JAN-2012, X.Bonnin:  Added localmin and localmax optional outputs.
;					
;-

;[1]:Initialize the input parameters
;[1]:===============================
if (n_params() lt 1) then begin
   message,/INFO,'Call is:'
   print,'ilocalmax = get_localmax(array,dimension, $'
   print,'                         ilocalmin=ilocalmin, $'
   print,'                         localmax=localmax,localmin=localmin, $'
   print,'                         nmax=nmax,nmin=nmin, $'
   print,'                         error=error,/VERBOSE)'
   return,-1
endif
VERBOSE = keyword_set(VERBOSE)

arr = array

if (not keyword_set(dimension)) then dim = 1 else dim = fix(dimension[0])
sz = size(arr)
nx = sz[1]
if (sz[0] eq 1) then begin
    dim = 1
    ny = 1
    narr = nx

    if (nx lt 3) then begin
        if (VERBOSE) then message,/CONT,'Input vector must have at least 3 elements!'
        return,-1   
    endif
endif

if (sz[0] eq 2) then begin  
    ny = sz[2] 
    narr = sz[4]

    if (nx lt 3) or (ny lt 3) then begin
        if (VERBOSE) then message,/CONT,'Input array must be at least a [3,3] matrix!'
        return,-1   
    endif
endif

if (dim eq 2) then begin
    arr = transpose(arr)     
    nx = sz[2]
    ny = sz[1]
endif
;[1]:===============================

;[2]:identify local max
;[2]:==================

localmax = bytarr(nx,ny)
localmin = bytarr(nx,ny)
for j=0l,ny-1l do begin
    ;Case of first point
    if (array[0,j] gt array[1,j]) then localmax[0,j] = 1b
    if (array[0,j] lt array[1,j]) then localmin[0,j] = 1b

    for i=0l,nx-3l do begin
       i1 = i + 1l
       if (array[i1,j] gt array[i1-1l,j]) and (array[i1,j] gt array[i1+1l,j]) then localmax[i1,j] = 1b
       if (array[i1,j] lt array[i1-1l,j]) and (array[i1,j] lt array[i1+1l,j]) then localmin[i1,j] = 1b
    endfor
    
    ;Case of last point
    if (array[nx-1l,j] gt array[nx-2l,j]) then localmax[nx-2l,j] = 1b
    if (array[nx-1l,j] lt array[nx-2l,j]) then localmin[nx-2l,j] = 1b
endfor

if (dim eq 2) then begin
    localmax = transpose(localmax)
    localmin = transpose(localmin)
endif

ilocalmax = where(localmax gt 0b,nmax)
ilocalmin = where(localmin gt 0b,nmin)

return,ilocalmax
END
