;PRO rabat3_merge,burst_indices,lvl_trust

;+
; NAME:
;	rabat3_merge
;
; PURPOSE:
; 	Merge close events.
;
; CATEGORY:
;	Feature recognition
;
; GROUP:
;	RABAT3
;
; CALLING SEQUENCE:
;	IDL>rabat3_merge,burst_indices,lvl_trust
;
; INPUTS:
;	burst_indices - Time subscripts of the detected bursts.
;
;       lvl_trust     - Corresponding detection level of trust.
;
; OPTIONAL INPUTS:
;	None.
;
;
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;	burst_indices - Merged subscripts
;
;       lvl_trust     - Merged level of trust.
;
; OPTIONAL OUTPUTS:
;       None.
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
;	Written by X.Bonnin,	26-JUL-2013.
;


nburst=n_elements(burst_indices)

; Regroup close events
iburst=-1l & lvl=1.0 & n=0l
for i=0,nburst-1 do begin

   iset=burst_indices[i] & j=i
   if (i lt nburst-1) then begin
      while (burst_indices[j+1]-burst_indices[j] eq 1l) do begin
         iset=[iset,burst_indices[j+1]]
         j++
         i=j
         if (j eq nburst-1l) then break
      endwhile
   endif

   iburst=[iburst,long(min(iset))] & n++
   lvl=[lvl,mean(lvl_trust[i:j])]
endfor
nburst=n
burst_indices=iburst[1:*]
lvl_trust=lvl[1:*]
n=0b & iburst=0b & lvl=0b

END
