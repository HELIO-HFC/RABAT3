;+
; NAME:
;		get_win_wav_files
;
; PURPOSE:
; 		Giving a list of date of observations,
;       this routine returns the corresponding 
;       Wind/Waves data files found.
;
; CATEGORY:
;		I/O
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL> waves_files = get_win_wav_files(date_obs)
;
; INPUTS:
;		date_obs - Scalar or vector of string type providing the dates of 
;                  observation for which Wind/Waves data must be retrieved.
;                  Date format must be 'YYYYMMDD', where YYYY, MM, and DD
;                  correspond respectively to the year(s), month(s), and day(s).    
;	
; OPTIONAL INPUTS:
;		data_dir - Specify the directory path to the input data file.
;                  Default is current one.
;
; KEYWORD PARAMETERS:
;       /RAD1          - Get Waves/RAD1 data (default).
;       /RAD2          - Get Waves/RAD2 data.
;       /GSFC          - Get Wind/Waves files produced by NASA/GSFC (default). 
;       /SAV           - Get Wind/Waves files in IDL XDR format (instead of ascii files).
;		/COMPRESSED	   - Search for compressed files (i.e., with extenstion .Z)
;       /DOWNLOAD_DATA - If a data file is not found, then download it.
;		/SILENT	       - Quiet mode.
;
; OUTPUTS:
;		waves_files - Scalar or vector of string type containing the 
;                     list of the full path to the
;                     Wind/Waves data files found for the input dates.
;
; OPTIONAL OUTPUTS:
;       missing_files    - Scalar or vector of string type containing the
;                          list of missing data file(s).
;       downloaded_files - Scalar or vector of string type containing the 
;                          list of url(s) of the downloaded file(s).
;                          (ONLY WORKS WITH /DOWNLOAD_DATA KEYWORD.) 
;		error            - Returns 1 if an error occurs during reading, 0 else.
;				
;
; COMMON BLOCKS:
;		None.
;
; SIDE EFFECTS:
;		None.
;
; RESTRICTIONS/COMMENTS:
;       wget command must be accessible using SPAWN IDL routine.
;       For the moment only GSFC data are available.
;	
; CALL:
;		None.		
;
; EXAMPLE:
;		None.
;
; MODIFICATION HISTORY:
;		Written by:		X.Bonnin, 26-JUL-2011.
;
;-

FUNCTION get_win_wav_files,date_obs, $
                           data_dir=data_dir, $  
                           downloaded_files=downloaded_files, $
                           missing_files=missing_files, $
                           RAD1=RAD1, RAD2=RAD2, $
                           GSFC=GSFC, SAV=SAV, $
                           COMPRESSED=COMPRESSED, $
                           DOWNLOAD_DATA=DOWNLOAD_DATA, $
                           error=error,SILENT=SILENT

error = 1
if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'waves_files = get_win_wav_files(date_obs,$'
	print,'                                data_dir=data_dir, $'
    print,'                                downloaded_files=downloaded_files, $'
    print,'                                missing_files=missing_files, $'
	print,'                                /RAD1,/RAD2,/GSFC,/SAV,$'
    print,'                                /COMPRESSED,/DOWNLOAD_DATA, $'
    print,'                                error=error,/SILENT)'
	return,0
endif

RAD1=keyword_set(RAD1)
RAD2=keyword_set(RAD2)
GSFC=keyword_set(GSFC)
SAV=keyword_set(SAV)
DOWNLOAD = keyword_set(DOWNLOAD_DATA)
SILENT = keyword_set(SILENT)
COMPRESS = keyword_set(COMPRESSED)

if (SILENT) then quiet=' -q -nv ' else quiet=''

case (2*RAD1 - RAD2) of
    -1:begin
        id='2'
    end
    0:begin
        RAD1 = 1
        id = '1'
    end
    1:message,'You must choose between /RAD1 and /RAD2 options!'
    2:begin
        id='1'
    end
    else:
endcase
if (GSFC eq 0) then GSFC = 1

date = strtrim(date_obs,2)
if (~keyword_set(data_dir)) then cd,current=data_dir
ndate = n_elements(date)

case 1 of
    GSFC:begin
        server = 'ftp://stereowaves.gsfc.nasa.gov'
        server_dir = '/wind_rad'+id+'/rad'+id
        if (not SAV) then server_dir = server_dir + 'a' ;get ascii format files
        server_dir = server_dir + '/'
        fname = date + '.R'+ id
        if (COMPRESS) then fname = fname + '.Z'
    end
    else:message,'Unknown data provider!'
endcase

waves_files = strarr(ndate) & iwav = 0l
missing_files = strarr(ndate) & imis = 0l
downloaded_files = strarr(ndate) & iurl = 0l
for i=0l,ndate-1l do begin
    fname_i = strtrim(data_dir[0],2) + path_sep() + fname[i]
    if (not file_test(fname_i)) then begin
        if (not SILENT) then print,strtrim(ndate-i,2)+': '+fname_i+' not found.'
        if (DOWNLOAD) then begin
            url = server+server_dir+file_basename(fname_i)
            if (not SILENT) then begin
                print,'Download it from '+server+'...'
                print,'wget '+url+' -P '+data_dir+quiet
            endif
            spawn,'wget '+url+' -P '+data_dir+quiet
            if (file_test(fname_i)) then begin
                downloaded_files[iurl] = url
                iurl++
                waves_files[iwav] = fname_i
                iwav++
                continue
            endif
        endif 
        missing_files[imis] = fname_i
        imis++
    endif else begin
        if (not SILENT) then print,strtrim(ndate-i,2)+': '+fname_i+' found.'
        waves_files[iwav] = fname_i
        iwav++
    endelse
endfor
if (iwav gt 0l) then waves_files = waves_files[0:iwav-1l] else waves_files = ''
if (imis gt 0l) then missing_files = missing_files[0:imis-1l] else missing_files = ''
if (iurl gt 0l) then downloaded_files = downloaded_files[0:iurl-1l] else downloaded_files = ''

error = 0
return,waves_files
END