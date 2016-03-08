pro openplot,file $
             ,xsize=xsize,ysize=ysize $
             ,xoffset=xoffset,yoffset=yoffset $
             ,landscape=landscape,colors=colors $
             ,encapsulated=encapsulated $ 
             ,bits=bits $ 
             ,verbose=verbose



if (n_params() lt 1) then begin
    message,/info,'Call is:'
    print,'openplot,file $'
    print,'        ,xsize=xsize,ysize=ysize $'
    print,'        ,xoffset=xoffset,yoffset=yoffset $'
    print,'        ,/landscape,/colors $'
    print,'        ,/encapsulated $' 
    print,'        ,bits=bits $ '
    print,'        ,/verbose'
    return
endif

if (keyword_set(encapsulated)) then begin
	landscape = 0
	extension = 'eps'
endif else extension = 'ps'


filebreak,file,dir=dir,name=name,ext=ext
if ext eq '' then begin
	 if (keyword_set(verbose)) then print,' Adding '+extension+' as the file extension.'
	 ext = extension
endif
if ext ne extension then begin
	 print,' Warning: non-standard extension: '+ext
	 print,' Standard extension is '+extension+'.'
	 ext = extension
endif

file = dir + name + '.' + ext

if (not keyword_set(bits)) then bits=8

set_plot,'ps',/copy,/interpolate
device,filename=file,encapsulated=encapsulated $
       ,color=colors,bits_per_pixel=bits $
       ,landscape=landscape 

IF (NOT keyword_set(encapsulated)) THEN BEGIN
    device,xsize=xsize,ysize=ysize $
    ,xoffset=xoffset,yoffset=yoffset
ENDIF

if (keyword_set(verbose)) then print,'['+file+'] saved'

end
