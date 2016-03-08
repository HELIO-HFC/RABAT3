FUNCTION morph_oprec,array,B0,B1,N0=N0,N1=N1,$	
				     error=error,SILENT=SILENT

;+
; NAME:
;		morph_oprec
;
; PURPOSE:
; 		Apply a morpholigical opening by reconstruction.
;		(See Gonzalez and Woods, "Digital Image Processing", Third edition, for more details.)
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>new_array = morph_oprec(array,B0,B1,N0=N0,N1=N1)
;
; INPUTS:
;		array	- 2D array to process.	
;		B0      - Vector or array containing kernel coefficients for erode operations.
;       B1		- Vector or array containing kernel coefficients for dilate operations.
;				  (If B1 is not provided, B1 = B0.)
;
; OPTIONAL INPUTS:
;		N0 - Iteration number of erode operations to process on the input array. 
;            By default, the erode operation is performed as long as
;            the array is not stabilized (i.e, array_k-1 = array_k).
;		N1 - Iteration number of dilate operations to process. 
;            By default, the dilate operation is performed
;			 as long as the output array is not stabilized (i.e., array_k-1 = array_k).
;		
;
; KEYWORD PARAMETERS:
;		/SILENT - Quiet mode.
;
; OUTPUTS:
;		new_array - The 2D array (in byte) after reconstruction operation.		
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

if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'new_array = morph_oprec(array,B0,B1,N0=N0,N1=N1,error=error,/SILENT)'
	return,0
endif

if (~keyword_set(B1)) then B1 = B0
if (~keyword_set(N0)) then N0 = 0
if (~keyword_set(N1)) then N1 = 0

new_array = array

SILENT = keyword_set(SILENT)
;[1]:===============================

;[2]:Compute opening reconstruction
;[2]:==========================
N = 0
while (N0 ge N) do begin
	arr0 = new_array
	new_array = erode(new_array,B0) AND array
	if (total(new_array) eq 0) then break
	if (total(new_array-arr0) eq 0) then break
	if (N0 eq 0) then N = 0 else N++
endwhile 
new_array = arr0

N = 0 
while (N1 ge N) do begin
	arr0 = new_array
	new_array = dilate(new_array,B1) AND array
	if (total(new_array-arr0) eq 0) then break
	if (N1 eq 0) then N = 0 else N++
endwhile

;[2]:==========================


error = 0
return,new_array
END