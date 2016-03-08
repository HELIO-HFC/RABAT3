; file = '../STR_WAV/PRE/AVERAGE/STA_WAV_LFR_60s_20061121.B3E'

PRO READ_STR_WAV_AVERAGE_DATA, file, data_l1,debug=debug,SILENT=SILENT

SILENT = keyword_set(SILENT)

; READING FILE IN 2 PASS
; 1st pass = scanning for number of records and total number of samples.
; 2nd pass = loading data into data_l1

time0 = systime(/sec)

; 1st PASS

nrecords = 0l
nsamples = 0l
record_size0 = 0l
record_size1 = 0l
record_size2 = 0l
header  = {STR_WAV_AVERAGE_HEADER}

openr,lun,file,/get_lun,/swap_if_little_endian
while ~eof(lun) do begin
  nrecords += 1l
  readu,lun,record_size0
  ptr0 = (fstat(lun)).cur_ptr
  readu,lun,header
  nsamples += header.nfreq
  
  point_lun,lun,ptr0+record_size0
  ptr1 = (fstat(lun)).cur_ptr
  readu,lun,record_size1
  record_size2 = ptr1-ptr0
  if record_size1 ne record_size0 or record_size1 ne record_size2 then $
    message,'WARNING Checksum failed for record #'+string(nrecords)
endwhile
close,lun
free_lun,lun

; 2nd PASS
  
nrecords = 0l
record_size0 = 0l
record_size1 = 0l
record_size2 = 0l
data_l1 = replicate({STR_WAV_AVERAGE_DATA_L1},nsamples)
start_sample_index = 0l

openr,lun,file,/get_lun,/swap_if_little_endian
while ~eof(lun) do begin

  nrecords += 1l
  readu,lun,record_size0
  ptr0 = (fstat(lun)).cur_ptr
  readu,lun,header

  if header.nfreq gt 0 then begin 
    Freq  = fltarr(header.nfreq)
    readu,lun, Freq
  
    Flux = fltarr(header.nfreq)
    readu,lun, Flux

    ksamples = header.nfreq
  
    data_amj   = header.Jamjcy(0)*10000l+header.Jamjcy(1)*100l+header.Jamjcy(2)
    data_sec   = double(header.Jhmscy(0)*3600l+header.Jhmscy(1)*60l+header.Jhmscy(2))
    data_sweep = intarr(ksamples)+(nrecords-1l)
    data_freq  = Freq
    data_flux  = Flux
    
    data_l1(start_sample_index:start_sample_index+ksamples-1).amj   = data_amj
    data_l1(start_sample_index:start_sample_index+ksamples-1).sec   = data_sec
    data_l1(start_sample_index:start_sample_index+ksamples-1).sweep = data_sweep
    data_l1(start_sample_index:start_sample_index+ksamples-1).freq  = data_freq
    data_l1(start_sample_index:start_sample_index+ksamples-1).flux  = data_flux
  
    start_sample_index += ksamples
    
  endif 
  
  ptr1 = (fstat(lun)).cur_ptr
  readu,lun,record_size1

  record_size2 = ptr1-ptr0
  if record_size1 ne record_size0 or record_size1 ne record_size2 then $
    message,'WARNING Checksum failed for record #'+string(nrecords)
  
  if keyword_set(debug) then stop
endwhile

data_l1.num = lindgen(nsamples)

time1 = systime(/sec)
if (~SILENT) then begin
	message,/info,string(nrecords)+' records read in '+string(time1-time0)+' seconds.'
	message,/info,string(nsamples)+' samples stored.'
endif

close,lun
free_lun,lun

END
