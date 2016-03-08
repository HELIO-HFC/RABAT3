PRO radex_events,event

;+
; NAME:
;        radex_events
;
; PURPOSE:
;        Execute the event triggered by the widget buttons.
;
; CATEGORY:
;       Visualization tool
;
; GROUP:
;       radex      
;
; CALLING SEQUENCE:
;       None.
;
; REQUIRED INPUTS:
;       None.
;
; OPTIONAL INPUTS
;       None.
;
; KEYWORD PARAMETERS:
;	None.
;
; COMMON BLOCKS:
;      param, widget, option
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS/COMMENTS:
;       None.
;
; CALL:
;       radex_display
;       radex_actions
;
; MODIFICATION HISTORY:
;       Written by X.Bonnin (LESIA), 10-NOV-2005.
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

COMMON param, day, obs, id_obs, data, nevents
COMMON option, tr, fr, minv, maxv, yl, slnt, ct, wid
COMMON widget, prevday_button, day_txt, nextday_button, $
   prevobs_button, obs_txt, nextobs_button, $
   fmin_txt, fmax_txt, log_button, $
   slide_button, quit_button, help_button

widget_control,event.id,get_uvalue=uval

nobs=n_elements(obs)
!mouse.button = 0 & loop = 0b
case uval of
   'prevobs':begin
      id_obs--
      if (id_obs lt 0) then id_obs = nobs - 1
      widget_control,obs_txt,set_value=obs[id_obs]		
   end
   'nextobs':begin
      id_obs++
      if (id_obs gt nobs-1) then id_obs = 0
      widget_control,obs_txt,set_value=obs[id_obs]			
   end
   'prevday':begin
      day = (countday(day,nday=-2))(1)
      id_obs = 0L & data = 0b
      widget_control,day_txt,set_value=day
      widget_control,obs_txt,set_value=obs[id_obs]
      print,'--> Go to previous day'
      radex_display				
   end
   'nextday':begin
      day = (countday(day,nday=2))(1)
      id_obs = 0L & data = 0b
      print,day
      widget_control,day_txt,set_value=day
      widget_control,obs_txt,set_value=obs(id_obs)
      print,'--> Go to next day'
      radex_display			
   end
   'udate':begin
      data = 0b
      widget_control,event.id,get_value=day
      print,'--> New date = '+day
      radex_display
   end
   'ufmin':begin
      data = 0b
      widget_control,event.id,get_value=fmin
      fr[0] = float(fmin[0])
      print,'--> New min. frequency = '+fmin+' kHz'
      radex_display
   end
   'ufmax':begin
      data = 0b
      widget_control,event.id,get_value=fmax     
      fr[1]=float(fmax[0])
      print,'--> New max. frequency = '+fmax+' kHz'
      radex_display
   end
   'uylog':begin
      data=0b
      widget_control,event.id,get_value=ylog
      yl = fix(ylog)
      if (yl eq 1) then print,'--> Use log scale for Y-axis' $
                              else print,'--> Use linear scale for Y-axis'
      radex_display
   end
   'slider':begin
      widget_control,event.id,get_value=maxv
      radex_display
   end
   'uhelp':begin
      print,'========================================='
      print,'--> Press left mouse button to select data points.'
      print,'--> Press right mouse button to end the selection.'
      print,'--> Press middle mouse button to cancel.'
      print,'========================================='
   end
   'uquit':begin
      radex_actions,uval
   end
endcase	

while loop eq 0b do radex_select
END
