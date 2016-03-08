;+
;GET_ULYSSES_URAP_DATA.PRO
;
;
;This function loads 144sec average ULYSSES/URAP/RAR radio data 
;from NASA ftp server : "ftp://stereowaves.gsfc.nasa.gov".
;(See http://urap.gsfc.nasa.gov/rav_data_files.html for more details about data.)
;
;INPUT :
;       DATE - Date of radio data (YYYYMMDD)      
;
;
;OPTIONAL KEYWORDS :
;
;
;		DATAPATH - Local directory path of Ulysses/urap data.
;                  (Default : current directory)
;
;		FTP - Permit to retreive data from NASA ftp server if data files
;			  are not found in directory path given by DATAPATH. 
;             (Internet connection is required.)
;
;		NOSAVE - Remove data files from local disk 
;                after downloading and loading them. 
;	
;
;		FOUND - Equal to 1 if data file is found (0 else.)
;
;
;OUTPUT :
;        DATA - structure containing ULYSSES/URAP radio data
;
;-


function get_ulysses_urap_data,date $
  							,datapath=datapath $
  							,nosave=nosave $
  							,found=found $
  							,ftp=ftp

;on_error,2

found = 0B

if (n_params() lt 1) then begin
    message,/info,'Call is :'
    print,'data = get_ulysses_urap_data(date,datapath=datapath $'
    print,'                             ,found=found,/FTP,/NOSAVE)'
    return,0
endif

;Specify the path where data are stored on the local disk
if (~keyword_set(datapath)) then CD,current=datapath

if (keyword_set(FTP)) then ftp = 1B else ftp = 0B

date = strtrim(date(0),2)

ftpname = 'ftp://stereowaves.gsfc.nasa.gov' 


;Frequency channel list
nlow = 64
flow = 1.25 + 0.75*findgen(nlow)
nhigh = 12
fhigh = [52.0000, 63.0000, 81.0000, 100.000, 120.000, 148.000, 196.000, 272.000, 387.000, 540.000, 740.000, 940.000]
fkhz = [flow,fhigh]
nf = n_elements(fkhz)

;Receiver list
rec = ['Low' + strarr(nlow),'High' + strarr(nhigh)]


filename = 'u'+strmid(date,2,6)+'.rav'
file = datapath + path_sep() + filename

if (~file_test(file)) and (ftp) then begin
   spawn,'wget '+ftpname+'/urap_data/rav/'+filename
   spawn,'mv '+filename+' '+datapath
endif
file = (file_search(file))(0)
if (file eq '') then begin
   print,'>> File has not been found <<'
   return,0
endif

dt = 144. ;sec
nt = long(86400./dt)
s = fltarr(nt,nf)
UT = fltarr(nt)
flux = fltarr(nf)
d = '' & t = ''
openr,lun,file,/GET_LUN
for i=0,nt-1 do begin
   readf,lun,d,t,format='(i8.8,1x,i6.6)'
   readf,lun,flux
   t = string(t,format='(i6.6)')
   UT(i) = float(strmid(t,0,2)) + float(strmid(t,2,2))/60. + float(strmid(t,4,2))/3600.
   s(i,*) = flux
endfor
close,lun

if (keyword_set(NOSAVE)) then spawn,'rm '+file

if (total(s) eq 0.) then return,0

bg = fltarr(nf)
for j=0,nf-1 do begin
   w99 = where(s(*,j) ne -99.000)
   if (w99(0) ne -1) then begin
      bg_j = get_quantile(s(w99,j),0.05)
      bg(j) = bg_j
      if (bg(j) ne 0.) then s(w99,j) = s(w99,j)/bg(j)
   endif
endfor

data = {date:date,UT:UT,fkhz:fkhz,flux:s,bkgd:bg,rec:rec}
found = 1B

return,data
end


