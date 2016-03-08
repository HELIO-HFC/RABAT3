FUNCTION get_wind_waves_data,date, $
                             datapath=datapath, $
                             filepath=filepath, $
                             found=found,url=url, $
                             DOWNLOAD_FILE=DOWNLOAD_FILE, $
                             REMOVE_FILE=REMOVE_FILE, $
                             VERBOSE=VERBOSE

;+
; NAME:
;       GET_WIND_WAVES_DATA.PRO
;
; PURPOSE:
;       This function reads 60sec average Wind/WAVES radio data files (tnr, rad1, and rad2)
;       produced by GSFC (NASA). 
;       (See http://lep694.gsfc.nasa.gov/waves/waves.html for more details about data.)
;       Files can be downloaded from GSFC ftp server ftp "ftp://stereowaves.gsfc.nasa.gov".
;      
; CALLING SEQUENCE:
;       data = get_wind_waves_data(date)
;
; INPUTS:
;       date - Date of radio data file to read (YYYYMMDD)      
;
; OPTIONAL INPUTS:
;       datapath - Path of the data file.
;                  Default is current one.
;
; KEYWORD PARAMETERS:
;	/DOWNLOAD_FILE - Call wget program to download the data file from NASA ftp server 
;                        (Only if data file are not found in directory path given by DATAPATH). 
;                        (Internet connection is required.)
;       /REMOVE_FILE   - Delete data files from local disk 
;                        after downloading and loading them.
;       /VERBOSE       - Talkative mode. 
; OUTPUTS:
;        data - structure containing WIND/WAVES radio data loaded.
;
; OPTIONAL OUTPUTS:
;        filepath - Full pathname of the radio data files read on the local disk.
;        url      - Returns the urls of the data files on the ftp server.
;        found    - Flag equals to :
;                        - 0b if no data has been loaded.
;                        - 1b if one data file has been read correclty.
;                        - 2b if two data files have been read correctly.
;                        - 3b if three data files have been read correctly. 
;
; CALL:
;        wget Software 
;
; EXAMPLE:
;        ; Get wind/waves data for the 1 January 2001:
;          data = get_wind_waves_data('20010101',found=found,/DOWNLOAD_FILE)
;
; HISTORY:
;        written by X.Bonnin (LESIA), 10-OCT-2006.
;
;-

;on_error,2

found = 0B
ftp_server = 'ftp://stereowaves.gsfc.nasa.gov' 
url = '' & filepath=''
if (n_params() lt 1) then begin
    message,/info,'Call is :'
    print,'data = get_wind_waves_data(date,datapath=datapath, $'
    print,'                           found=found, url=url, $'
    print,'                           filepath=filepath, $'
    print,'                           /DOWNLOAD_FILE,/REMOVE_FILE, $'
    print,'                           /VERBOSE)'
    return,0b
endif
DOWNLOAD=keyword_set(DOWNLOAD_FILE)
REMOVE=keyword_set(REMOVE_FILE)
VERBOSE=keyword_set(VERBOSE)

;Specify the path where data are stored on the local disk
if not (keyword_set(datapath)) then CD,current=datapath

date = strtrim(date(0),2)

;Universal Time in Hrs (integration time = 60sec)
UT = findgen(1440)/60.
nt = n_elements(UT)

;RAD1
;Freq
fr1=findgen(256)*4.+20.
nf1 = n_elements(fr1)

;RAD2
;Freq
fr2=(findgen(256)*0.05+1.075)*1.e3
nf2 = n_elements(fr2)

;TNR
;Freq
frtnr=10.^(findgen(96)*0.0188144+alog10(4.))
nftnr = n_elements(frtnr)


;Freq list
fkhz = [frtnr,fr1,fr2]
nf = n_elements(fkhz)

;Receiver list
rec = ['TNR' + strarr(nftnr),'RAD1' + strarr(nf1),'RAD2' + strarr(nf2)]

;Flux
s = fltarr(nt,nf)

;GET WAVES DATA FILES FOR EACH RECEIVER
;RAD1
filename1 = datapath+path_sep()+date+'.R1'
rad1_url = ftp_server+'/wind_rad1/rad1/'+date+'.R1'
url=[url,rad1_url]
if not (file_test(filename1)) and (DOWNLOAD) then begin
   spawn,'wget '+rad1_url+' -P '+datapath+' -t 3'
endif
filename1 = (file_search(filename1))(0)
if (filename1 eq '') then arrayb = fltarr(1441,256) $
else begin
   filepath=[filepath,filename1]
   if (VERBOSE) then print,'restore '+filename1
   restore,filename1
   found++
endelse

;Flux
s1 = arrayb(0:1439,*)
;Background
bg1 = arrayb(1440,*)


;RAD2
filename2 = datapath+path_sep()+date+'.R2'
rad2_url = ftp_server+'/wind_rad2/rad2/'+date+'.R2'
url=[url,rad2_url]
if not (file_test(filename2)) and (DOWNLOAD) then begin
   spawn,'wget '+ rad2_url+' -P '+datapath+' -t 3'
endif 
filename2 = (file_search(filename2))(0)  
if (filename2 eq '') then arrayb = fltarr(1441,256) $	
else begin
   filepath=[filepath,filename2]
   if (VERBOSE) then print,'restore '+filename2
   restore,filename2
   found++
endelse

;Flux
s2 = arrayb(0:1439,*)
;Background
bg2 = arrayb(1440,*)


;TNR
filename3 = datapath+path_sep()+date+'.tnr'
tnr_url=ftp_server+'/wind_tnr/tnr/'+date+'.tnr'
url = [url,tnr_url]
if (~file_test(filename3)) and (DOWNLOAD) then begin 
   if (VERBOSE) then print,'wget '+tnr_url
   spawn,'wget '+tnr_url+' -P '+datapath+' -t 3'
endif
filename3 = (file_search(filename3))(0)
if (filename3 eq '') then arrayb = fltarr(1441,96) $	
else begin
   filepath=[filepath,filename3]
   if (VERBOSE) then print,'restore '+filename3
   restore,filename3
   found++
endelse

;Flux
s3 = arrayb(0:1439,*)
;Background
bg3 = arrayb(1440,*)


;==== FLUX ==== 
s(*,0:nftnr-1) = s3
s(*,nftnr:nftnr+nf1-1) = s1
s(*,nftnr+nf1:nf-1) = s2

;Background
bg = fltarr(nf)
bg(0:nftnr-1) = bg3
bg(nftnr:nftnr+nf1-1) = bg1
bg(nftnr+nf1:nf-1) = bg2

if (found gt 0b) then begin
   filepath=filepath[1:*]
   if (REMOVE) then begin
      for i=0,found-1 do begin
         cmd = 'rm '+filepath[i]
         if (VERBOSE) then print,cmd 
         spawn,cmd
      endfor
   endif
endif

if (total(arrayb) eq 0.) then begin
   if (VERBOSE) then message,/CONT,'Empty data set!'
   return,0
endif
data = {date:date,UT:UT,fkhz:fkhz,flux:s,bkgd:bg,rec:rec}

return,data
end



