PRO fit_t3_driftrate,filename, $
                     A0=A0,$
					 data_dir=data_dir

if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'fit_t3_driftrate,filename, $'
    print,'                 A0=A0, $'
	print,'                 data_dir=data_dir'
	return
endif

file = strtrim(filename[0],2)

if (not file_test(file)) then message,'File not found!'
nline = file_lines(file)

if (not keyword_set(A0)) then A0 = [-0.005,2.]

data = strarr(nline,5)
openr,lun,file,/GET_LUN
i = 0l
while (~eof(lun)) do begin
    data_i = ''
    readf,lun,data_i
    data[i,*] = strsplit(data_i,';',/EXTRACT)
    i++
endwhile
close,lun
free_lun,lun
fields = strupcase(strtrim(reform(data(0,*)),2))
data = strtrim(data(1:*,*),2)
date_obs = reform(data(*,where(fields eq 'DATE_OBS')))
observat = strupcase(reform(data(*,where(fields eq 'OBSERVAT'))))
instrume = strupcase(reform(data(*,where(fields eq 'INSTRUME'))))
telescop = strupcase(reform(data(*,where(fields eq 'TELESCOP'))))
freq_max = float(reform(data(*,where(fields eq 'FREQ_MAX'))))

nfeat = n_elements(date_obs)
date = strmid(date_obs,0,10)
time = strmid(date_obs,11)
dateList = date[uniq(date,sort(date))]
ndates = n_elements(dateList)

id = observat[0]+'-'+telescop[0]+'-'+instrume[0]
case id of
    'WIND-WAVES-RAD1':begin
        for i=0l,ndates-1l do dateList[i] = strjoin(strsplit(dateList[i],'-',/EXTRACT))
        files = get_win_wav_files(dateList,data_dir=data_dir,/RAD1,/COMPRESS,/GSFC,/DOWNLOAD_DATA,/SILENT)
        data = read_gsfc_rad1(files[0],header=header)
        data = replicate(data,ndates)
        header = replicate(header,ndates)
        nread = 1l
        while(nread lt ndates) do begin
            printl,strtrim(ndates - nread,2)+' structures to load...'
            data_i = read_gsfc_rad1(files[nread],header=header_i)
            data[nread] = data_i
            header[nread] = header_i
            nread++
        endwhile        
    end
    'WIND-WAVES-RAD2':begin
        for i=0l,ndates-1l do dateList[i] = strjoin(strsplit(dateList[i],'-',/EXTRACT))
        files = get_win_wav_files(dateList,data_dir=data_dir,/RAD2,/COMPRESS,/GSFC,/DOWNLOAD_DATA,/SILENT)
        data = read_gsfc_rad2(files[0],header=header)
        data = replicate(data,ndates)
        header = replicate(header,ndates)
        nread = 1l
        while(nread lt ndates) do begin
            printl,strtrim(ndates - nread,2)+' structures to load...'
            data_i = read_gsfc_rad2(files[nread],header=header_i)
            data[nread] = data_i
            header[nread] = header_i
            nread++
        endwhile          
    end
    else:message,'Unknown intrument!'
endcase

for i=0l,ndates-1l do begin
           


endfor

END