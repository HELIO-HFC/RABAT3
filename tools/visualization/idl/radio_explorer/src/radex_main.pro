PRO radex_main,date,observatory, $
               min_val=min_val,max_val=max_val, $
               frange=frange,trange=trange, $
               color_table=color_table, $
               data_dir=data_dir, $
               output_dir=output_dir, $
               YLOG=YLOG, $ 
               HELP=HELP, $
               SILENT=SILENT

;+
; NAME:
;       radex_main
;
; PURPOSE:
;
;       This program allows to visualize dynamical spectrum
;       from various radio datasets.
;       It also allows event selections. 
;            
; CATEGORY:
;      Visualization program
;
; GROUP:
;     radex
;
; CALLING SEQUENCE:
;       radio_explorer,date,observatory
;
; INPUTS:
;       date        - Date of observation (scalar string format 'YYYYMMDD')
;       observatory - Name of the observatory in the following list : 
;                         ulysse (urap data), wind (waves data),
;                         stereo a (HFR data), stereo b (HFR data),
;                         nancay (nda data).
;
; OPTIONAL INPUTS:
;       min_val     - min intensity on dyn. spec. in dB above
;                     background. Default is 0 dB.
;       max_val     - max intensity on dyn. spec. in dB above
;                     background. Defaults is 10 dB.
;       trange      - specify the time range (between 0. and 24.)
;       frange      - specify the frequency range
;       output_dir  - specify directory where output data file(s) will be saved
;       data_dir    - specify directory where data files are stored.
;       color_table - specify the IDL color_table to load.
;                     Default is 0 (B&W).
;
; KEYWORD PARAMETERS:
;       /YLOG   - Display log(frequency) in Y-axis
;       /SILENT - Warning messages are not display if SILENT is set. 
;       /HELP   - Display help
;
;
; COMMON BLOCKS:
;       param, option, widget, path
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS/COMMENTS:
;	None.
;
; CALL:
;       radex_display
;       radex_select
;       radex_actions
;       radex_events
;       radex_bounds
;       display2d
;       hh2hhmmss
;       countday
;       draw_widget
;       get_quantile
;       get_wind_waves_data
;       get_stereo_waves_data
;       get_ulysses_urap_data
;
; MODIFICATION HISTORY:
;       Written by X. Bonnin (LESIA),  10-NOV-2005.
;
; Version 1.0
;       10-NOV-2005, X.Bonnin:    First release.
; Version 1.1 
;       10-NOV-2006, X.Bonnin:    Added STEREO data. 
; Version 1.2
;       28-JUL-2009, X.Bonnin:    Added Ulysses data.
; Version 1.3
;       28-FEB-2013, X.Bonnin:    Added Nancay data.
;
Version = 1.3
;###########################################################################
;
; LICENSE
;
;  Copyright (c) 2005-2013, Xavier Bonnin, CNRS - Observatoire de Paris
;  All rights reserved.
;  Non-profit redistribution and non-profit use in source and binary forms, 
;  with or without modification, are permitted provided that the following 
;  conditions are met:
; 
;        Redistributions of source code must retain the above copyright
;        notice, this list of conditions, the following disclaimer, and
;        all the modifications history.
;        Redistributions in binary form must reproduce the above copyright
;        notice, this list of conditions, the following disclaimer and all the
;        modifications history in the documentation and/or other materials 
;        provided with the distribution.
;        Neither the name of the CNRS and Observatoire de Paris nor the
;        names of its contributors may be used to endorse or promote products
;        derived from this software without specific prior written permission.
; 
; THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
; EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;-

quote=string(39b)
args = strtrim(command_line_args(),2)
nargs = n_elements(args)
if (args[0] ne '') then begin
   date = args[0]
   observatory = args[1]
   inputpar = ['min_val','max_val', $
               'color_table','output_dir', $
               'data_dir','feat_min_pix']
   inputkey = ['/ylog','/help', $
               '/silent']
   for i=0l,n_elements(args)-1 do begin
      where_key = (where(strlowcase(args[i]) eq inputkey))[0]
      if (where_key ne -1) then begin
         flag = execute(strmid(inputkey[where_key],1)+'=1')
         continue
      endif
      value = strsplit(args[i],'=',/EXTRACT)
      if (n_elements(value) eq 2) then begin
         where_par = (where(strlowcase(value[0]) eq inputpar))[0]
         if (where_par ne -1) then begin
            flag = execute(value[0]+'='+quote+value[1]+quote)
         endif
      endif
   endfor
endif

print,systime()
;**** TEST INPUT PARAMETERS ****
date_flag = keyword_set(date)
observatory_flag = keyword_set(observatory)
if (keyword_set(HELP)) then begin
   print,'PURPOSE:==================================='
   print,'This program permits to display radio dataset'
   print,'and select event(s) with the mouse cursor. '
   print,''
   wait,.5
   print,'CALLING SEQUENCE:=========================='
   print,'radex_main,date,observatory'
   print,''
   wait,.5
   print,'REQUIRED INPUTS:==========================='
   print,'DATE        - Vector containing date of data'
   print,'OBSERVATORY - Name of the observatory'
   print,'        	(available = ["ulysses","wind"'
   print,'              ,"stereo_a","stereo_b","nancay"])' 
   print,''
   wait,.5
   print,'EXAMPLE:==================================='
   print,'radex_main,"20070101", $'
   print,'           ["wind","stereo_a"]'
   print,'======================================= X.B'
   print,''
   return
endif
if not (date_flag) or not (observatory_flag) then begin
   message,/INFO,'Call is:'
   print,'radex_main,date,observatory, $'
   print,'           max_val=max_val,min_val=min_val, $'
   print,'           frange=frange,trange=trange, $'
   print,'           output_dir=output_dir, $'
   print,'           data_dir=data_dir, $'
   print,'           color_table=color_table, $'
   print,'           /YLOG,/SILENT,/HELP'
   return
endif
SILENT=keyword_set(SILENT)
YLOG=keyword_set(YLOG)
;************************



;**** COMMON PARAMETERS ****
COMMON param, day, obs, obs_id, data, nevents
COMMON path, ULYSSES_DATAPATH, WIND_DATAPATH, STEREOA_DATAPATH, STEREOB_DATAPATH, NANCAY_DATAPATH, SAVEPATH
COMMON option, tr, fr, minv, maxv, yl, slnt, ct, wid
COMMON widget, prevday_button, day_txt, nextday_button, $
   prevobs_button, obs_txt, nextobs_button, $
   fmin_txt, fmax_txt, log_button, $
   slide_button, quit_button, help_button
;************************

;**** LIST OF AVAILABLE SPACECRAFT DATA ****
obs_list = ['ULYSSES','WIND','STEREO_A','STEREO_B','NANCAY']

if not (keyword_set(observatory)) then begin
   message,/CONT,'>> You must choose at least one observatory from the following list <<'
   message,/CONT,obs_list
   return
endif
;************************

;**** INITIALIZING ARGUMENTS ****
date=string(date(0),format='(i8.8)')
observatory = strupcase(strtrim(observatory,2))
data = 0b
obs_id = 0
win_id = 1L & sta_id = 1L & stb_id = 1L & uly_id = 1L & nan_id = 1L
nevents = 0L
;************************

;**** COLOR TABLE ****
;By default ct = 0 (B&W)
if (n_elements(color_table) eq 0) then begin
   color_table = 0
   loadct,color_table,SILENT=SILENT
endif 
;************************

;**** TIME RANGE ****
if not (keyword_set(trange)) then trange = [0.,24.] $
else trange = float(trange)<24.>0.
trange = hh2hhmmss(trange)
;************************


;**** PLOT OPTION ****
CASE !VERSION.OS_FAMILY OF 
   'unix'      : set_plot,'X' 
   'Windows'   : set_plot,'WIN' 
   else : set_plot,'X' 
ENDCASE 
device,decomposed=0	

;**** INITIALIZE DATAPATH, CREATE LOGFILE ****
day = date & obs = observatory
slnt = SILENT & ct = color_table
if not (keyword_set(frange)) then frange = [0.,100000.]
if (keyword_set(min_val)) then minv = min_val else minv = 0.0001
if (keyword_set(max_val)) then maxv = max_val else maxv = 10.
if (keyword_set(output_dir)) then SAVEPATH = output_dir
if (keyword_set(data_dir)) then begin
   WIND_DATAPATH=data_dir
   ULYSSES_DATAPATH=data_dir
   STEREOA_DATAPATH=data_dir
   STEREOB_DATAPATH=data_dir
   NANCAY_DATAPATH=data_dir
endif else begin
   WIND_DATAPATH=''
   ULYSSES_DATAPATH=''
   STEREOA_DATAPATH=''
   STEREOB_DATAPATH=''
   NANCAY_DATAPATH=''
endelse
yl = YLOG 
tr = trange
fmin = string(frange[0],format='(f9.2)') 
fmax = string(frange[1],format='(f9.2)')
fr = [fmin,fmax]
radex_actions,'start'

;**** CREATE WIDGET TO DISPLAY DYN. SPECT. **** 
device, get_screen_size=screensize
xsize=screensize(0)*.85
ysize=screensize(1)*.6
draw_widget,xsize=xsize,ysize=ysize, $
	 window_set=window_set, $
	 title='Radio Explorer', $
	 base = mainbase, $
         menubase = menubase, $
	 row = 2
wid = window_set


;**** CREATE OPTION WIDGET ****
file_menu   = WIDGET_BUTTON(menubase, value='File', /MENU)
quit_button = WIDGET_BUTTON(file_menu, value='Quit',$
                            uvalue='uquit')
help_menu   = WIDGET_BUTTON(menubase, value='Help', /MENU)
help_button = WIDGET_BUTTON(help_menu, value='Display help',$
                            uvalue='uhelp')

;**** CREATE OPTION WIDGET **** 
base           = WIDGET_BASE(mainbase,title='Selection menu', $
                             /ALIGN_CENTER,/BASE_ALIGN_CENTER, $
                             ysize=80, /ROW)
date_lbl       = WIDGET_LABEL(base,value='  DATE :  ', $
                              xsize=75,ysize=30)
prevday_button = WIDGET_BUTTON(base, value='Previous', uvalue='prevday' $
                               ,/ALIGN_CENTER,xsize=100) 
day_txt        = WIDGET_TEXT(base,value=date,uvalue='udate' $
                             ,xsize=10,/EDITABLE,/ALIGN_CENTER)
nextday_button = WIDGET_BUTTON(base, value='Next', uvalue='nextday' $
                               ,/ALIGN_CENTER ,xsize=100) 
gap_lbl        = WIDGET_LABEL(base,value='  ' $
                              ,xsize=30)
obs_lbl         = WIDGET_LABEL(base,value='  OBSERVATORY :  ', $
                               xsize=100,ysize=30)					
prevobs_button  = WIDGET_BUTTON(base, value='Previous', uvalue='prevobs' $
                               ,/ALIGN_CENTER ,xsize=100)
obs_txt         = WIDGET_TEXT(base,value=observatory[0] $
                             ,uvalue='observatory' $
                             ,xsize=10,/ALIGN_CENTER)
nextobs_button  = WIDGET_BUTTON(base, value='Next', uvalue='nextobs' $
                               ,/ALIGN_CENTER,xsize=100)
gap_lbl        = WIDGET_LABEL(base,value='  ' $
                              ,xsize=30)
slide_button   = WIDGET_SLIDER(base, uvalue='slider', value=maxv $
                               ,MAXIMUM=maxv,MINIMUM=minv $
                               ,title='dB above background' $
                               ,/FRAME,/ALIGN_CENTER)			 
gap_lbl        = WIDGET_LABEL(base,value='  ' $
                              ,xsize=30)
fr0_lbl         = WIDGET_LABEL(base, value=' FREQ. (kHz) = ', $
                               xsize=100,ysize=30)
fmin_txt        = WIDGET_TEXT(base,value=fmin,uvalue='ufmin', $
                              xsize=10,/EDITABLE)
fr1_lbl         = WIDGET_LABEL(base, value=' to ', $
                              xsize=25,ysize=30)
fmax_txt        = WIDGET_TEXT(base,value=fmax,uvalue='ufmax', $
                              xsize=10,/EDITABLE)
gap_lbl         = WIDGET_LABEL(base,value='  ', $
                               xsize=10)
log_button      = CW_BGROUP(base, ['ylog'], /ROW, /NONEXCLUSIVE, $ 
                            uvalue='uylog', $
                            set_value=[yl],$
                            xsize=70,ysize=30)
;************************

WIDGET_CONTROL, base, /REALIZE
XMANAGER, 'wid', base, event_handler='radex_events',/NO_BLOCK

!mouse.button = 0 & loop = 0b
radex_display
while loop eq 0b do radex_select

END


