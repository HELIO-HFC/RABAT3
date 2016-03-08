PRO split_yyyymmdd,yyyymmdd,yyyy=yyyy,mm=mm,dd=dd $
					,help=help

IF keyword_set(help) THEN BEGIN
	message,/info,'Call is:'
	print,'split_yyyymmdd,yyyymmdd,yyyy=yyyy,mm=mm,dd=dd'
	return
ENDIF

IF keyword_set(yyyymmdd) THEN BEGIN
	ymd = strtrim(yyyymmdd,2)
	yyyy = strmid(ymd,0,4)
	mm = strmid(ymd,4,2)
	dd = strmid(ymd,6,2) 
ENDIF ELSE BEGIN
	IF NOT keyword_set(yyyy) THEN y = '' ELSE y = yyyy
	IF NOT keyword_set(mm) THEN m = '' ELSE m = mm
	IF NOT keyword_set(dd) THEN d = '' ELSE d = dd
	
	y = strtrim(string(y,format='(i4.4)'),2)
	m = strtrim(string(m,format='(i2.2)'),2)
	d = strtrim(string(d,format='(i2.2)'),2)

	yyyymmdd = strtrim(y+m+d,2)
ENDELSE

END