FUNCTION rabat3_parseconfig,config_file,$
                            VERBOSE=VERBOSE


;+
; NAME:
;	rabat3_parseconfig
;
; PURPOSE:
; 	Read and parse the configuration file
;
; CATEGORY:
;	I/O
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL> args = rabat3_parseconfig(config_file)
;
; INPUTS:
;	config_file - Pathname of the configuration file to parse.
;
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	/VERBOSE	- Talkative mode.
;
; OUTPUTS:
;	args - Structure containing the rabat3 input arguments.
;
;
; OPTIONAL OUTPUTS:
;	None.
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
;	rabat3_config__define
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by:		X.Bonnin, 26-JUL-2011.
;
;-

;On_error,2
if (n_params() lt 1) then begin
   message,/INFO,'Call is:'
   print,'args = rabat3_parseconfig(config_file,/VERBOSE)'
   return,0
endif
VERBOSE=keyword_set(VERBOSE)

if (~file_test(config_file)) then $
   message,config_file+' not found!'

args = {rabat3_config}
nargs = n_tags(args)
tags = strupcase(tag_names(args))

nlines  = file_lines(config_file)
;if (nlines ne nargs) then $
;   message,'Number of input arguments is incorrect!'


openr,lun,config_file,/GET_LUN
for i=0,nlines-1 do begin
   data_i = ""
   readf,lun,data_i
   data_i = strtrim(strsplit(data_i,'=',/EXTRACT),2)
   tag_i = strupcase(data_i[0]) & data_i = strsplit(data_i[1],',',/EXTRACT)

   where_tag=(where(tag_i eq tags))[0]
   if (where_tag ne -1) then args.(where_tag)=data_i
endfor
close,lun
free_lun,lun

error = 0
return,args
END
