PRO radex_select

;+
; NAME:
;       radex_select
;
; PURPOSE:
;       Permits to select and save radio event contours 
;       on dynamical spectrum using the cursor of mouse. 
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
; OPTIONAL KEYWORD PARAMETERS:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS/COMMENTS:
;       None.
;
; CALL:
;       radex_bounds
;
; MODIFICATION HISTORY:
;      Written  by X.Bonnin (LESIA), 10-NOV-2005.
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

COMMON path, ULYSSES_DATAPATH, WIND_DATAPATH, STEREOA_DATAPATH, STEREOB_DATAPATH, NANCAY_DATAPATH, SAVEPATH
COMMON param, day, obs, obs_id, data, nevents
COMMON option, tr, fr, minv, maxv, yl, slnt, ct, wid

color_table = ct
date = day
observatory = obs[obs_id]

		
; RESTORE PLOT INFO & DATA FOR THE CURRENT OBSERVATORY
current_id = data[obs_id].id
current_obs = strlowcase(data[obs_id].obs)
current_rec = strlowcase(data[obs_id].inst)
t = *data[obs_id].time 
f = *data[obs_id].freq
s = *data[obs_id].flux
plot_info = *data[obs_id].map
plot_info.p.multi=0

; Check output file existence and last event index
savefile = current_obs+'_'+strmid(current_rec,0,3)+'_'+date+'_events.csv'
output_file = SAVEPATH + path_sep() + savefile
file_exists = file_test(output_file)
if (file_exists) then begin
   nlines = file_lines(output_file)
   ev_id = long(nlines)
endif else ev_id=1l
str_ev_id = strtrim(ev_id,2)

;**** SELECT EVENT ON DYN. SPECT. ****
print,'--> Select event #'+string(str_ev_id,format='(i3.3)')+$
      ' for '+observatory

device,decomposed=0 & mouse=0
bounds = radex_bounds(t,f,plot_info=plot_info, $
                      window_set=window_set, $ 
                      color_table=39,  $
                      mouse=mouse,found=found)
if (mouse eq 2) then print,'--> CURRENT SELECTION HAS BEEN CANCELLED!'
nbounds=n_elements(bounds)
if not (found) or (nbounds eq 1) then return
npoints=nbounds/2l

loadct,color_table,/SILENT
		
;loadct,39,/SILENT
;oplot,bounds(1,*),bounds(0,*),psym=3,color=50,thick=1.
;oplot,bounds(2,*),bounds(0,*),psym=3,color=50,thick=1.
;loadct,color_table,/SILENT

;save event data in csv format file (.txt)
;============================
header='index|npoints|time|freq'
line2write=str_ev_id+'|'+strtrim(npoints,2)+'|'+ $
           strjoin(strtrim(reform(bounds[0,*]),2),',')+'|'+ $
           strjoin(strtrim(reform(bounds[1,*]),2),',')
openw,lun,output_file,/GET_LUN,/APPEND
if not (file_exists) then printf,lun,header
printf,lun,line2write
close,lun
free_lun,lun

print,'==================================='
print,'--> Event #'+str_ev_id+' saved in '+output_file
print,''            

data[obs_id].id=ev_id
	
nevents++
END


