FUNCTION image2chain, image,$
                      end_pix=end_pix,$
                      start_pix=start_pix,$
                      X=X,Y=Y,$
                      error=error, VERBOSE=VERBOSE

;+
; NAME:
;		image2chain
;
; PURPOSE:
; 		Make the chain code of a closed contour 
;		provided in the input 2D binary array.
;
;
; CATEGORY:
;		Image processing
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>chaincode = image2chain(image)
;
; INPUTS:
;		image - 2D binary array containing the contour for which the chain
;		        code must be produced.
;               It is assumed that only contour's pixels
;               have values greater than zero.
;	
; OPTIONAL INPUTS:
;		end_pix - Vector containing the position [X,Y] in pixel
;			  at which the computation must be stopped.
;			  (by default, the computation stops when the 
;			  first pixel is encountered, or at the end of
;			  the contour if it is not closed.)
;			  is not closed).
;
; KEYWORD PARAMETERS:
;		/VERBOSE - Talkative mode.
;
; OUTPUTS:
;		chaincode - scalar of string type containing the chain code. 		
;
; OPTIONAL OUTPUTS:
;		start_pix - Returns a vector with the position [X,Y] of the
;		            starting pixel.
;		X         - Vector containing the chain code pixels coordinates along X-axis.
;		Y         - Vector containing the chain code pixels coordinates along Y-axis. 
;		Error	  - Equal to 1 if an error occurs, 0 else.
;		
; COMMON BLOCKS:
;		None.
; SIDE EFFECTS:
;		None.
; RESTRICTIONS:
;		None.
; CALL:
;		None.	
;
; EXAMPLE:
;		None.		
;
; MODIFICATION HISTORY:
;		Written by:     X.bonnin, 18-MAY-2011. 
;
;-
				  
error = 1b
if (n_params() lt 1) then begin
   message,/INFO,'Call is:'
   print,'chaincode = image2chain(image,end_pix=end_pix,start_pix=start_pix,$'
   print,'                         X=X,Y=Y,error=error,/VERBOSE)'
   return,''
endif
VERBOSE=keyword_set(VERBOSE)

n = size(image,/DIM)
if (n_elements(n) ne 2) then begin
   if (VERBOSE) then message,'Input image must have 2D dimensions!'
   return,''
endif
nx = n[0] & ny = n[1]

; Resize and Binarize the input image
offset=2l 
mask = bytarr(nx+2*offset,ny+2*offset)
mask[offset:nx-1l+offset,offset:ny-1l+offset] = byte(image)>(0b)<(1b)

ardir = [[-1,0],[-1,1],[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1]]
ccdir = [0,7,6,5,4,3,2,1]
ndir=8

where_pix = where(mask gt 0b,npix)
if (where_pix[0] eq -1) then begin
   if (VERBOSE) then message,/CONT,'All pixels are null!'
   return,''
endif

;Look for the starting pixel 
;(must be the uppermost,leftmost one)
ipix = array_indices(mask,where_pix)
ipix = ipix[*,sort(ipix[0,*])]
cc_y_pix = max(ipix[1,*],ix) 
cc_x_pix = ipix[0,ix]
start_pix = [cc_x_pix,cc_y_pix]
if not (keyword_set(end_pix)) then end_pix=start_pix else $
   end_pix = end_pix + offset

chaincode=''
loop=1b & xpix=cc_x_pix & ypix=cc_y_pix
while loop do begin

   for i=0,ndir-1 do begin
      x = xpix + ardir[0,i]  
      y = ypix + ardir[1,i]
      current_ccdir = ccdir[i]
      if (mask[x,y] eq 1b) then break
   endfor
   if (mask[x,y] ne 1b) and (i eq ndir) then return,''
   chaincode=chaincode+strtrim(current_ccdir,2)
   cc_x_pix = [cc_x_pix,x] & cc_y_pix = [cc_y_pix,y]
   if (x eq end_pix[0]) and (y eq end_pix[1]) then loop=0b
   xpix=x & ypix=y
   
   ; rotate direction vector
   ishift = (where(ccdir eq (current_ccdir+4) mod 8))[0]
   ardir = shift(ardir,[0,7-ishift])
   ccdir = shift(ccdir,7-ishift)
endwhile

X = cc_x_pix - offset
Y = cc_y_pix - offset
start_pix=start_pix-offset
end_pix=end_pix-offset

error = 0b
return,chaincode
END
