PRO get_waves_gsfc_file,date,receiver, $
                        target_dir=target_dir, $
                        tries=tries, $
                        url=url,filepath=filepath, $
                        VERBOSE=VERBOSE, QUIET=QUIET, $
                        ASCII=ASCII,NOCLOBBER=NOCLOBBER

;+
; NAME:
;	get_waves_gsfc_file
;
; PURPOSE:
; 	Download a Wind/Waves TNR, Rad1, or Rad2 data file YYYYMMDD.R2(.Z)
;	from the GSFC (NASA) ftp server.
;	(see http://ssed.gsfc.nasa.gov/waves/data_products.html)
;
; CATEGORY:
;	I/O
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL> get_waves_gsfc_file,date,receiver
;
; INPUTS:
;	date     - String providing the date for which 
;                  data file must downloaded.
;                  Input date format must be 
;                  'YYYYMMDD' or 'YYYY-MM-DD'.
;       receiver - Name of the Waves receiver.
;                  Must be 'tnr', 'rad1', or 'rad2'.
;	
; OPTIONAL INPUTS:
;	target_dir - Specify the path of the directory 
;                    where the data file is saved. 
;                    Default is current one.
;       tries      - Number of downloading tries.
;                    Default is 3.
;
; KEYWORD PARAMETERS:
;	/QUIET     - Quiet mode.
;       /VERBOSE   - Talkative mode.
;       /ASCII     - Download ascii data file instead of IDL format one.
;       /NOCLOBBER - If set, overwrite existing file in target_dir.
;
; OUTPUTS:
;	None.
;
; OPTIONAL OUTPUTS:
;	url      - Returns the url of the data file to download.
;       filepath - Returns the local path of the download data file.
;                  It contains an empty string if the downloading has failed.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS/COMMENTS:
;	The wget software must be installed
;       on the OS.
;	
; CALL:
;       Call the wget software.
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by:		X.Bonnin, 26-JUL-2011.
;
;-


sep = path_sep()
cd,current=Current_dir
ftp_server = 'ftp://stereowaves.gsfc.nasa.gov' 

url='' & filepath=''
if (n_params() lt 2) then begin
   message,/INFO,'Call is:'
   print,'get_waves_gsfc_file,date,receiver, $'
   print,'                    target_dir=target_dir, $'
   print,'                    tries=tries, $'
   print,'                    url=url, filepath=filepath, $'
   print,'                    /VERBOSE, /QUIET, /ASCII, /NOCLOBBER'
   return
endif
VERBOSE=keyword_set(VERBOSE)
QUIET=keyword_set(QUIET)
ASCII=keyword_set(ASCII)
NOCLOBBER=keyword_set(NOCLOBBER)
if not (keyword_set(target_dir)) then target_dir=Current_dir
if not (keyword_set(tries)) then tries=3

date = strtrim(date[0],2)
rec = strlowcase(strtrim(receiver[0],2))

filename=date
case rec of
   'tnr':begin
      filename=filename+'.tnr'
      directory='/wind_tnr/tnr'
   end
   'rad1':begin
      filename=filename+'.R1'
      directory='/wind_rad1/rad1'
   end   
   'rad2':begin
      filename=filename+'.R2'
      directory='/wind_rad2/rad2'
   end
   else:begin
      message,/CONT,'Input receiver must be tnr, rad1, or rad2!'
      return
   end
endcase

if (ASCII) then begin
   filename=filename+'.Z'
   directory=directory+'a'
endif

url = ftp_server+directory+'/'+filename

opts = ' -t '+strtrim(tries[0],2)
if (VERBOSE) then opts=opts+' -v'
if (QUIET) then opts=opts+' -q'
if (NOCLOBBER) then opts=opts+' -nc'
spawn,'wget '+ url+' -P '+target_dir+opts

filepath = target_dir+sep+filename
if not (file_test(filepath)) then filepath=''

END
