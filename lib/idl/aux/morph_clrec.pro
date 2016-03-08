;+
; NAME:
;		morph_clrec
;
; PURPOSE:
; 		Apply a morpholigical closing by reconstruction.
;		(See Gonzalez and Woods, "Digital Image Processing", Third edition, for more details.)
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>new_array = morph_clrec(array,B0,B1,N0=N0,N1=N1)
;
; INPUTS:
;		array	- 2D array to process.	
;		B0      - Vector or array containing kernel coefficients for dilate operations.
;       B1		- Vector or array containing kernel coefficients for erode operations.
;				  (If B1 is not provided, B1 = B0.)
;
; OPTIONAL INPUTS:
;		N0 - Number of dilate operations to process on input array. Default is 1.
;		N1 - Number of erode operations to process. If N1 is not provided, iterations are performed
;			 as long as output array is not stabilized (i.e., array_k-1 = array_k).
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

FUNCTION morph_clrec,array,B0,B1,N0=N0,N1=N1,$	
					  error=error,SILENT=SILENT

;[1]:Initialize the input parameters
;[1]:===============================
error = 1

if (n_params() lt 2) then begin
	message,/INFO,'Call is:'
	print,'new_array = morph_clrec(array,B0,B1,N0=N0,N1=N1,error=error,/SILENT)'
	return,0
endif

if (~keyword_set(B1)) then B1 = B0
if (~keyword_set(N0)) then N0 = 1
if (~keyword_set(N1)) then N1 = 0

new_array = array

SILENT = keyword_set(SILENT)
;[1]:===============================

;[2]:Compute opening reconstruction
;[2]:==========================
for i=0L,N0-1L do new_array = dilate(new_array,B0)

N = 0 
while (N1 ge N) do begin
	arr0 = new_array
	new_array = erode(new_array,B1) OR array
	if (total(new_array-arr0) eq 0) then break
	if (N1 eq 0) then N = 0 else N++
endwhile

;[2]:==========================


error = 0
return,new_array
END