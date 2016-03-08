FUNCTION read_wind_waves_60s,file,header, $
   verbose=verbose,ndata=ndata,nsweep=nsweep,si_units=si_units, $
   irecord_offset=irecord_offset,isweep_offset=isweep_offset, help=help

data=0b & header=0b
if not (keyword_set(file)) or (keyword_set(help)) then begin
   message,/INFO,'Usage:'
   print,'data = read_wind_waves_60s(file,header, $'
   print,'                           irecord_offset=irecord_offset, $'
   print,'                           isweep_offset=isweep_offset, $'
   print,'                           /SI_UNITS,/NDATA,/NSWEEP,/VERBOSE,/HELP'
   return,0b
endif


if ~keyword_set(verbose) then verbose=0b else verbose=1b
if keyword_set(si_units) then begin 
  if verbose then message,/info,'Intensity output in V^2/Hz (SI units)'
  factor=1.e-12
endif else begin
  if verbose then message,/info,'Intensity output in microV^2/Hz'
  factor=1.
endelse

if keyword_set(irecord_offset) then irecord_offset = long(irecord_offset) else irecord_offset = 0l
if verbose then message,/info,'irecord offset ='+string(irecord_offset)

if keyword_set(isweep_offset) then isweep_offset = long(isweep_offset) else isweep_offset = 0l
if verbose then message,/info,'isweep offset = '+string(isweep_offset)

; temporary header format (used for date reading):
ccsds_date = {P_FIELD:0b, julian_day_b1:0b, julian_day_b2:0b, julian_day_b3:0b, msec_of_day:0L}

header_tmp = {ccsds_date:ccsds_date, $
              receiver_code:0, $
              julian_sec:0l, $
              calend_date:{calend_date}, $
              avg_duration:0, $
              iunit:0, $
              nfreq:0, $
              spacecraft_coord:{spacecraft_coord_gse}}

n_sweep = 0l
n_data  = 0l
rec_lng1 = 0l
rec_lng2 = 0l

; File overview (getting number of data samples)

openr,lun,file,/get_lun,/swap_if_little_endian

repeat begin
  n_sweep ++
  readu,lun,rec_lng1
  point_lun,-lun,lun_ptr
  readu,lun,header_tmp
  n_data += header_tmp.nfreq
  point_lun,lun,lun_ptr+rec_lng1
  readu,lun,rec_lng2
  if rec_lng1 ne rec_lng2 then stop
endrep until eof(lun)

close,lun
free_lun,lun

if verbose then message,file+':',/info
if verbose then message,string(format='(I6," sweeps, ",I6," data samples.")',n_sweep,n_data),/info



if keyword_set(ndata) then begin
  if verbose then message,'Returning number of data samples.',/info
  if keyword_set(nsweep) and verbose then message,'Ignoring /nsweep keyword.',/info
  return,n_data
endif else if keyword_set(nsweep) then begin
  if verbose then message,'Returning number of sweeps.',/info
  return,n_sweep
endif

if verbose then message,'Loading data.',/info

data = replicate({data_wind_waves_60s},n_data)
header = replicate({header_wind_waves_60s},n_sweep)

data.irecord = lindgen(n_data)+irecord_offset

warning = 0l

openr,lun,file,/get_lun,/swap_if_little_endian

for i=0l,n_sweep-1l do begin 
  readu,lun,rec_lng1
  readu,lun,header_tmp

  if verbose then message, string(format='("sweep #",I4.4," [",I4," bytes]")',i,rec_lng1),/info

  header(i).ccsds_date.P_field             = header_tmp.ccsds_date.P_Field

  julian_day = long(header_tmp.ccsds_date.julian_day_b1)*2l^16l+long(header_tmp.ccsds_date.julian_day_b2)*2l^8l+long(header_tmp.ccsds_date.julian_day_b3)
  julian_sec = julian_day*86400l + header_tmp.ccsds_date.msec_of_day/1000l

  if julian_sec ne header_tmp.julian_sec then begin
    warning ++
    if verbose then message,'/!\ Warning: date check did not pass /!\',/info
  endif

  caldat,julian_day+julday(01,01,1950,0,0,0),month,day,year

  header(i).ccsds_date.T_field.year        = year
  header(i).ccsds_date.T_field.month       = month
  header(i).ccsds_date.T_field.day         = day
  header(i).ccsds_date.T_field.hour        = header_tmp.ccsds_date.msec_of_day/1000l/3600l
  header(i).ccsds_date.T_field.minute      = (header_tmp.ccsds_date.msec_of_day/1000l mod 3600l)/60l
  header(i).ccsds_date.T_field.second      = (header_tmp.ccsds_date.msec_of_day/1000l mod 60l)
  header(i).ccsds_date.T_field.second_10_2 = (header_tmp.ccsds_date.msec_of_day mod 1000l)/10l
  header(i).ccsds_date.T_field.second_10_4 = (header_tmp.ccsds_date.msec_of_day mod 10l)*10l
  header(i).receiver_code                  = header_tmp.receiver_code
  header(i).julian_sec                     = double(julian_day) + double(header_tmp.ccsds_date.msec_of_day)/1.d3
  header(i).calend_date                    = header_tmp.calend_date
  header(i).avg_duration                   = header_tmp.avg_duration
  header(i).iunit                          = header_tmp.iunit
  header(i).nfreq                          = header_tmp.nfreq
  header(i).spacecraft_coord               = header_tmp.spacecraft_coord
  
  data(i*header(i).nfreq:(i+1l)*header(i).nfreq-1l).receiver_code = header_tmp.receiver_code
  data(i*header(i).nfreq:(i+1l)*header(i).nfreq-1l).seconds = double(header_tmp.ccsds_date.msec_of_day)/1.d3
  data(i*header(i).nfreq:(i+1l)*header(i).nfreq-1l).isweep   = i + irecord_offset
  
  tmp = fltarr(header(i).nfreq)
  readu,lun,tmp
  data(i*header(i).nfreq:(i+1l)*header(i).nfreq-1l).freq = tmp
  readu,lun,tmp
  data(i*header(i).nfreq:(i+1l)*header(i).nfreq-1l).intensity = tmp*factor
  
  readu,lun,rec_lng2
  if rec_lng2 ne rec_lng1 then stop

endfor

close,lun
free_lun,lun

if verbose then message,'Returning data.',/info
return,data
end
