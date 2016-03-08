FUNCTION get_stereo_waves_data,date,spacecraft, $
                               datapath=datapath, $
                               url=url,filepath=filepath, $
                               DOWNLOAD_FILE=DOWNLOAD_FILE, $
                               REMOVE_FILE=REMOVE_FILE, $
                               VERBOSE=VERBOSE, $
                               VECTOR=VECTOR, $
                               found=found

;+
; NAME:
;	GET_STEREO_WAVES_DATA.PRO
;
; PURPOSE:
;	Loads the 60sec average STEREO/WAVES radio data (LFR, HFR)
;	produced by the GSFC (NASA).
;       Data files can be downloaded from the GSFC ftp server:
;            ftp://stereowaves.gsfc.nasa.gov
;
; INPUTS :
;       date       - String scalar containing date of data (YYYYMMDD).
;       spacecraft - Name of the STEREO probe name (must be 'A' or 'B')
;
; OPTIONAL INPUTS:
;       datapath - Local directory path of stereo/Waves data files.
;                  Default is current one.
;
; KEYWORD PARAMETERS:
;	/DOWNLOAD_FILE - Call wget program to download the data file from NASA ftp server 
;                        (Only if data file are not found in directory path given by DATAPATH). 
;                        (Internet connection is required.)
;       /REMOVE_FILE   - Delete data files from local disk 
;                        after downloading and loading them.
;       /VERBOSE       - Talkative mode.                        
;       /VECTOR        - Returns intensity, time, and frequency as a vectors.
;                        By default, intensity is returned as a 2d array [time,freq].
;
; OUTPUTS:
;        data - structure containing STEREO/WAVES radio data loaded.
;
; OPTIONAL OUTPUTS:
;        filepath - Full pathname of the radio data files read on the local disk.
;        url      - Returns the urls of the data files on the ftp server.
;        found    - Flag equals to :
;                        - 0b if no data has been loaded.
;                        - 1b if one data file has been read correclty.
;
; CALL:
;        wget Software 
;
; EXAMPLE:
;        ; Get stereo_a/waves data for the 1 January 2007:
;          data = get_stereo_waves_data('20070101','A',found=found,/DOWNLOAD_FILE)
;
; HISTORY:
;        Written by X.Bonnin (LESIA), 20-NOV-2006.
;
;-


on_error,2

;Initialize found
found = 0B

IF (n_params() LT 2) THEN BEGIN
    message,/info,'Call is :'
    print,'data = get_stereo_waves_data(date,spacecraft, $' 
    print,'                       	datapath=datapath, $'
    print,'                             url=url, filepath=filepath, $'
    print,'                             found=found, /VERBOSE, /VECTOR, $'
    print,'                             /DOWNLOAD_FILE, /REMOVE_FILE)'
    return, 0b
ENDIF

sc = strtrim(strlowcase(spacecraft),2)

;-> 'A' or 'B'
case sc of
   'a':sc = 'a'
   'b':sc = 'b'
   'sta':sc = 'a'
   'stereo_a': sc = 'a'
   'stb':sc = 'b'
   'stereo_b':sc = 'b'
   else:begin
      if (~keyword_set(silent)) then $
         print,'Spacecraft name must be "A" or "B".'
      error = 1
      return,0
   end
endcase
VERBOSE=keyword_set(VERBOSE)
DOWNLOAD=keyword_set(DOWNLOAD_FILE)
REMOVE=keyword_set(REMOVE_FILE)
VECTOR=keyword_set(VECTOR)

CD,current=curr_dir
;Specify the path where data are stored on the local disk
if not (keyword_set(datapath)) then datapath = curr_dir

exist = file_search(datapath,/TEST_DIRECTORY)
if (exist eq '') then message,'Current datapath not found : '+datapath

;FTP server name 
server = 'ftp://stereowaves.gsfc.nasa.gov' 

;file name(s)
date = strtrim(date(0),2)
filename = 'swaves_average_'+date+'_'+sc+'.sav'

;Universal Time in Hrs (Time res = 60sec)
ut = findgen(1440)/60.
nt = n_elements(ut)

;Number of frequency channel
n_lfr = 48 & n_hfr = 319
nf = n_lfr + n_hfr

; Receivers
rec = ['LFR'+strarr(n_lfr),'HFR'+strarr(n_hfr)]

;#### GET SWAVES DATA FILES ####

filepath = datapath + path_sep() + filename
url = server+'/stereo_data/summary/'+yyyy+'/'+filename
if not (file_test(filepath)) and (DOWNLOAD) then begin
   if (VERBOSE) then $
      print,'Get '+filename+' from '+server+' ...'  
   yyyy = strmid(date,0,4)
   spawn,'wget '+url
   if (datapath ne curr_dir) then spawn,'mv '+filename+' '+datapath
endif

filepath = (file_search(filepath))[0]
if (filepath eq '') then begin
   if (VERBOSE) then $
      print,'>> '+filepath+' not found <<' 
   return,0		
endif else begin
   if (VERBOSE) then print,'restore '+filepath
   restore,file
endelse

;freq
fkhz = frequencies
nf = n_elements(fkhz)

;flux
flux = transpose(spectrum)

;background
bg = back

;=== Time ===
t = ut
nt = n_elements(t)

;return data as vectors 
if (VECTOR) then begin
   nt = n_elements(t)
   
   r = reform(r,nt*nf)
   bg = reform(bg,nt*nf)
   
   date = strtrim(reform(rebin(long(date),nt,nf),nt*nf),2)
   t = reform(rebin(t,nt,nf),nt*nf)
   f = reform(transpose(rebin(f,nf,nt)),nt*nf)
        
   rec = strtrim(reform(transpose(rebin(long(rec),nf,nt)),nt*nf),2)
endif


;PUT DATA INTO A STRUCTURE
data = {date:date,ut:t,fkhz:fkhz,flux:flux,bkgd:bg,rec:rec}

found = 1B
return,data
end

