PRO get_waves_file, date, receiver, filepath, $
                    level=level, target_dir=target_dir, $
                    username=username,password=password, $
                    url=url, VERBOSE=VERBOSE, $
                    GET_URL=GET_URL, NOCLOBBER=NOCLOBBER

;+
; NAME:
;       get_waves_file
;
; PURPOSE:
;       This program downloads a Wind/Waves data file providing the 
;       date of observation, the receiver name, and the data level.
;      
; CALLING SEQUENCE:
;       get_waves_file, date, receiver, filepath, level=level
;
; INPUTS:
;       date     - Date of radio data file to read ('YYYYMMDD').
;       receiver - Name of the Waves receiver: 'rad1', 'rad2', or
;                  'tnr'.
;
; OPTIONAL INPUTS:
;       level      - Data level : 'l2_hres', 'l2_avg', 'l3_df', 'l3_gp',
;                    or 'l3_sfu'. Default is 'l2_hres'.
;       target_dir - Path of the directory where the data file will be
;                    saved. Default is the current one.
;       username   - Name of the LESIA ftp server account.
;       password   - FTP account password.
;
; KEYWORD PARAMETERS:
;       /NOCLOBBER    - IF set, do not start downloading if the file
;                       is already in data_directory.
;       /GET_URL      - If set, returns the url of the file only
;                       (no downloading).
;       /VERBOSE      - Talkative mode. 
;
; OUTPUTS:
;        filepath - String containing the path to the downloaded file.
;                   (Empty string if the downloading has failed.)
;
; OPTIONAL OUTPUTS:
;        url - URL of the distant data file.
;
; CALL:
;        wget Software required.
;
; EXAMPLE:
;        ; Get wind/waves/rad2 60 seconds averaged data file for the 1 January 2001:
;          get_waves_files,'20010101','rad2',filepath,level='l2_avg'
;
; HISTORY:
;        Written by X.Bonnin (LESIA), 10-MAY-2013.
;
;-

; CONSTANT ARGUMENTS

ftp_server = 'ftp://sorbet.obspm.fr'
url = '' & filepath=''
ext = '.B3E'
; Checking input arguments
if (n_params() lt 2) then begin
    message,/info,'Call is :'
    print,'get_waves_file,date,receiver,filepath, $'
    print,'               level=level, target_dir=target_dir, $'
    print,'               url=url, /VERBOSE, /GET_URL, /NOCLOBBER'
    return
endif
VERBOSE=keyword_set(VERBOSE)
GET_URL=keyword_set(GET_URL)
NOCLOBBER=keyword_set(NOCLOBBER)

dat = strtrim(date[0],2)
rec = strlowcase(strtrim(receiver[0],2))
lev = strlowcase(strtrim(level[0],2))
if not (keyword_set(target_dir)) then cd,current=target_dir
if not (keyword_set(username)) then username='waves'
if not (keyword_set(password)) then password='wavesuser'

filename = 'WIN_'+strupcase(rec)
case lev of
   'l2_hres':begin
      filename = filename+'_'+dat+ext
      subdir = '/l2/h_res'
   end
   'l2_avg':begin
      filename = filename+'_60S_'+date+ext
      if (rec eq 'tnr') then subdir = '/l2_60s' $
      else subdir = '/l2/average'
   end
   'l3_df':begin
      filename = filename+'_DF_'+date+ext
      subdir = '/l3/df'
   end
   'l3_gp':begin
      filename = filename+'_GP_'+date+ext
      subdir = '/l3/gp'
   end
   'l3_sfu':begin
      filename = filename+'_SFU_'+date+ext
      subdir = '/l3/sfu'
   end
   else:message,'Unknown data level!'
endcase   

url = ftp_server + '/WIND_Data/CDPP/'+rec+subdir+'/'+filename
if (GET_URL) then return

Popt = ' -P '+target_dir
if (VERBOSE) then Popt = Popt+' -v' else Popt=Popt+' -q'
if (NOCLOBBER) then Popt = Popt + ' -nc'

spawn,'wget --user='+username+' --password='+password+' '+url+Popt

filepath = target_dir + path_sep() + filename
if not (file_test(filepath)) then begin
   if (VERBOSE) then message,/INFO,'Downloading has failed!'
   filepath = ''
endif

END
