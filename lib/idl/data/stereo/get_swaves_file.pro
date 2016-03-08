PRO get_swaves_file, date, probe, receiver, filepath, $
                     level=level, target_dir=target_dir, $
                     username=username,password=password, $
                     url=url, VERBOSE=VERBOSE, $
                     GET_URL=GET_URL

;+
; NAME:
;       get_swaves_file
;
; PURPOSE:
;       This program downloads a STEREO/Waves data file providing the 
;       date of observation, the probe and receiver names, and the data level.
;      
; CALLING SEQUENCE:
;       get_swaves_file, date, probe, receiver, filepath, level=level
;
; INPUTS:
;       date     - Date of radio data file to read ('YYYYMMDD').
;       probe    - Name of the probe (can be 'A','Ahead' or 'B','Behind')
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
;       /GET_URL       - If set, returns the url of the file only
;                        (no downloading).
;       /VERBOSE       - Talkative mode. 
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
;        ; Get STEREO_A/Waves/LFR 60 seconds averaged data file for the 1 January 2001:
;          get_swaves_files,'20010101','A','rad2',filepath,level='l2_avg'
;
; HISTORY:
;        Written by X.Bonnin (LESIA), 10-MAY-2013.
;
;-

; CONSTANT ARGUMENTS

ftp_server = 'ftp://swaves.obspm.fr'
url = '' & filepath=''
ext = '.B3E'
; Checking input arguments
if (n_params() lt 3) then begin
    message,/info,'Call is :'
    print,'get_swaves_file,date,probe,receiver,filepath, $'
    print,'               level=level, target_dir=target_dir, $'
    print,'               url=url, /VERBOSE, /GET_URL'
    return
endif
VERBOSE=keyword_set(VERBOSE)
GET_URL=keyword_set(GET_URL)

if not (keyword_set(target_dir)) then cd,current=target_dir
if not (keyword_set(username)) then username='swavesftpuser'
if not (keyword_set(password)) then password='SwAvEs#ftp'
if not (keyword_set(level)) then level='l2_hres'

dat = strtrim(date[0],2)
prb = strupcase(strmid(strtrim(probe[0],2),0,1))
rec = strupcase(strtrim(receiver[0],2))
lev = strupcase(strtrim(level[0],2))

filename = 'ST'+prb+'_WAV_'+rec
case lev of
   'L2_HRES':begin
      filename = filename+'_'+dat+ext
      subdir = 'H_RES'
   end
   'L2_AVG':begin
      filename = filename+'_60s_'+date+ext
      subdir = 'AVERAGE'
   end
   else:message,'Unknown data level!'
endcase   

url = ftp_server + '/CDPP_data/STR_WAV/PRE/'+subdir+'/'+filename
if (GET_URL) then return

Popt = ' -P '+target_dir
if (VERBOSE) then Popt = Popt+' -v' else Popt=Popt+' -q'
spawn,'wget --user='+username+' --password='+password+' '+url+Popt

filepath = target_dir + path_sep() + filename
if not (file_test(filepath)) then begin
   if (VERBOSE) then message,/INFO,'Downloading has failed!'
   filepath = ''
endif

END
