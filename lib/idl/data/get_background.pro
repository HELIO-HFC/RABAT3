FUNCTION get_background,intensity,q, $
                        _EXTRA=EXTRA

;+
; NAME:
;	get_background
;
; PURPOSE:
;	Compute the background spectrum 
;       from an intensity 2d array.
;       (see Zarka et al., SSR, 2004 for
;        more details about the method).  		
;
; CATEGORY:
;	radio
;
; GROUP:
;	None.
;
; CALLING SEQUENCE:
;	IDL>bg = get_background(intensity,q)
;
; INPUTS:
;	intensity - 2d array containing the radio intensity 
;               as a function of time and frequency.
;   q         - Scalar of float type containing the 
;               quantile value between 0 and 1. 
;               This value will be
;               used to determinate the background level
;               on the intensity histograms.
;               Default is 0.05.
;
; OPTIONAL INPUTS:
;	See get_quantile.pro optional inputs.
;
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;	bg - vector containing the background spectrum.		
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
; RESTRICTIONS/COMMENTS:
;	None.
;		
; CALL:
;	get_quantile
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2010.


if not (keyword_set(intensity)) then begin
   message,/INFO,'Usage:'
   print,'bg = get_background(intensity,q,_EXTRA=EXTRA)'
   return,0b
endif

sz=size(intensity)
if (sz[0] ne 2) then message,/CONT,'input intensity must be a 2d array!'
if not (keyword_set(q)) then q = 0.05
nx = sz[1]
ny = sz[2]

bg = fltarr(ny)
for j=0l, ny-1l do bg[j] = get_quantile(intensity[*,j],q,_EXTRA=EXTRA)

return, bg
END
