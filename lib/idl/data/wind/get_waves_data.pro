FUNCTION get_waves_data, date, receiver, level=level, $
                         data_dir=data_dir, $
                         username=username, $
                         password=password, $
                         header=header, $
                         filepath=filepath, $
                         found=found,url=url, $
                         DOWNLOAD_FILE=DOWNLOAD_FILE, $
                         DELETE_FILE=DELETE_FILE, $
                         VERBOSE=VERBOSE

;+
; NAME:
;       get_waves_data
;
; PURPOSE:
;       This function permits to read a Wind/Waves data file
;       produced by the LESIA (Observatoire de Paris), providing
;       the date of observation and the name of the Waves receiver.
;
;       (If the data file is not found on the disk, it can be 
;        downloaded from the LESIA ftp server using the /DOWNLOAD_FILE
;        keyword.)
;      
; CALLING SEQUENCE:
;       data = get_waves_data(date,receiver,level=level)
;
; INPUTS:
;       date     - Date of Wind/Waves data file to read 
;                  (format is 'YYYYMMDD').
;       receiver - Name of the Waves receiver : 'rad1', 'rad2', or
;                  'tnr'.    
;
; OPTIONAL INPUTS:
;       level      - Data level : 'l2_hres', 'l2_avg', 'l3_df', 'l3_gp',
;                    or 'l3_sfu'. Default is 'l2_hres'.
;       data_dir   - Path of the directory where the data file are
;                    stored. Default is the current one.
;       username   - Name of the LESIA ftp server account.
;       password   - FTP account password.
;
; KEYWORD PARAMETERS:
;	/DOWNLOAD_FILE - Call wget program to download the data file
;                        from the LESIA ftp server 
;                        (Only if data file are not found in the
;                        directory data_dir). 
;                        (Internet connection is required.)
;       /DELETE_FILE   - Delete data file from the local disk 
;                        once the data are loaded.
;       /VERBOSE       - Talkative mode. 
;
; OUTPUTS:
;        data - structure containing WIND/WAVES radio data.
;
; OPTIONAL OUTPUTS:
;        header   - Structure array containing the sweep headers.
;        filepath - Full pathname of the radio data file on the local disk.
;        url      - Returns the url of the data file on the ftp
;                   server. (Only if /DOWNLOAD_FILE is set.)
;
; CALL:
;        get_waves_file
;        calend_date__define
;        ccdsd_date__define
;        data_wind_waves_hres__define
;        header_wind_waves_hres__define
;        data_wind_waves_60s__define
;        header_wind_waves_60s__define
;        data_wind_waves_df__define
;        header_wind_waves_df__define
;        data_wind_waves_gp__define
;        header_wind_waves_gp__define
;
; EXAMPLE:
;        ; Load wind/waves rad2 data on 1 January 2001:
;          data = get_waves_data('20010101','rad2',filepath=filepath,found=found,/DOWNLOAD_FILE)
;
; HISTORY:
;        Written by X.Bonnin (LESIA), 10-MAY-2013.
;
;-

;on_error,2

found = 0B
url = '' & filepath=''
if (n_params() lt 2) then begin
    message,/info,'Call is :'
    print,'data =get_waves_data(date,receiver,level=level,$'
    print,'                      data_dir=data_dir, $'
    print,'                      username=username, $'
    print,'                      password=password, $'
    print,'                      header=header, $'
    print,'                      found=found, url=url, $'
    print,'                      filepath=filepath, $'
    print,'                      /DOWNLOAD_FILE,/DELETE_FILE, $'
    print,'                      /VERBOSE)'
    return,0b
endif
DOWNLOAD_FILE=keyword_set(DOWNLOAD_FILE)
DELETE=keyword_set(DELETE_FILE)
VERBOSE=keyword_set(VERBOSE)

;Specify the path where data are stored on the local disk
if not (keyword_set(data_dir)) then cd,current=data_dir
if not (keyword_set(username)) then username='waves'
if not (keyword_set(password)) then password='wavesuser'

dat = strtrim(date[0],2)
rec = strlowcase(strtrim(receiver[0],2))
if not (keyword_set(level)) then lev='l2_hres' else lev=strtrim(level[0],2)

get_waves_file,dat,rec,level=lev,url=url,/GET_URL
filename = file_basename(url)
filepath = data_dir + path_sep() + filename
if not (file_test(filepath)) and (DOWNLOAD_FILE) then begin
   if (VERBOSE) then print,'Downloading '+url
   get_waves_file,dat,rec,filepath, $
                  level=lev, $
                  username=username, $
                  password=password, $
                  target_dir=data_dir, $
                  VERBOSE=VERBOSE
endif
if not (file_test(filepath)) then begin
   if (VERBOSE) then message,/INFO, $
                             data_dir + path_sep() + filename + ' does not exist!'
   return, 0b
endif

case lev of 
   'l2_hres':data = read_wind_waves_hres(filepath,header)
   'l2_avg':data = read_wind_waves_60s(filepath,header)
   'l3_df':data = read_wind_waves_df(filepath,header)
   'l3_gp':data = read_wind_waves_gp(filepath,header)
   'l3_sfu':data = read_wind_waves_hres(filepath,header)
endcase

if (DELETE) then begin
   if (VERBOSE) then message,/INFO,'Deleting '+filepath
   spawn,'rm -f '+filepath
endif

return,data
end



