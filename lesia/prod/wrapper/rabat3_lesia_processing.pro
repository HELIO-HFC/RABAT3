PRO rabat3_lesia_processing,config_file, results, $
                          starttime=starttime,endtime=endtime, $
                          data_directory=data_directory, $
                          output_directory=output_directory, $
                          nfreq_max=nfreq_max, $
                          HELP=HELP

;+
; NAME:
;	rabat3_lesia_processing
;
; PURPOSE:
; 	The RAdio Burst Automated Tracking software (RABAT3) is dedicated
;	to the type III solar radio burst recognition on a dynamical
;	spectrum.
;
;       Current data set that can be processed are:
;	        Wind/Waves (Rad1,Rad2)
;           	STEREO/Waves (HFR)
;           	Nancay Decametric Array
;
; CATEGORY:
;	Feature recognition 
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>rabat3_lesia_processing, config_file
;
; INPUTS:
;	config_file - Scalar of string type specifying the
;                pathname of the configuration file.
;		           The configuration file provides the 
;                input parameters to use for the 
;                current recognition process.
;	 
;
; OPTIONAL INPUTS:
;       starttime        - String providing the first date (YYYYMMDD) of
;                          the time range to process.
;                          Default is current date.
;       endtime          - String providing the end date (YYYYMMDD) of
;                          the time range to process.
;                          Default is current date.
;       nfreq_max        - Maximum number of frequency points returned 
;                          for each burst detected.
;	output_directory - String giving the path of the directory
;                          where output files will be saved.
;                          Default is the current one.
;       data_directory   - Vector or Scalar of string type giving
;                          the path of the directory(ies) where 
;                          data files are stored (or will be
;                          downloaded). 
;
; KEYWORD PARAMETERS: 
;       /HELP - Display help message.
;
; OUTPUTS:
;	results - Structure array providing results
;                 of the detections.	
;
; OPTIONAL OUTPUTS:
;       None.
;		
; COMMON BLOCKS:		
;	None.	
;	
; SIDE EFFECTS:
;	None.
;		
; RESTRICTIONS/COMMENTS:
;	None.
;			
; CALL:
;       countday
;       get_waves_file
;       rabat3_processing
;       type3_driftrate_func
;
; EXAMPLE:
;	None.		
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	03-OCT-2013.			
;
;-


rabat3_processing,'','',frc_info,/GET_FRC_INFO

if not (keyword_set(config_file)) or (keyword_set(HELP)) then begin
   message,/INFO,'Usage:'
   print,'rabat3_lesia_processing, config_file, $'
   print,'                       starttime=starttime, $'
   print,'                       endtime=endtime, $'  
   print,'                       data_directory=data_directory, $'
   print,'                       output_directory=output_directory, $'
   print,'                       nfreq_max=nfreq_max, $'
   print,'                       /HELP'
   return
endif

if not (file_test(config_file)) then message,config_file+' does not exist!'
if not (keyword_set(endtime)) then spawn,'date +%Y%m%d',endtime
if not (keyword_set(starttime)) then starttime=endtime
if (long(endtime) lt long(starttime)) then message,'starttime must be older than endtime!'
cd,current=current_directory
if not (keyword_set(output_directory)) then output_directory=current_directory
if not (keyword_set(data_directory)) then data_directory=current_directory

dates=countday(starttime,endtime,nday=nday)

args=rabat3_parseconfig(config_file)
obs=strupcase(args.observatory)

for i=0,nday-1 do begin
   case obs of
      'WIND':begin
         if (n_elements(data_directory) eq 1) then data_directory=strarr(2)+data_directory
         data_file=strarr(2) & rec=['rad1','rad2']
         for k=0,1 do begin
            get_waves_file,dates[i],rec[k],file_k,target_dir=data_directory[k], $
                           level='l2_avg',/NOCLOB
            if (file_k eq '') then begin
               message,/CONT,'No file found!'
               return
            endif
            data_file[k]=file_k
         endfor
      end
      else:begin
         print,'Unknown observatory!'
         return
      end
   endcase
   output_file=strlowcase(obs)+'_type3_'+dates[i]+'_auto.txt'
   output_header='Written by : '+frc_info.code+' Software Version '+frc_info.version+', '+systime()
   output_header=[output_header,strupcase(obs)+' Data '+strjoin(rec,' ')+': '+$
                  strmid(dates[i],0,4)+'/'+strmid(dates[i],4,2)+'/'+strmid(dates[i],6,2)]
   output_header=[output_header,'','Time [minutes]','Frequency [kHz]','']
   output_path=output_directory+path_sep()+output_file   

   print,'Running rabat3_processing for ['+strjoin(data_file,',')+']'
   rabat3_processing,data_file,config_file,results,nburst=nburst

   if (nburst gt 0) then begin
      openw,lun,output_path,/GET_LUN
      for k=0,n_elements(output_header)-1 do printf,lun,output_header[k]
      for j=0,nburst-1 do begin
         freq_j=results[j].burst_freq & nfreq_j=n_elements(freq_j)

         tburst_j=type3_driftrate_func(freq_j,$
                                       results[j].fitting)
         tburst_j=long(tburst_j/60.0) ; sec to min.
         freq_j=freq_j*1000. ; MHz to kHz

         where_in=where(tburst_j ge 0l and tburst_j le 1440,nfreq_j)
         if (where_in[0] eq -1) then continue
         tburst_j=tburst_j[where_in] & freq_j=freq_j[where_in]

         if (keyword_set(nfreq_max)) then begin
            if (nfreq_max lt nfreq_j) then begin
               freq_j = interpol(freq_j,nfreq_max)
               tburst_j = interpol(tburst_j,lindgen(nfreq_j),lindgen(nfreq_max))
               nfreq_j=nfreq_max
            endif
         endif

         printf,lun,' '+strtrim(j+1l,2)+' TypeIII :  '+strtrim(nfreq_j,2)
         printf,lun,'T : '+strjoin(string(tburst_j,format='(i5)'),'    ')
         printf,lun,'F : '+strjoin(string(freq_j,format='(i5)'),'    ')
      endfor
      close,lun
      free_lun,lun
      print,output_path+' saved'
   endif else print,'No burst detected!'
endfor
END
