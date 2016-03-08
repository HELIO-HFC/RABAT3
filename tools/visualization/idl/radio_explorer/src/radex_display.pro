PRO radex_display

;+
; NAME:
;      radex_display
;
; PURPOSE:
;      Load and display radio data. 
;       
; CATEGORY:
;      Plot
;
; GROUP:
;     radex
;
; CALLING SEQUENCE:
;     None.
;
; REQUIRED INPUTS:
;     None.
;
; OPTIONAL INPUTS
;     None.
;
; OPTIONAL KEYWORD PARAMETERS:
;     None.
;
; COMMON BLOCKS:
;    None.
;
; SIDE EFFECTS:
;    None.
;
; RESTRICTIONS/COMMENTS:
;    None
;
; CALL:
;    
;
; MODIFICATION HISTORY:
;    Written by X. Bonnin (LESIA),  10-NOV-2005.
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

COMMON param, day, obs, obs_id, data, nevents
COMMON path, ULYSSES_DATAPATH, WIND_DATAPATH, STEREOA_DATAPATH, STEREOB_DATAPATH, NANCAY_DATAPATH, SAVEPATH
COMMON option, tr, fr, minv, maxv, yl, slnt, ct, wid

date = day
observatory=obs

;************************
nobs = n_elements(observatory)
xtitle = 'UT (Hrs)'
ytitle = 'Frequency (kHz)'
frange = float(fr)
trange = tr
minval = minv & maxval = maxv
window_set = wid & YLOG = yl
;************************

;**** LOADING DATA ****
print,''
print,'--> Current date : '+date

if (size(data,/TNAME) ne 'STRUCT') then begin
   data={obs:'',inst:'', id:1l, $
         ephem:fltarr(3),$
         time:ptr_new(0.),freq:ptr_new(0.), $
         flux:ptr_new(0.), $
         map:ptr_new(0.)} 
   data = replicate(data,nobs)
endif

!P.multi = [0,1,nobs]
wset,window_set

FOR j=0,nobs-1 DO BEGIN

	CASE observatory[j] OF

	;**** WIND/WAVES ****
           'WIND':BEGIN
				  
              print,'--> LOADING WIND/WAVES DATA, PLEASE WAIT...'	  
				  
              obs_j = 'WIN'
              inst_j = 'WAVES'

	      ;Ephemerids (to be done)
              ephem_j = [0.,0.,0.]
				
	      ;load WIND/WAVES TNR/RAD1/RAD2 60s average data
              filepath = ''
              data_j = get_wind_waves_data(date, $
                                           datapath=WIND_DATAPATH, $
                                           found=found, $
                                           /DOWNLOAD_FILE)
              IF (FOUND eq 0b) THEN BEGIN
                 print,'>> WIND data can not be loaded for this date <<'
                 goto,SKIP_SC
              ENDIF
			 
              dte = data_j.date
              t = data_j.ut
              nt = n_elements(t)
              f = data_j.fkhz
              nf = n_elements(f)
              
	      ;Intensity on background ratio
              s = data_j.flux

	      ;AFFICHE TOUTES LES FREQUENCES SUR TNR ET 
	      ;SEULEMENT LES FREQUENCES RAD1 POUR LESQUELLES 
	      ;f1 > max(f_tnr)
              w = where(data_j.rec eq 'TNR')
              fm_tnr = max(f(w))
              w = where(data_j.rec eq 'RAD1' and f le fm_tnr,complement=cw)  

              f = f(cw)
              s = s(*,cw)
              wfmin = min(f,max=wfmax,/NAN)
			
	      ;Convert in dB
              sdb = 10.*alog10(s > 1.)

              if keyword_set(frange) then begin
                 zf = where(f ge frange(0) and f le frange(1),nzf)
                 if zf(0) ne -1 then begin
                    f = f(zf)
                    s = s(*,zf)
                    sdb = sdb(*,zf)
                    nf = nzf
                 endif
              endif else frange = [wfmin,wfmax]
			
              sdb = sdb>(minval)<(maxval)
              
           END
		
	;**** ULYSSES/URAP ****
           'ULYSSES':BEGIN
				  
              print,'--> LOADING ULYSSES/URAP DATA, PLEASE WAIT...'	  
				  
              obs_j = 'ULS'
              inst_j = 'URAP'
			
	      ;Ephemerids (to be done)
              ephem_j = [0.,0.,0.]
			
	      ;load ULYSSES/URAP RAR 144sec average data
              filepath = ''
              data_j = get_ulysses_urap_data(date, $
                                             DATAPATH=ULYSSES_DATAPATH, $
                                             /FTP, $
                                             FOUND=FOUND)
              IF not (found) THEN BEGIN
                 print,'>> ULYSSES data can not be loaded for this date <<'
                 goto,SKIP_SC
              ENDIF
              
              dte = data_j.date
              t = data_j.ut
              nt = n_elements(t)
              f = data_j.fkhz
              nf = n_elements(f)
			
	      ;Intensity on background ratio
              s = data_j.flux
	
	      ;dB
              sdb = 10.*alog10(s > 1.)

              ufmin = min(f,max=ufmax,/NAN)
              if keyword_set(frange) then begin
                 zf = where(f ge frange(0) and f le frange(1),nzf)
                 if zf(0) ne -1 then begin
                    f = f(zf)
                    s = s(*,zf)
                    sdb = sdb(*,zf)
                    nf = nzf
                 endif
              endif else frange=[ufmin,ufmax]
			
              sdb = sdb>(minval)<(maxval)
			
           END   
   
;**** STEREO A ****
           'STEREO_A':BEGIN

              print,'--> LOADING STEREO_A/WAVES DATA, PLEASE WAIT...'	  
              
              obs_j = 'STA'
              inst_j = 'WAVES'
              
              ephem_j = fltarr(3)

              data_j = get_stereo_waves_data(date,obs_j, $
                                             datapath=STEREOA_DATAPATH, $
                                             /DOWNLOAD_FILE,$
                                             found=found)
              IF not (found) THEN BEGIN
                 print,'>> STEREO A data can not be loaded for this date <<'
                 goto,SKIP_SC
              ENDIF
              
              dte = data_j.date
              t = data_j.ut
              nt = n_elements(t)
              f = data_j.fkhz
              nf = n_elements(f)
              
	      ; Intensity/background (Already in dB)
              s = data_j.flux > 0.
              
              sdb = s>(minval)<(maxval)

              afmin = min(f,max=afmax,/NAN)
              if keyword_set(frange) then begin
                 zf = where(f ge frange(0) and f le frange(1),nzf)
                 if zf(0) ne -1 then begin
                    f = f(zf)
                    s = s(*,zf)
                    sdb = sdb(*,zf)
                    nf = nzf
                 endif
              endif else frange=[afmin,afmax]
           END

;**** STEREO B ****
           'STEREO_B':BEGIN

              print,'--> LOADING STEREO_B/WAVES DATA, PLEASE WAIT...'
              
              obs_j = 'STB'
              inst_j = 'WAVES'
              
              ephem_j = fltarr(3)

              data_j = get_stereo_waves_data(date,obs_j, $
                                            datapath=STEREOB_DATAPATH, $
                                            /DOWNLOAD_FILE,/VERBOSE, $
                                            found=found)
              IF not (found) THEN BEGIN
                 print,'>> STEREO B data can not be loaded for this date <<'
                 goto,SKIP_SC
              ENDIF
			
              dte = data_j.date
              t = data_j.ut
              nt = n_elements(t)
              f = data_j.fkhz
              nf = n_elements(f)
			
	      ;Intensity/background (Already in dB)
              s = data_j.flux > 0.
		  
              sdb = s>(minval)<(maxval)

              bfmin = min(f,max=bfmax,/NAN)
              if keyword_set(frange) then begin
                 zf = where(f ge frange(0) and f le frange(1),nzf)
                 if zf(0) ne -1 then begin
                    f = f(zf)
                    s = s(*,zf)
                    sdb = sdb(*,zf)
                    nf = nzf
                 endif
              endif else frange=[bfmin,bfmax]
              
           END
           'NANCAY':begin
              print,'--> LOADING NANCAY/DECAMETRIC ARRAY DATA, PLEASE WAIT...'
              
              obs_j = 'NAN'
              inst_j = 'NDA'
              
              coord = fltarr(3)

              stop,'To be done!'
           end
           ELSE:BEGIN
              message,/CONT,'>> Current observatory ('+strtrim(observatory[j],2)+') is not available, skipping! <<'
              goto,SKIP_SC
           END
        ENDCASE            
      
;#### DISPLAY DYNAMICAL SPECTRA #####
	title = observatory[j]+'/'+inst_j+' ['+day+']'
	display2d,sdb,X_in=t,Y_in=long(f), $
                  ylog=ylog, $
                  min_val=minval,max_val=maxval, $ 
                  window_set=window_set, $
                  map=plot_info, $
                  title=title,xtitle=xtitle,ytitle=ytitle, $
                  color_table=ct, $
                  /REVERSE_COLORS


;**** display obs ephem ****
;    xyouts,0.05+j*((0.95-0.05)/nsc),0.0005,/normal,color=0 $
;          ,' - '+sc+' ['+strtrim(string(coord(0),format='(i4.3)'),2) $
;         +'∞,'+strtrim(string(coord(1),format='(i4.3)'),2)+'∞,' $
;        +strtrim(string(coord(2),format='(f5.2)'),2)+' au]  - '

        data[j].obs=obs_j
        data[j].inst=inst_j
        data[j].ephem=ephem_j
        *data[j].time=t
        *data[j].freq=f
        *data[j].flux=sdb
        *data[j].map=plot_info
	
SKIP_SC:
ENDFOR
!p.multi = 0

END
