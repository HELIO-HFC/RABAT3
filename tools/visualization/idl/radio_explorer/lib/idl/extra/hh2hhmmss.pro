;+
;
;hh2hhmmss
;
;Purpose : convertit heure decimale en heure:minute:seconds (string)
;
;Input : hh_in
;
;
;Output : 'hh:mm:ss' (defaut) ; heure décimale (reverse)
;
;
;
;-


function hh2hhmmss,hh_in $
                   ,rev=rev $
                   ,hh=hh,mm=mm,ss=ss $
                   ,error=error,help=help

On_error,2

IF n_params() lt 1 OR keyword_set(help) THEN BEGIN
    message,/info,'Call is : '
    print,'x=hh2hhmmss(hh_in $'
    print,'            ,hh=hh,mm=mm,ss=ss $'
    print,'            ,error=error)'
    return,0
ENDIF

error = 0

shh = size(hh_in)
CASE shh(n_elements(shh)-2) OF 
	7:BEGIN
   		hh_in = strtrim(hh_in,2)
    	hh = strmid(hh_in,0,2)
    	mm = strmid(hh_in,3,2)
		ss = strmid(hh_in,6)
		hh_out = double(hh) + double(mm)/60D + double(ss)/3600D
    	return,hh_out
	END	
	4:BEGIN
    	hh = strtrim(string(fix(hh_in),format='(i2.2)'),1)
    	mm0 = abs(fix(hh_in) - hh_in)*60D
    	mm = fix(mm0)
    	mm = strtrim(string(mm,format='(i2.2)'),1)
    	hh_out = hh+':'+mm
    	ss = fix(abs(mm0-mm)*60D)
    	ss = strtrim(string(ss,format='(i2.2)'),1)
    	hh_out = hh_out+':'+ss
    	return,hh_out
	END
	5:BEGIN
    	hh = strtrim(string(fix(hh_in),format='(i2.2)'),1)
    	mm0 = abs(fix(hh_in) - hh_in)*60D
    	mm = fix(mm0)
    	mm = strtrim(string(mm,format='(i2.2)'),1)
    	hh_out = hh+':'+mm
    	ss = fix(abs(mm0-mm)*60D)
    	ss = strtrim(string(ss,format='(i2.2)'),1)
    	hh_out = hh_out+':'+ss
    	return,hh_out
	END
	ELSE:BEGIN
		error=1
		return,0
	END
ENDCASE
END
