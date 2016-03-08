FUNCTION read_rabat3_train_stats,file,header

delimiter='|'

data=0b & header=''
if not (keyword_set(file)) then begin
   message,/INFO,'Call is:'
   print,'data = read_rabat3_train_stats(file,header)'
   return,0b
endif

if not (file_test(file)) then begin
   message,/CONT,file+' does not exist!'
   return,0b
endif

nline = file_lines(file)
openr,lun,file,/GET_LUN
readf,lun,header
col = strsplit(header,delimiter,/EXTRACT)
ncol = n_elements(col)
nline--
date = strarr(nline)
good = -1.0 & miss = -1.0 & bad = -1.0
for i=0l,nline-1l do begin
   line_i=''
   readf,lun,line_i
   line_i = strtrim(strsplit(line_i,delimiter,/EXTRACT,/PRESERVE_NULL),2)
   if (n_elements(line_i) ne ncol) then begin
      message,/CONT,'Cannot read line '+strtrim(i+1l,2)+'!'
      return,0b
   endif
   date[i] = line_i[0]
   if (line_i[1] ne '') then good = [good,float(strsplit(line_i[1],',',/EXTRACT))]
   if (line_i[2] ne '') then bad = [bad,float(strsplit(line_i[2],',',/EXTRACT))]
   if (line_i[3] ne '') then miss = [miss,float(strsplit(line_i[3],',',/EXTRACT))]
endfor
close,lun
free_lun,lun
if (n_elements(good) gt 1) then good=good[1:*]
if (n_elements(bad) gt 1) then bad=bad[1:*]
if (n_elements(miss) gt 1) then miss=miss[1:*]

data = {good:good,bad:bad,miss:miss}
return,data
END
