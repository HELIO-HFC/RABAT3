PRO write_csv, struct, output_path, $
               separator=separator,error=error,$
               APPEND=APPEND


;+
; NAME:
;	write_csv
;
; PURPOSE:
;   	Write fields provided in the input structure into a csv format file.
;
; CATEGORY:
;	I/O
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL>write_csv, struct, output_path
;
; INPUTS:
;       struct  - Structure containing the fields to write.
;       output_path - Full path (directory + filename) to the output file.    
;
; OPTIONAL INPUTS:
;       separator - Specify the separator character between fields.
;                   Default is ";"	    
;
; KEYWORD PARAMETERS:
;       /APPEND - Equivalent to /APPEND keyword for openw procedure.
;
; OUTPUTS:
;	None.				
;
; OPTIONAL OUTPUTS:
;	error - Scalar equal to 1 if an error occurs, 0 otherwise.		
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
;	struct2csv
;
; EXAMPLE:
;	None.
;		
; MODIFICATION HISTORY:
;	Written by:		X.Bonnin (LESIA).
;
;-

error = 1
if (n_params() lt 2) then begin
    message,/INFO,'Call is:'
    print,'write_csv, struct, output_path, $'
    print,'           separator=separator, error=error, $'
    print,'           /APPEND'
    return
endif

APPEND = keyword_set(APPEND)
if not (keyword_set(separator)) then sep = ';' else sep = strtrim(separator[0],2)

outpath = strtrim(output_path[0],2)
if (not file_test(file_dirname(outpath),/DIR)) then begin
    message,/CONT,'Output directory does not exist!'
    return
endif
if (not file_test(outpath)) then APPEND = 0

fields = struct2csv(struct,header=header,separator=sep)

openw, lun, outpath , /get_lun, APPEND=APPEND
if (not APPEND) then printf,lun,header
for i=0l,n_elements(fields)-1l do printf,lun,fields[i]
close,lun
free_lun,lun

error = 0
END
