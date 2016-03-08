PRO logging__define

;+
; NAME:
;	logging__define
;
; PURPOSE:
; 	Define logging object that manages message prints
;      into a log file and/or in the terminal.
;
; CATEGORY:
;	Object
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL> logObj = OBJ_NEW('logging')
;
; INPUTS:
;	None.
;
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	None.
;
; OPTIONAL OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; CALL:
;	None.
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin (CNRS, LESIA)
;
;-

void = {logging, $
	logger:'', $
	lun:0, $
	filename:'', $
	info:'', $
	warning:'', $
	error:'', $
	verbose:0}

END

FUNCTION logging::init, logger=logger
	if not (keyword_set(logger)) then logger = 'logging_' + strjoin(strsplit(self->get_date(),'-:T',/EXTRACT))
	defsysv, logger, exists=isLog
	if (isLog eq 1) then void = execute('self = ' + '!' + logger) $
	else begin
		self.logger = logger
	 	self.lun = 0
	  	self.filename = ''
	  	self.verbose = 0
		defsysv,'!'+logger,self
	endelse
	return,1
END

PRO logging::setup,info=info, warning=warning, error=error, VERBOSE=VERBOSE
	if (keyword_set(info)) then self.info = info
  	if (keyword_set(warning)) then self.warning = warning
  	if (keyword_set(error)) then self.error = error
  	self.verbose = VERBOSE
  	defsysv,'!'+self.logger,self
END

PRO logging::open, filename=filename

	if (keyword_set(filename)) then begin
		openw,lun,filename,/GET_LUN
		self.lun=lun
		self.filename = filename
		defsysv,'!'+self.logger,self
	endif

END

FUNCTION logging::isfile

if (file_test(self.filename)) then $
  return,1 $
  else return,0

END

PRO logging::info, msg

  root = self->parse_date(self.info)

if (self.lun gt 0) then printf, self.lun, root + msg
if (self.verbose gt 0) then print, root + msg

END

PRO logging::warning, msg

  root = self->parse_date(self.warning)

  if (self.lun gt 0) then printf, self.lun, root + msg
  if (self.verbose gt 0) then print, root + msg

END

PRO logging::error, msg, FORCE_STOP=FORCE_STOP

  root = self->parse_date(self.error)

  if (self.lun gt 0) then printf, self.lun, root + msg
  if (self.verbose gt 0) then print, root + msg
  if (keyword_set(FORCE_STOP)) then message,'Processing has been stop!'

END

PRO logging::close

	if (self.lun gt 0) then close, self.lun

END

FUNCTION logging::get_date, format=format
  if not (keyword_set(format)) then format = '%Y-%m-%DT%H:%M:%S'
  return, self->parse_date(format)
END

FUNCTION logging::parse_date, msg

  caldat, systime(/JULIAN), mm, dd, yyyy, hh, nn, ss
  mm = string(mm,format='(i2.2)')
  dd = string(dd,format='(i2.2)')
  yyyy = string(yyyy,format='(i4.4)')
  hh = string(hh,format='(i2.2)')
  nn = string(nn,format='(i2.2)')
  ss = string(ss,format='(i2.2)')

  msg = '-' + msg + '-'
  i = strsplit(msg,'%Y',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, yyyy)
  i = strsplit(msg,'%m',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, mm)
  i = strsplit(msg,'%D',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, dd)
  i = strsplit(msg,'%H',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, hh)
  i = strsplit(msg,'%M',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, mm)
  i = strsplit(msg,'%S',/REGEX, /EXTRACT)
  if (i[0] ne msg) then msg = strjoin(i, ss)

  msg = strmid(msg,1,strlen(msg)-2)
  return, msg
END