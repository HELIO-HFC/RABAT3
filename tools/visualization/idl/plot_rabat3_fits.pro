PRO plot_rabat3_fits,filename,index=index,$
					 input_dir=input_dir,$
					 output_dir=output_dir,$
					 color_table=color_table,$
					 OVERPLOT_CONTOUR=OVERPLOT_CONTOUR,$
					 OVERPLOT_INDEX=OVERPLOT_INDEX,$
					 YLOG=YLOG,WRITE_PNG=WRITE_PNG,$
					 _EXTRA=_extra


if (n_params() lt 1) then begin
	message,/INFO,'Call is:'
	print,'plot_rabat3_fits,filename,index=index,$'
	print,'                 input_dir=input_dir,$'
	print,'                 output_dir=output_dir,$'
	print,'                 color_table=color_table,$'
	print,'                 /OVERPLOT_CONTOUR,$'
	print,'                 /OVERPLOT_INDEX,$'
	print,'                 /YLOG,/WRITE_PNG'
	return
endif

OCONTOUR  = keyword_set(OVERPLOT_CONTOUR)
OINDEX = keyword_set(OVERPLOT_INDEX)
WRITE_PNG = keyword_set(WRITE_PNG)
YLOG = keyword_set(YLOG)

if not (keyword_set(color_table)) then color_table = 39

file = strtrim(filename[0],2)
if (keyword_set(input_dir)) then file = strtrim(input_dir[0],2)+path_sep()+file_basename(file)
if (~file_test(file)) then message,/INFO,'Input fits file not found'

if (~keyword_set(output_dir)) then cd,current=output_dir

array = readfits(file,hdr,/SILENT)
nhdr = n_elements(hdr)
header = {simple:'',bitpix:0,naxis:0,naxis1:0L,naxis2:0L,naxis3:0L,$
		  extend:'',version:'',observat:'',telescop:'',instrume:'',$
		  institut:'',filename:'',date_obs:'',date_end:'',cdelt1:0.0d,$
		  cdelt2:0.0d,crpix1:0L,crpix2:0L,crval1:0.0d,crval2:0.0d}
for i=0,nhdr-1 do begin
	hdr_i = strtrim(strsplit(hdr[i],'=/',/EXTRACT),2)
	if (hdr_i[0] eq 'END') then break
	if (n_elements(hdr_i) lt 2) then hdr_i = [hdr_i[0],' ']
	tags_i = hdr_i[0]
	val_i = hdr_i[1]
	jflag = execute('header.'+tags_i+'=+val_i')
endfor

time = header.cdelt1*(lindgen(header.naxis1) - header.crpix1) + header.crval1
freq = header.cdelt2*(lindgen(header.naxis2) - header.crpix2) + header.crval2
time = time>(0.0d)<(24.0d)
int = reform(array[*,*,0])
ctr = fix(reform(array[*,*,1]))

date = (strsplit(header.date_obs,'T',/EXTRACT))[0]
if (~keyword_set(title)) then $
	title = header.observat+'-'+header.telescop+'-'+header.instrume+': '+date 
display2d,int,time,freq,$
		  xrange=xrange,yrange=yrange,$
		  xtitle='UTC (hours)',ytitle='Frequency (MHz)',$
		  title=title,_EXTRA=_extra,$
		  color=0,$
		  YLOG=YLOG,/REVERSE

level = ctr[uniq(ctr,sort(ctr))]
level = long(level[1:*]) 
loadct,color_table,/SILENT
color = bytscl(level,top=234) + 20b
if (OCONTOUR) then begin
	for i=0L,n_elements(level)-1L do begin
		if (keyword_set(index)) then begin
			if ((where(level[i] eq long(index)))[0] eq -1) then continue 	
		endif
		contour,ctr eq level[i],time,freq,$
			 	level=1,$
			 	c_color=color[i],/OVER
	endfor
endif


if (OINDEX) then begin
	for i=0L,n_elements(level)-1L do begin
		if (keyword_set(index)) then begin
			if ((where(level[i] eq long(index)))[0] eq -1) then continue 	
		endif
	
		ipix = where(level[i] eq ctr)
		ipix = array_indices(ctr,ipix)
		Ypix = round(mean(ipix[1,*]))
		Xpix = round(min(ipix[0,*]))
		xyouts,time[Xpix],freq[Ypix],strtrim(level[i],2),/DATA,color=color[i],charsize=0.8
	endfor
endif

if (WRITE_PNG) then begin
	pngfile = strtrim(output_dir[0],2)+path_sep()+file_basename(file,'fits')+'png' 
	WRITE_PNG,pngfile ,$
			   TVRD(/TRUE)
	print,pngfile+' has been written.'
endif

END