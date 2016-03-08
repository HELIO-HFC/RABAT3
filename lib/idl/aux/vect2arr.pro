FUNCTION vect2arr,Z,X,Y, $
                  Xout=Xout,Yout=Yout, $
                  nx=nx,ny=ny,dx=dx,dy=dy, $
                  count=count,REGULAR=REGULAR, $
                  CLOSEST_NEIGHBOR=CLOSEST_NEIGHBOR

;+
; NAME:
;  vect2arr
;
; PURPOSE:
;  Create a 2D array using X and Y vectors, 
;  then fill it with the values of 
;  a corresponding Z vector.     
;
; CATEGORY:
;  Matrix
;
; GROUP:
;  None.
;
; CALLING SEQUENCE:
;  IDL>Arr=vect2arr(Z,X,Y)
;
; INPUTS:
;  Z - Vector of N elements used to fill the 2D array [Nx,Ny].
;  X - Vector of N elements containing the corresponding X-axis values.
;  Y - Vector of N elements containing the corresponding Y-axis values.
;  
; OPTIONAL INPUTS:
;  Xout - Vector of Nx elements containing the output values along the X-axis.
;         If Xout is not provided, then use Xout=X[uniq(X,sort(X))].
;  Yout - Vector of Ny elements containing the output valus along the Y-axis.
;         If Yout is not provided, then use Yout=Y[uniq(Y,sort(Y))].
;  dx   - Scale along the X-axis.
;  dy   - Scale along the Y-axis.
;
; KEYWORD PARAMETERS:
;  /REGULAR          - Specify that dx and dy are constant (i.e., case of regular grid). 
;                      This allows to use a faster algorithm.
;  /CLOSEST_NEIGHBOR - To fill the location [Xout,Yout], use the closest neighbor [X,Y] Z value.
;
; OUTPUTS:
;  Arr - 2D array containing the Z vector values.  
;        If more than one Z value exist for a given [Xout,Yout] location,
;        then use the average value.  
;
; OPTIONAL OUTPUTS:
;  nX    - Number of elements along X-axis.
;  nY    - Number of elements along Y-axis.
;  count - 2d histogram [Nx,Ny] providing the number of Z values
;          used to fill each [Xout,Yout] location.
;
; COMMON BLOCKS:     
;  None.       
;
; SIDE EFFECTS:
;  None.    
;
; RESTRICTIONS/COMMENTS:
;  None.
;     
; CALL:
;  None.
;
; EXAMPLE:
;  None.
;
; MODIFICATION HISTORY:
;  Written by X.Bonnin, 26-JUL-2006. 
;                                
;-


Xout=0b & Yout=0b & Arr=0b & count=0b
if (n_params() lt 3) then begin
   message,/info,'Usage:'
   print,'Arr = vect2arr(Z,X,Y, $'
   print,'               Xout=Xout,Yout=Yout, $'
   print,'               nx=nx,ny=ny,dx=dx,dy=dy, $'
   print,'               count=count,/REGULAR, $'
   print,'               /CLOSEST_NEIGHBOR)'
   return,0b
endif
REGULAR=keyword_set(REGULAR)
CLOSEST=keyword_set(CLOSEST_NEIGHBOR)

if (not keyword_set(Xout)) then Xout = X[uniq(X,sort(X))]
if (not keyword_set(Yout)) then Yout = Y[uniq(Y,sort(Y))]

if not (keyword_set(dx)) then dx = deriv(Xout)
if not (keyword_set(dy)) then dy = deriv(Yout)

n = n_elements(Z)
nX = n_elements(Xout)
nY = n_elements(Yout)

Arr = fltarr(nX,nY)
count = fltarr(nX,nY)
if (REGULAR) then begin
   Xmin=min(Xout,/NAN)
   Ymin=min(Yout,/NAN)

   for i=0L,n-1 do begin
      ix = round((X[i] - Xmin)/float(dx[0]))  
      iy = round((Y[i] - Ymin)/float(dy[0]))

      if (ix lt 0l) or (ix ge nX) then continue
      if (iy lt 0l) or (iy ge nY) then continue
   
      Arr[ix,iy] = Arr[ix,iy] + Z[i]
      count[ix,iy] = count[ix,iy] + 1.0
   endfor
endif else if (CLOSEST) then begin
   for i=0L,n-1 do begin
      Xmin=min(abs(X[i]-Xout),ix)
      Ymin=min(abs(Y[i]-Yout),iy)

      Arr[ix,iy] = Arr[ix,iy] + Z[i]
      count[ix,iy] = count[ix,iy] + 1.0
   endfor
endif else begin
   for i=0L,n-1 do begin
      ix = (where(X(i) ge Xout-0.5*dx and X(i) lt Xout + 0.5*dx))(0)
      iy = (where(Y(i) ge Yout-0.5*dy and Y(i) lt Yout + 0.5*dy))(0)
      if (ix eq -1) or (iy eq -1) then continue

   
      Arr[ix,iy] = Arr[ix,iy] + Z[i]
      count[ix,iy] = count[ix,iy] + 1.0
   endfor

endelse
where_ok=where(count gt 0.0)
if (where_ok[0] ne -1) then Arr[where_ok]=Arr[where_ok]/count[where_ok]

return,Arr
end
