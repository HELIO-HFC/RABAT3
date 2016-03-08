; ==============================================================================
FUNCTION UNIQ_LIST, array,reverse_indices=reverse_indices
; ==============================================================================
; VERSION HISTORY
;
; V1.0
; creation of the function
; V1.1
; added REVERSE_INDICES keyword
;
; ==============================================================================
; USE
; 
; list = uniq_list(array)
; list is the list of unique values in array.
;
; KEYWORDS
;
; REVERSE_INDICES:
; * similar to the REVERSE_INDICES keyword in the IDL HISTOGRAM function.
; Set the REVERSE_INDICES keyword to a named variable, which will contain the
; list of inidices in the input array corresponding to each value of the output
; list.
; * Usage:
; list = uniq_list(array,Reverse_indices=Rev)
; * to get the elements of array where the value is list(i) do:
; array(rev(rev(i):rev(i+1)-1))
; 
; ==============================================================================

sorted_array = array(sort(array))
list = sorted_array(uniq(sorted_array))

narray = n_elements(array)
nlist = n_elements(list)

reverse_indices = lonarr(nlist+narray+1)
for ilist = 0l,nlist-1l do begin
  wlist = where(array eq list(ilist))
  nwlist = n_elements(wlist)
  reverse_indices(ilist+1) = reverse_indices(ilist)+nwlist
  reverse_indices(reverse_indices(ilist)+nlist+1:reverse_indices(ilist+1)+nlist) = wlist
endfor
reverse_indices(0:nlist) = reverse_indices(0:nlist)+nlist+1

return,list
end

