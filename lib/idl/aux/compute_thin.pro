FUNCTION compute_thin,array,error=error,SILENT=SILENT

;+
; NAME:
;		compute_thin
;
; PURPOSE:
; 		Apply a thinning morphological operator on the input array.
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>thin_array = compute_thin(array)
;
; INPUTS:
;		array	-	2D array to thin.	
;
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		/SILENT - Quiet mode.
;
; OUTPUTS:
;		thin_array - The 2D array after thinnig operation.		
;
; OPTIONAL OUTPUTS:
;		error - Equal to 1 if an error occurs, 0 else.
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
;		printl
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin,	14-APR-2011.			
;									
;-


;[1]:Initialize the input parameters
;[1]:===============================
error = 1

if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'compute_thin,array,error=error,/SILENT'
	return,0
endif

SILENT = keyword_set(SILENT)

thinImg = array
;[1]:===============================

;[2]:Compute thinning operator
;[2]:==========================

;Define hit and miss structures
h0 = [[0b,0,0], $ 
      [0,1,0], $ 
      [1,1,1]] 
m0 = [[1b,1,1], $ 
      [0,0,0], $ 
      [0,0,0]] 
h1 = [[0b,0,0], $ 
      [1,1,0], $ 
      [1,1,0]] 
m1 = [[0b,1,1], $ 
      [0,0,1], $ 
      [0,0,0]] 
h2 = [[1b,0,0], $ 
      [1,1,0], $ 
      [1,0,0]] 
m2 = [[0b,0,1], $ 
      [0,0,1], $ 
      [0,0,1]] 
h3 = [[1b,1,0], $ 
      [1,1,0], $ 
      [0,0,0]] 
m3 = [[0b,0,0], $ 
      [0,0,1], $ 
      [0,1,1]] 
h4 = [[1b,1,1], $ 
      [0,1,0], $ 
      [0,0,0]] 
m4 = [[0b,0,0], $ 
      [0,0,0], $ 
      [1,1,1]] 
h5 = [[0b,1,1], $ 
      [0,1,1], $ 
      [0,0,0]] 
m5 = [[0b,0,0], $ 
      [1,0,0], $ 
      [1,1,0]] 
h6 = [[0b,0,1], $ 
      [0,1,1], $ 
      [0,0,1]] 
m6 = [[1b,0,0], $ 
      [1,0,0], $ 
      [1,0,0]] 
h7 = [[0b,0,0], $ 
      [0,1,1], $ 
      [0,1,1]] 
m7 = [[1b,1,0], $ 
      [1,0,0], $ 
      [0,0,0]] 

bCont = 1b 
iIter = 1 

inan = where(~finite(array))
if (inan[0] ne -1) then thinImg[inan] = 0
 

WHILE bCont EQ 1b DO BEGIN
   ;if (~SILENT) then printl,'Thinning processing...'
   inputImg = thinImg 
   thinImg = MORPH_THIN(inputImg, h0, m0) 
   thinImg = MORPH_THIN(thinImg, h1, m1)  
   thinImg = MORPH_THIN(thinImg, h2, m2) 
   thinImg = MORPH_THIN(thinImg, h3, m3) 
   thinImg = MORPH_THIN(thinImg, h4, m4) 
   thinImg = MORPH_THIN(thinImg, h5, m5) 
   thinImg = MORPH_THIN(thinImg, h6, m6) 
   thinImg = MORPH_THIN(thinImg, h7, m7) 
   bCont = MAX(inputImg - thinImg) 
   iIter = iIter + 1 
ENDWHILE 

;[2]:==========================

thin_array = thinImg
if (inan[0] ne -1) then thin_array[inan] = !values.f_nan

error = 0
return,thin_array
END
