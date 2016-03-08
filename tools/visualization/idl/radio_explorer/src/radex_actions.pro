PRO radex_actions,val

;+
; NAME:
;       radex_actions
;
; PURPOSE:
;       Setup system variables when radex software starts 
;       and exit program if QUIT widget button is pressed. 
;
; CATEGORY:
;
;       Graphic dynamical program
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
;     param, option, widget, path
;
; SIDE EFFECTS:
;     None.
;
; RESTRICTIONS/COMMENTS:
;     None.
;
; CALL:
;
;
; MODIFICATION HISTORY:
;     Written by X. Bonnin (LESIA),  10-NOV-2005.
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

case val of
   'start':begin
			
      ;**** DEFINE SOME DIRECTORY PATHS ****
		
      ;Save current directory path
      CD,current=curr_dir 
      
     ;WIND DATAPATH
      if ((where(obs eq 'WIND'))(0) ne -1) and (WIND_DATAPATH eq '') then begin
         WIND_DATAPATH=getenv('WIND_WAVES_DATA_DIR')
         if (WIND_DATAPATH[0] eq '') then begin
            if (~slnt) then begin
               message,/CONT,'>> WIND_WAVES_DATA_DIR is not defined <<'
               print,'-> WIND data directory is assumed to be the current one.'
            endif
            WIND_DATAPATH = curr_dir
         endif
      endif
		
      ;STEREOA DATAPATH
      if ((where(obs eq 'STEREO_A'))(0) ne -1) and (STEREOA_DATAPATH eq '') then begin
         STEREOA_DATAPATH=getenv('STEREOA_WAVES_DATA_DIR')
         if (STEREOA_DATAPATH[0] eq '') then begin
            if (~slnt) then begin
               message,/CONT,'>> STEREOA_WAVES_DATA_DIR is not defined <<'
               print,'-> STEREOA data directory is assumed to be current one.'
            endif
            STEREOA_DATAPATH = curr_dir
         endif
      endif

      ;STEREOB DATAPATH
      if ((where(obs eq 'STEREO_B'))(0) ne -1) and (STEREOB_DATAPATH eq '') then begin
         STEREOB_DATAPATH=getenv('STEREOB_WAVES_DATA_DIR')
         if (STEREOB_DATAPATH[0] eq '') then begin
            if (~slnt) then begin
               message,/CONT,'>> STEREOB_WAVES_DATA_DIR is not defined <<'
               print,'-> STEREOB data directory is assumed to be current one.'
            endif
            STEREOB_DATAPATH = curr_dir
         endif
      endif		
	
      ;ULYSSES DATAPATH
      if ((where(obs eq 'ULYSSES'))(0) ne -1) and (ULYSSES_DATAPATH eq '') then begin
         ULYSSES_DATAPATH=getenv('ULYSSE_URAP_DATA_DIR')
         if (ULYSSES_DATAPATH[0] eq '') then begin
            if (~slnt) then begin
               message,/CONT,'>> ULYSSES_URAP_DATA_DIR is not defined <<'
               print,'-> ULYSSES data directory is assumed to be current one.'
            endif
            ULYSSES_DATAPATH = curr_dir
         endif
      endif

      ;NANCAY DATAPATH
      if ((where(obs eq 'NANCAY'))(0) ne -1) and (NANCAY_DATAPATH eq '') then begin
         NANCAY_DATAPATH=getenv('NANCAY_NDA_DATA_DIR')
         if (NANCAY_DATAPATH[0] eq '') then begin
            if (~slnt) then begin
               message,/CONT,'>> NANCAY_NDA_DATA_DIR is not defined <<'
               print,'-> NANCAY data directory is assumed to be current one.'
            endif
            NANCAY_DATAPATH = curr_dir
         endif
      endif

		
      ;SAVEPATH = path where output file (.EV) will be saved.
      if not (keyword_set(SAVEPATH)) then SAVEPATH  = curr_dir
		
		;************************
   end
   'uquit':begin
      
      widget_control,/reset
            
      print,''
      print,'Number of events saved : '+strtrim(nevents,2)
      print,'Program has ended correctly.'
      print,systime()
      exit
   end
   else:print,''
endcase	

END
