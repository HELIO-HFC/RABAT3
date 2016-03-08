pro draw_widget,xsize=xsize,ysize=ysize $
                ,xoffset=xoffset,yoffset=yoffset $
                ,title=title $
                ,base=base,menubase=menubase $
                ,column=column,row=row $
                ,window_set=window_set $
                ,help=help

IF keyword_set(help) THEN BEGIN
    message,/info,'Call is :'
    print,'draw_widget,xsize=xsize,ysize=ysize $'
    print,'           ,xoffset=xoffset,yoffset=yoffset $'
    print,'           ,title=title $'
    print,'           ,base=base,menubase=menubase $'
    print,'           ,column=column,row=row $'
    print,'           ,window_set=window_set $'
    return
ENDIF

if not keyword_set(xsize) then xsize = 960
if not keyword_set(ysize) then ysize = 589
if not keyword_set(xoffset) then xoffset = -10
if not keyword_set(yoffset) then yoffset = -10
if not keyword_set(title) then title = ''

base=widget_base(title=title,column=column,row=row,tlb_size_events=1 $
                 ,mbar=menubase $
                 ,xoffset=xoffset,yoffset=yoffset)
drawid=widget_draw(base,xsize=xsize,ysize=ysize)
widget_control,base,/realize

IF not (keyword_set(window_set)) THEN $
  widget_control,drawid,get_value=window_set
wset,window_set

end
