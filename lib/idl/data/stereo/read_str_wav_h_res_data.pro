; file = '../STR_WAV/PRE/H_RES/STA_WAV_LFR_20061121.B3E'

PRO READ_STR_WAV_H_RES_DATA, file, data_l1, autodb=autodb, SILENT=SILENT

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
header  = {STR_WAV_H_RES_HEADER}

openr,lun,file,/get_lun,/swap_if_little_endian
while ~eof(lun) do begin
  nrecords += 1l
  readu,lun,record_size0
  ptr0 = (fstat(lun)).cur_ptr
  readu,lun,header
  nsamples += header.nfreq*header.nconfig
  
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
data_l1 = replicate({STR_WAV_H_RES_DATA_L1},nsamples)
start_sample_index = 0l

openr,lun,file,/get_lun,/swap_if_little_endian
while ~eof(lun) do begin

  nrecords += 1l
  readu,lun,record_size0
  ptr0 = (fstat(lun)).cur_ptr
  readu,lun,header

  PalkHz  = fltarr(header.nfreq)
  readu,lun, PalkHz
  
  Paltime = fltarr(header.npalcy,header.nconfig)
  readu,lun, Paltime

  Cag1    = fltarr(header.npalcy,header.nconfig)
  readu,lun, Cag1

  if header.ncag2 ne 0 then begin
    Cag2    = fltarr(header.ncag2,header.nconfig)
    readu,lun, Cag2
  endif
  
  if header.LoopA eq 0 then header.LoopA = 1 
  
  Auto1   = fltarr(header.nfreq,header.LoopA)
  readu,lun, Auto1

  if header.nauto2 ne 0 then begin
    Auto2   = fltarr(header.nauto2,header.LoopA)
    readu,lun, Auto2
  endif
  
  if header.LoopC ne 0 then begin
    CrosR   = fltarr(header.nfreq,header.LoopC)
    readu,lun, CrosR
    CrosI   = fltarr(header.nfreq,header.LoopC)
    readu,lun, CrosI
  endif

  ksamples = header.nconfig*header.nfreq
  
  data_amj   = header.Jamjcy(0)*10000l+header.Jamjcy(1)*100l+header.Jamjcy(2)
  data_sec   = rebin([double(header.Jhmscy(0)*3600l+header.Jhmscy(1)*60l+header.Jhmscy(2))+ $
               double(header.sfract)],ksamples)+double(rebin(paltime,ksamples))
  data_freq  = reform(rebin(reform(PalkHz,1,header.nfreq),header.nconfig,header.nfreq),$ 
               ksamples)
  data_dt    = header.msti
  data_ant   = reform(rebin(reform(header.iant12(0:header.nconfig-1),header.nconfig,1), $
               header.nconfig,header.nfreq),ksamples)
  data_agc1  = reform(transpose(rebin(reform(cag1,header.npalcy,header.nconfig), $
               header.nfreq,header.nconfig)),ksamples)
  if header.ncag2 ne 0 then begin
    data_agc2  = reform(transpose(rebin(reform(cag2,header.npalcy,header.nconfig), $
                 header.nfreq,header.nconfig)),ksamples)
  endif else begin
    data_agc2  = 0 
  endelse
  if header.loopA ne 0 then begin 
    data_auto1 = reform(transpose(rebin(reform(auto1,header.nfreq,header.nconfig), $
                 header.nfreq,header.nconfig)),ksamples)
    if header.nauto2 ne 0 then begin
      data_auto2 = reform(transpose(rebin(reform(auto2,header.nfreq,header.nconfig), $
                   header.nfreq,header.nconfig)),ksamples)
    endif else begin
      data_auto2 = 0
    endelse
  endif else begin
    data_auto1 = 0
    data_auto2 = 0
  endelse
  if header.LoopC ne 0 then begin 
    data_crosR = reform(transpose(rebin(reform(CrosR,header.nfreq,header.nconfig), $
                 header.nfreq,header.nconfig)),ksamples)
    data_crosI = reform(transpose(rebin(reform(CrosI,header.nfreq,header.nconfig), $
                 header.nfreq,header.nconfig)),ksamples)
  endif else begin
    data_crosR = 0
    data_crosI = 0
  endelse
  
  if (header.irad mod 10) le 3 then begin 
    data_fi = reform(rebin(reform(indgen(16),1,16),header.nconfig,16),ksamples) $
              + 1000*(header.irad mod 10)
  endif
  if (header.irad mod 10) gt 3 then data_fi = fix(data_freq-125.)/50 + 4000

  data_sweep = intarr(ksamples)+(nrecords-1l)
  
  fband = [0.225,0.900,3.600,12.50]
  data_df = fband(data_fi/1000-1)
  
  data_l1(start_sample_index:start_sample_index+ksamples-1).amj   = data_amj
  data_l1(start_sample_index:start_sample_index+ksamples-1).sec   = data_sec
  data_l1(start_sample_index:start_sample_index+ksamples-1).freq  = data_freq
  data_l1(start_sample_index:start_sample_index+ksamples-1).fi    = data_fi
  data_l1(start_sample_index:start_sample_index+ksamples-1).sweep = data_sweep
  data_l1(start_sample_index:start_sample_index+ksamples-1).dt    = data_dt
  data_l1(start_sample_index:start_sample_index+ksamples-1).df    = data_df
  data_l1(start_sample_index:start_sample_index+ksamples-1).ant   = data_ant
  data_l1(start_sample_index:start_sample_index+ksamples-1).agc1  = data_agc1
  data_l1(start_sample_index:start_sample_index+ksamples-1).agc2  = data_agc2
  data_l1(start_sample_index:start_sample_index+ksamples-1).auto1 = data_auto1 
  data_l1(start_sample_index:start_sample_index+ksamples-1).auto2 = data_auto2
  data_l1(start_sample_index:start_sample_index+ksamples-1).crosR = data_crosR
  data_l1(start_sample_index:start_sample_index+ksamples-1).crosI = data_crosI
  
  start_sample_index += ksamples
  
  ptr1 = (fstat(lun)).cur_ptr
  readu,lun,record_size1

  record_size2 = ptr1-ptr0
  if record_size1 ne record_size0 or record_size1 ne record_size2 then $
    message,'WARNING Checksum failed for record #'+string(nrecords)
  
endwhile

data_l1.num = lindgen(nsamples)

if keyword_set(autodb) then begin
  data_l1.agc1  = 10.*alog10(data_l1.agc1)
  data_l1.agc2  = 10.*alog10(data_l1.agc2)
  data_l1.auto1 = 10.*alog10(data_l1.auto1)
  data_l1.auto2 = 10.*alog10(data_l1.auto2)
endif

time1 = systime(/sec)
if (~SILENT) then begin
	message,/info,string(nrecords)+' records read in '+string(time1-time0)+' seconds.'
	message,/info,string(nsamples)+' samples stored.'
endif

close,lun
free_lun,lun

END
