PRO plot_time_series,intensity,time,frequency $
                    ,trange=trange,frange=frange $
                    ,freqlist = freqlist $
                    ,xtitle=xtitle,ytitle=ytitle,title=title $
                    ,thick=thick $
                    ,max_val=max_val,min_val=min_val $
                    ,window_set=window_set $
                    ,position=position $
                    ,DB=DB


;+
; NAME:
;       plot_time_series
;
; PURPOSE:
;       plot time series for several frequencies.
;
; AUTHOR:
;       X. Bonnin
;
; CATEGORY:
;       Graphics.
;
; CALLING SEQUENCE:
;       plot_time_series,intensity,time,frequency
;
; INPUTS:
;       intensity - Vector or 2d array containing the intensity values to plot.
;       time      - Vector containing the time values.
;       frequency - Vector containing the frequency values.
;
; OPTIONAL INPUTS:
;       trange      - 2 elements vector containing the time range along X-axis.
;       frange      - 2 elements vector containing the frequency range along Y-axis.
;       freqlist    - Vector providing the list of frequencies to plot.
;       xtitle      - Scalar of string type containing the title of the x-axis.
;       ytitle      - Scalar of string type containing the title of the y-axis.
;       title       - Scalar of string type containing the main title of the plot.
;       thick       - Thick of plot.
;       min_val     - Scalar containing the minimum intensity value. 
;       max_val     - Scalar containing the maximum intensity value.
;       window_set  - Scalar containing the index of the open window to use.
;       position    - Vector containing the position of the plot in the window 
;                     (in normal coordinates system).
;
; KEYWORD PARAMETERS:
;       /DB             - Plot intensity in dB.
;       
;
; OUTPUTS:
;       None.
;
; OPTIONAL OUTPUTS:
;       None.
;
; CALL:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       None.
;
; EXAMPLE:
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by X.Bonnin, 10-May-2005.
;       
;       29-NOV-2013, X.Bonnin:  renamed flux to intensity.
;                               removed /NOERASE keyword.
;
;-

if n_params() lt 3 then begin
    message,/info,'Call is:'
    print,'plot_time_series,intensity,time ,frequency $'
    print,'                ,trange=trange,frange=frange $'
    print,'                ,freqlist=freqlist $ '
    print,'                ,xtitle=xtitle,ytitle=ytitle,title=title $'
    print,'                ,window_set=window_set,thick=thick $'
    print,'                ,max_val=max_val,min_val=min_val $'
    print,'                ,position=position '
    print,'                ,/DB          '
    return
endif
DB=keyword_set(DB)
YLOG=keyword_set(YLOG)


if not (!D.NAME eq 'PS') then begin
    if not keyword_set(window_set) then begin
        device,get_screen_size=screensize
        wxsize = screensize(0)*0.5 & wysize = screensize(1)*0.8 
        window,/free,xsize=wxsize,ysize=wysize
    endif else begin
        wset,window_set
    endelse
    device,decomposed=0
endif 

IF NOT keyword_set(title) THEN title = ''

sz = size(intensity)
n=n_elements(intensity)
CASE sz(0) OF
	1:BEGIN
		s = intensity
        t = time
        f = frequency
	END
	2:BEGIN
        nt = sz[1]
        nf = sz[2]
		s=reform(intensity,n)
        t=reform(rebin(time,nt,nf),n)
        f=reform(transpose(rebin(frequency,nf,nt)),n)
	END
	ELSE:return
ENDCASE



IF keyword_set(frange) THEN BEGIN
    zf = where(f ge frange(0) and f le frange(1),nf)
    IF zf(0) EQ -1 THEN BEGIN
        message,/CONT,'>> No value found in frange <<'
        RETURN
    ENDIF
	f = f(zf)
	s = s(zf)
    t = t(zf)
ENDIF
f0 = min(f) & f1 = max(f)


IF NOT keyword_set(freqlist) THEN freqlist=f[uniq(f,sort(f))] 
nfreq=n_elements(freqlist)

;plot position
IF NOT keyword_set(position) THEN position = [0.15, 0.05, 0.90, 0.95]
xsize = (position[2] - position[0]) * !D.X_Vsize
ysize = (position[3] - position[1]) * !D.Y_Vsize
dy = (position[3] - position[1])/(nfreq)

IF (DB) THEN s = 10.*alog10(s > 1.0)

IF NOT keyword_set(max_val) THEN max_val = max(s,/NAN)
IF NOT keyword_set(min_val) THEN min_val = min(s,/NAN)

wf0 = where(f eq freqlist[0])

plot,t(wf0),s(wf0),thick=thick,ycharsize=0.75 $
    	,position=[position(0),position(1) $
    	,position(2),position(1)+dy] $
    	,xs=8+1,/ys, /nodata $
    	,xtitle=xtitle,ytitle=ytitle $
    	,xrange=trange,yrange=[min_val,max_val]

plot,t(wf0),s(wf0),thick=thick,ycharsize=0.75 $
    	,position=[position(0),position(1) $
    	,position(2),position(1)+dy] $
    	,/noerase,xs=8+1,/ys $
    	,xtitle=xtitle,ytitle=ytitle $
    	,xrange=trange,yrange=[min_val,max_val]
    	
xyouts,position(2) + 0.02,position(1)+(dy/2.),/normal $
		,strtrim(freqlist(0),2)


FOR j=1,nfreq-1 DO BEGIN
    wfj=where(f eq freqlist[j])
    if (wfj[0] eq -1) then begin
        message,/INFO,'No value for frequency '+strtrim(freqlist[j],2)
        continue
    endif
	IF j EQ nfreq-1 THEN title_j = title ELSE title_j = ''
	
    plot,t[wfj],s(wfj),thick=thick,ycharsize=0.75 $
    	,position=[position(0),position(1)+j*dy $
    	,position(2),position(1)+(j+1)*dy] $
    	,/noerase,xs=4+1,/ys $
    	,xrange=trange,yrange=[min_val,max_val] $
    	,title=title_j
    	
	xyouts,position(2) + 0.02,position(1)+dy*(2.*j + 1)/2.,/normal $
			,strtrim(freqlist(j),2)

ENDFOR

END
