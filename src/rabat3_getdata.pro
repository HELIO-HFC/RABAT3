FUNCTION rabat3_getdata,args,data_file, $
                        time=time,freq=freq, $
                        background=background, $
                        missing_pix=missing_pix, $
                        date_obs=date_obs, $
                        PREP=PREP, $
                        VERBOSE=VERBOSE

;+
; NAME:
;  rabat3_getdata
;
; PURPOSE:
;	Read a radio data file and returns data into a structure
;
; CATEGORY:
;	I/O
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>data = rabat3_getdata(args,data_file,time=time,freq=freq)
;
; INPUTS:
;        args - Structure containing the input parameters
;	data_file   - Scalar or vector of string type providing the
;         pathname of the data file to read.
;
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;        /PREP - Run pre-processings.
;        /VERBOSE - Talkative mode.
;
; OUTPUTS:
;	data - Structure containing the following data:
;                    observatory - Observatory name
;                    instrument - Instrument name
;                    receiver - receiver name
;                    date_obs - String containing the date of observation
;                    spectra - 2d array containing the intensity spectra
;                                     (i.e., the dynamical spectrum).
;                     time      - Time values in seconds along X-axis.
;                     freq       - Frequency values in MHz along Y-axis.
;                     background - background spectrum.
;                     missing_pix - Vector containing the subscripts of
;                                               missing pixels.
;                     scale - String indicating the intensity scale
;                                   ("db" or "linear")
;
; OPTIONAL OUTPUTS:
;         None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS/COMMENTS:
;	Only works with Wind/Waves/Rad1-Rad2 (GSFC 60sec averaged data),
;  STEREO/Waves/HFR (GSFC 60sec averaged data),
;  and Nancay/Decametric Array
;  data files (SYYMMDD.RT1)
;
; CALL:
;         stddev_filter
;         vect2arr
;         interp_missing
;         read_waves_gsfc_rad1
;	read_waves_gsfc_rad2
;	read_waves_gsfc_shfr
;	read_rawdam
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2010.
;
;-

;[1]:Initialization of the program
;[1]:=============================
;On_error,2
data = 0b
spectra=0b & rec=0b
time=0b & freq=0b
background=0b
missing_pix=0b
tcal=-1.0 & ncal=0
;Check the input parameters
if (n_params() lt 2) then begin
   message,/INFO,'Call is:'
   print,'data = rabat3_getdata(args,data_file, $'
   print,'                         /PREP, /VERBOSE)'
   return,0b
endif
PREP=keyword_set(PREP)
VERBOSE=keyword_set(VERBOSE)
obs=strlowcase(strtrim(args.observatory[0],2))
basename=file_basename(data_file)
;[1]:=============================

;[2]:Read data file
;[2]:==============
case obs of
   'wind':begin
      ; Time values (60s averaged)
      dt=60.0 & tmax=86400.0 & tmin=0.0
      nt=1440
      time=dt*findgen(nt) + tmin ; seconds
      dfr1=4.0 & nfr1=256 & fr1min=20.0
      dfr2=50.0 & nfr2=256 & fr2min=1075.0
      frad1=dfr1*findgen(nfr1) + fr1min ; kHz
      frad2=dfr2*findgen(nfr2) + fr2min ; kHz
      freq=[frad1,frad2]*1.0e-3 ; MHz

      ; Get RAD1 data
      date_obs=(strsplit(basename[0],'_.',/EXTRACT))[3] & miss_val=0.0
      where_r1=(where(strmatch(basename,'WIN_RAD1_60S_????????.B3E')))[0]
      if (where_r1 eq -1) then begin
         message,/CONT,'Wind/Waves/RAD1 data file missing!'
         return,0b
      endif
      data_r1=read_wind_waves_60s(data_file[where_r1],header_r1)

      s1=vect2arr(data_r1.intensity,data_r1.seconds,data_r1.freq,xout=time,yout=f1,/CLOSEST)

      nf1=n_elements(f1)
      if (nf1 lt nfr1) then begin
         j1=interpol(indgen(nf1),f1,frad1)
         s1=interpolate(s1,findgen(nt),j1,/GRID) ; use 1440x256 array
      endif

      ; Get RAD2 data
      where_r2=(where(strmatch(basename,'WIN_RAD2_60S_????????.B3E')))[0]
      if (where_r2 eq -1) then begin
         message,/CONT,'Wind/Waves/RAD2 data file missing!'
         return,0b
      endif
      data_r2=read_wind_waves_60s(data_file[where_r2],header_r2)

      s2=vect2arr(data_r2.intensity,data_r2.seconds,data_r2.freq,xout=time,yout=f2,/CLOSEST)

      nf2=n_elements(f2)
      if (nf2 lt nfr2) then begin
         j2=interpol(indgen(nf2),f2,frad2)
         s2=interpolate(s2,findgen(nt),j2,/GRID) ; use 1440x256 array
      endif

      ; Normalize to Rad1 level
      s2 = s2*(mean(s1[*,nfr1-1],/NAN)/mean(s2[*,0],/NAN))

      spectra=[[s1],[s2]]

      missing_pix=where(spectra le 0.0)

      background = get_background(spectra,0.1,nbins=100000,max=5)
      for j=0,n_elements(freq)-1 do spectra[*,j]=spectra[*,j]/background[j]

      data = {observatory:args.observatory, $
                   instrument:args.instrument, $
                   receiver:args.receiver, $
                   date_obs:date_obs, $
                   spectra:spectra, $
                   time_units:'seconds', $
                   time:time, $
                   freq_units:'MHz', $
                   freq:freq, $
                   background:background, $
                   missing_pix:missing_pix, $
                   scale:"linear",max_val:2}

   end
   'stereoa':begin
      date_obs=(strsplit(basename,'_',/EXTRACT))[2]
      stop,'to be done'
   end
   'stereob':begin
      date_obs=(strsplit(basename,'_',/EXTRACT))[2]
      stop,'to be done'
   end
   'nancay':begin
      date_obs=strmid(basename[0],1,6)
      data = read_rawdam(data_file[0],header=header, $
                                             sys=sys,filter=filter,reponse=reponse)
      if (size(data,/TNAME) ne 'STRUCT') then message,'Error reading ' + data_file[0]
      spectra = data.flux
      freq = data.frequency
      time = data.time

      missing_pix=where(finite(spectra) eq 0)
      spectra[missing_pix] = median(spectra)
      spectra = smooth(spectra,5)

      background = get_background(spectra,0.1,nbins=100000,max=5)
      for j=0,n_elements(freq)-1 do spectra[*,j]=spectra[*,j] - background[j]

      data = {observatory:args.observatory, $
                   instrument:args.instrument, $
                   receiver:args.receiver, $
                   date_obs:date_obs, $
                   spectra:spectra, $
                   time:time, $
                   time_units:'seconds', $
                   freq:freq, $
                   freq_units:'MHz', $
                   background:background, $
                   missing_pix:missing_pix, $
                   scale:"db",max_val:10}
   end
   else:begin
      message,/CONT,'Unknown observatory!'
      message,/CONT,'Must be wind, stereoa, stereob, or nancay!'
      return,0b
   end
endcase
;[2]:=========

if (PREP) then data.spectra=interp_missing(data.spectra,data.time,data.freq,missing_pix)

return,data
END
