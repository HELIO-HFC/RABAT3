PRO t3_manual_selection,data_files, config_file, output_dir, $
                  time_window=time_window, $
                  min_val=min_val, max_val=max_val, $
                  DEBUG=DEBUG, OVERWRITE=OVERWRITE

;+
; NAME:
;       t3_manual_selection
;
; PURPOSE:
;       Program to select type 3 bursts manually
;       Information about selected bursts will be saved
;       in a ASCII format files
;
; CATEGORY:
;       Feature recognition
;
; GROUP:
;       RABAT3
;
; CALLING SEQUENCE:
;       IDL>t3_manual_selection, data_file, config_file, output_dir
;
; INPUTS:
;       data_file   - Scalar of string type specifying the
;                     pathname of the data file to process for a
;                     given day.
;
;       config_file - Scalar of string type specifying the
;                     pathname of the configuration file.
;                     The configuration file provides the
;                     input parameters to use for the
;                     current recognition process.
;
;        output_dir - Path of the directory where output files will be saved.
;
;
; OPTIONAL INPUTS:
;     time_window - Size of the window in seconds to display at each step.
;                                Default is 86400 sec.
;
; KEYWORD PARAMETERS:
;       /DEBUG                     - Debug mode.
;       /OVERWRITE           - Overwrite existing output file(s).
;
; OUTPUTS:
;       Save results in an output file(s) in output_dir directory.
;
; OPTIONAL OUTPUTS:
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
;       rabat3_parseconfig
;       rabat3_getdata
;       display2d
;
; EXAMPLE:
;       None.
;
; MODIFICATION HISTORY:
;       Written by X.Bonnin,  26-JUL-2010.
;
;-

sep = path_sep()
cd,current=Current_dir

CASE !version.os_family OF
    'Windows': cr = string("15b)+string("12b)
    'MacOS' : cr = string("15b)
    'unix' : cr = string("15b)
ENDCASE
form="($,' time = ',a,', freq =',f8.2,' kHz ',a)"

if (n_params() lt 2) then begin
   message,/INFO,'Call is:'
   print,'t3_manual_selection,data_files, config_file, output_dir, $'
   print,'             time_window=time_window, $'
   print,'             min_val=min_val,max_val=max_val, $'
   print,'             /DEBUG, /OVERWRITE'
   return
endif
DEBUG=keyword_set(DEBUG)
OVERWRITE=keyword_set(OVERWRITE)

if not (keyword_set(time_window)) then time_window = 86400.0d

if not (file_test(output_dir,/DIR)) then message,'Output directory '+output_dir+' does not exist!'

device,get_screen_size=screen
draw_widget, $
   xsize=screen[0]*0.8,ysize=screen[1]*0.95, $
   window_set=window_set

nfiles  = n_elements(data_files)

args = rabat3_parseconfig(config_file,VERBOSE=VERBOSE)
if (size(args,/TNAME) ne 'STRUCT') then message,'Can not read '+config_file+'!'
obs = args.observatory

n3 = 0L
for i=0,nfiles-1 do begin
      print,i+1,nfiles, data_files[i], format='("[", i3.3,"/", i3.3, "] - Reading ",a)'
      data_i = rabat3_getdata(args,data_files[i], /VERB)

      date = data_i.date_obs
      t = double(data_i.time)
      tmin = min(t, max=tmax, /NAN)
      f = data_i.freq
      fmin  = min(f, max=fmax, /NAN)
      s = data_i.spectra

      ; Initialize output data for current file
        n3_i = 0l
        t3_id = -1l & t3_time= -1l & t3_date = ''
        t3_mean_freq = -1.0

        basename = file_basename(data_files[i],strmid(data_files[i],strpos(data_files[i],'.',/REVERSE_SEARCH)))
        output_file = output_dir + path_sep() + basename + '_t3.csv' ; A MODIFIER (enlever extension fichier data)

      nstep = long((tmax - tmin)/time_window) + 1l
      t0 = tmin
      for j=0,nstep-1 do begin
        if (t0 ge tmax) then break
        t1 = t0 + time_window

        st0 = cvtime(t0/3600.0,/DOUBLE)
        st1 = cvtime(t1/3600.0,/DOUBLE)
            print,'Starting selection on ' + date + ' between ' + $
               st0 + ' and ' +  st1 + '...'
            !p.multi=[0,1,2]
            display2d,s,Xin=t,Yin=f, $
                xtitle='UT (seconds)',ytitle='Freq. (MHz)', $
              title=obs+' - '+date+ ' ['+st0+'-'+st1+']', $
              xrange=[t0,t1], /XS, $
              min_val=min_val,max_val=max_val, $
              window_set=window_set, color=0, $
              map=plot1, $
              /YLOG,/REVERSE_COL

              tots = total(s,2)
              min_tots = min(tots, max=max_tots)
              plot,t,tots, $
                     xrange=[t0,t1], /XS
              saveplot,plot2
              !p.multi=0

              print,''
              loop=1b & !mouse.button = 0
              while (loop) do begin
                 loadplot,plot1
                 cursor,px,py,/NOWAIT,/DATA
                 str_t = cvtime(px/3600.0d,/DOUBLE)
                 print,form = form,str_t, py,cr
;          xmin=min(abs(3600.0*px-burst_start),imin)
;          ; Display a line and dot that follow the cursor position on the second plot

          loadplot,plot2
          loadct,39,/SILENT
          xm = min(abs(px - t),ix)
          tx = t[ix] & totsx=tots[ix]

          device,set_graphics_function=6

           oplot,[tx,tx],[totsx, totsx],$
                color=200,psym=4,thick=4
         oplot,[tx,tx], [min_tots, max_tots], $
                color=50,thick=0.75
          wait, 0.1
          oplot,[tx,tx], [min_tots, max_tots], $
                color=50,thick=0.75
          oplot,[tx,tx],[totsx, totsx],$
                color=200,psym=4,thick=4

        device,set_graphics_function=3

         case !mouse.button of
             0:
             1:begin
                print,''
                wx = (where(long(tx) eq t3_time))[0]
                if (wx ne -1) then begin
                    print,'Event already saved'
                endif else begin
                    n3++ & n3_i++
                    t3_id = [t3_id, n3_i]
                    t3_time = [t3_time, long(tx)]
                    t3_date = [t3_date, date]
                    t3_mean_freq = [t3_mean_freq,py]
                    print,'New event #'+strtrim(n3_i,2)+' saved [' + strtrim(n3,2)+ ']'
                    oplot,[tx,tx],[totsx, totsx],$
                    color=150,psym=4,thick=4
                endelse
             end
             2:begin
                if (n3_i gt 0l) then begin
                    wx = (where(long(tx) eq t3_time,complement=cwx,ncomplement=ncwx))[0]
                    if (wx ne -1) then begin
                        id_i = t3_id[wx]
                        if (cwx[0] eq -1) then begin
                            t3_id = -1L
                            t3_time = -1L
                            t3_date = ""
                            t3_mean_freq = -1.0
                        endif else begin
                            t3_id = t3_id[cwx] ; A modifier (pas correct)
                            t3_time = t3_time[cwx]
                            t3_date = t3_date[cwx]
                            t3_mean_freq = t3_mean_freq[cwx]
                        endelse
                        n3-- & n3_i--
                        print,""
                        print,'Event #'+strtrim(id_i,2)+' removed [' + strtrim(n3,2)+ ']'
                       oplot,[tx,tx],[totsx, totsx],$
                        color=250,psym=4,thick=4
                        endif
                endif
             end
             else:loop=0b
             endcase
             !mouse.button = 0
        endwhile
        t0 = t1
      endfor
    loadct,0,/SILENT

    if (n3_i gt 0l) then begin
      t3_id = t3_id[1:n3_i]
      t3_time = t3_time[1:n3_i]
      t3_date  = t3_date[1:n3_i]
      t3_mean_freq = t3_mean_freq[1:n3_i]
      nt3_i = n_elements(t3_id)


      if (file_test(output_file) and not OVERWRITE) then begin
        message,/INFO,output_file + ' already exists!'
      endif else begin
        print,'Saving '+ output_file + '...'
        openw,lun,output_file,/GET_LUN
        printf,lun,'ID;DATE;SECONDS;MEAN_FREQ_MHZ'
        for k=0l,nt3_i-1l do printf,lun,t3_id[k], t3_date[k], t3_time[k], t3_mean_freq[k], format='(i4.4,";", i6, ";", i5, ";", f8.5)'
        close,lun
        free_lun,lun
      endelse
    endif


endfor



print,'Ending progam'
wdelete,window_set
END
