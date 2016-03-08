FUNCTION rabat3_thresholding, x, threshold, $
                              nburst=nburst, $
                              GET_MAX=GET_MAX, $
                              GET_MID=GET_MID

;+
; NAME:
;	rabat3_thresholding
;
; PURPOSE:
; 	This function performs a thresholding method
;       on the input x vector, and returns
;       the indices along time axis of samples below the threshold.
;
; CATEGORY:
;	Feature recognition
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>time_indices=rabat3_thresholding(x,threshold)
;
; INPUTS:
;	x                 - Vector containing the values
;                               to threshold.
;	threshold  - Threshold value.
;
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	/GET_MAX - Regroup neighboor points which are
;                                 above threshold, and returns the subscript
;                                 of the maximal value.
;        /GET_MID - Regroup neighboor points which are
;                                 above threshold, and returns the
;                                 middle subscript.
;
; OUTPUTS:
;	time_indices - Vector containing the subscript(s) of
;                      the time samples for which lsr is below the threshold.
;
; OPTIONAL OUTPUTS:
;       nburst - Number of bursts.
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
;       None.
;
; EXAMPLE:
;	None.
;
; MODIFICATION HISTORY:
;	Written by X.Bonnin,	26-JUL-2010.
;-

burst_indices=-1 & nburst=0l
if (n_params() lt 2) then begin
   message,/CONT,'Call is:'
   print,'burst_indices = rabat3_thresholding(x,threshold, $'
   print,'                                    nburst=nburst, $'
   print,'                                    /GET_MAX, /GET_MID)'
   return,-1
endif
GET_MAX=keyword_set(GET_MAX)
GET_MID=keyword_set(GET_MID)

; Keep samples for which
; the lsr are below the threshold
n=n_elements(x)
w=where(x gt threshold,nev)
if (GET_MAX + GET_MID eq 0) then return,w
if (w[0] eq -1) then return,-1

; Regroup events which are close in time
iburst=-1l & nburst=0l
for i=0,nev-1 do begin

   iset=w[i] & j=i
   if (i lt nev-1) then begin
      while (w[j+1]-w[j] eq 1l) do begin
         iset=[iset,w[j+1]]
         j++
         i=j
         if (j eq nev-1l) then break
      endwhile
   endif

   if (GET_MAX) then $
      xm=max(x[iset],iset_m,/NAN) $
   else iset_m = iset[0.5*(n_elements(iset)-1)]
   iburst=[iburst,iset[iset_m]] & nburst++
endfor
if (nburst eq 0l) then return,-1
burst_indices=iburst[1:*]

return,burst_indices
END
