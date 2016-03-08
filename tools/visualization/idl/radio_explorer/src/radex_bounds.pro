FUNCTION radex_bounds,t,f, $
                      plot_info=plot_info, $
                      window_set=window_set, $
                      color_table=color_table, $
                      mouse=mouse, $
                      found=found, $
                      help=help

;+
; NAME:
;       radex_bounds
;
; PURPOSE:
;       Select contour data points on the dynamical spectrum using mouse cursor.
;       
; CATEGORY:
;       Visualization tool
;
; GROUP:
;       radex
;
; CALLING SEQUENCE:
;       results = radex_bounds(t, f)
;
; REQUIRED INPUTS:
;       t - Vector containing time values.
;       f - Vector containing frequency values.
;
; OPTIONAL INPUTS
;       plot_info   - Structure providing system variables of the
;                     current plot.
;       window_set  - Specify the window index.
;       color_table - Specify the IDL color table to load.     
;
; KEYWORD PARAMETERS:
;       /HELP        - display the help and return 0 
;
; OUTPUTS:
;	boundaries - (2,n) array containing the [time,freq] coordinates of the n contour data points :
;
; OPTIONAL OUTPUTS:
;       mouse       - contains mouse button state
;       found       - equal to 1 if the contour selection succeed (0 else)
;
; COMMON BLOCKS:
;       widget
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS/COMMENTS:
;      None.
;
; CALL:
;     loadploat 
;     radex_events
;
; MODIFICATION HISTORY:
;     Written by X.Bonnin (LESIA), 10-NOV-2005
;
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
COMMON widget, prevday_button, day_txt, nextday_button, $
   prevobs_button, obs_txt, nextobs_button, $
   fmin_txt, fmax_txt, log_button, $
   slide_button, quit_button, help_button

found = 0B
IF keyword_set(help) OR N_params() LT 2 THEN BEGIN
    message,/info,'Call is:'
    print,'Result = radex_bounds(t,f $'
    print,'                      ,plot_info=plot_info $' 
    print,'                      ,window_set=window_set $'
    print,'                      ,color_table=color_table $'
    print,'                      ,found=found $'
    print,'                      ,mouse=mouse)'
    return,0
ENDIF

again:

CASE !version.os_family OF
    'Windows': cr = string("15b)+string("12b)
    'MacOS' : cr = string("15b)
    'unix' : cr = string("15b)
ENDCASE
form="($,' time = ',i2.2,':',i2.2,' Hrs, freq =',f8.2,' kHz ',a)"


IF keyword_set(window_set) THEN wset,window_set
IF keyword_set(color_table) THEN loadct,color_table,/silent
IF keyword_set(plot_info) THEN loadplot,plot_info

;DEFINE BOUNDARIES
px0 = 0. & py = 0.
time = 0. & freq = 0.
!mouse.button = 0 
loop = 0 & mouse = 0 & np=0l
WHILE loop EQ 0 DO BEGIN
  
    CURSOR,px,py,/nowait,/data
   	
   	;Widget button states 
    state = widget_event(prevday_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state
    state = widget_event(nextday_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state
    state = widget_event(prevobs_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state	
    state = widget_event(nextobs_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state
    state = widget_event(quit_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state
    state = widget_event(help_button,/NOWAIT)	
    if (state.id ne 0) then radex_events,state
    state = widget_event(day_txt,/NOWAIT)
    if (state.id ne 0) then radex_events,state
    state = widget_event(slide_button,/NOWAIT)
    if (state.id ne 0) then radex_events,state
    state = widget_event(fmin_txt,/NOWAIT)
    if (state.id ne 0) then radex_events,state
    state = widget_event(fmax_txt,/NOWAIT)
    if (state.id ne 0) then radex_events,state
    state = widget_event(log_button,/NOWAIT)
    if (state.id ne 0) then radex_events,state	


    if px lt min(t) then continue
    if px gt max(t) then continue
    if py lt min(f) then continue
    if py gt max(f) then continue

    mz = min(abs(px-t),z)
    px = t(z(0))
    mz = min(abs(py-f),z)
    py = f(z(0))
    
    hh = fix(px) & mm = fix((px-hh)*60.)
    print,form = form, hh,mm,py,cr    

    CASE !mouse.button OF
        0:BEGIN
            mouse = 0
        END
        1:BEGIN
           print,''
           print,format="('time = ',i2.2,':',i2.2,' Hrs, freq =',f8.2,' kHz --> saved')",hh,mm,py
           time = [time,px]
           freq = [freq,py]
           np++
           
           IF np+1 GT 2 THEN BEGIN
              OPLOT,time(1:*),freq(1:*),line=0,thick=2.,color=254
              OPLOT,[px,px],[py,py],psym=1,thick=2.,color=254
           ENDIF ELSE BEGIN
              OPLOT,[time(1),time(1)],[freq(1),freq(1)],psym=1,thick=2. $
                    ,color=254
              px0 = px & py0 = py
           ENDELSE
           wait,0.2
           mouse = 1
        END
        2:BEGIN
           mouse = 2
           return,0
        END
        4:BEGIN
           IF np GT 1 THEN BEGIN
              ;OPLOT,[time(np-1),px0],[freq(np-1),py0] $
              ;     ,line=0,thick=2.,color=254
              loop = 1
              wait,0.2
           ENDIF ELSE BEGIN
              mouse = 4
              return,0
           ENDELSE     
        END
        ELSE:loop=0
    ENDCASE
ENDWHILE
IF (np eq 0l) THEN goto,again
time = time(1:*)
freq = freq(1:*)

boundaries = fltarr(2,np)
boundaries[0,*] = time
boundaries[1,*] = freq

;TAKE DATA POINTS IN THE EDGE OF BOUNDARIES (obsolete)
;print,'Searching for contour data points ...'
;time = [time,time[0]] & freq = [freq,freq[0]]
;oROI = OBJ_NEW('IDLanROI',time,freq)
	
;trange = [min(time),max(time)]
;frange = [min(freq),max(freq)]

;wt = where(t ge trange(0) and t le trange(1),nt)
;wf = where(f ge frange(0) and f le frange(1),nf)

;if (wt(0) eq -1) or (wf(0) eq -1) then begin
;   print,'>> No data point inside contour selection <<'
;   goto,again
;endif

;fkhz = 0. & ut = 0.
;for i=0,nt-1 do begin
;   for j=0,nf-1 do begin
;      ptTest = oROI -> ContainsPoints(t(wt(i)),f(wf(j)))
;      if (ptTest ne 0) then begin
;         fkhz = [fkhz,f(wf(j))]
;         ut = [ut,t(wt(i))]
;      endif
;   endfor
;endfor
;OBJ_DESTROY, oROI
;fkhz = fkhz(1:*)
;ut = ut(1:*)

;freq = fkhz[uniq(fkhz,sort(fkhz))]
;nf = n_elements(freq)
;boundaries = fltarr(3,nf)
;for j=0,nf-1 do begin
;   wf = where(freq(j) eq fkhz)
;   boundaries(0,j) = freq(j)
;   boundaries(1,j) = min(ut(wf))
;   boundaries(2,j) = max(ut(wf))
;endfor

found = 1B
return,boundaries
END
