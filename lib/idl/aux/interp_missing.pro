FUNCTION interp_missing,array,x,y, missing_pix, $
                                                xout=xout, $
                                                yout=yout, $
                                                TRIGRID=TRIGRID

interp_array=0b
if (n_params() lt 3) then begin
   message,/INFO,'Call is:'
   print,'interp_array=interp_missing(array,x,y,missing_pix, $'
   print,'                                                    xout=xout,yout=yout, $''
   print,'                                                    /TRIGRID)'
   return,0b
endif
TRIGRID = keyword_set(TRIGRID)

sz=size(array)
if (sz[0] ne 2) then message,'Input array must have 2 dimensions!'
nx=n_elements(x)
if (sz[1] ne nx) then message,'Incorrect number of elements along first dimension!'
ny=n_elements(y)
if (sz[2] ne ny) then message,'Incorrect number of elements along second dimension!'
n=nx*ny

if not keyword_set(Xout) then Xout=X[uniq(X,sort(X))]
if not keyword_set(Yout) then Yout=Y[uniq(Y,sort(Y))]

Z = array
where_missing = missing_pix
nmiss = n_elements(where_missing)
if (where_missing[0] eq -1) then return, array
Z[where_missing] = !values.f_nan

where_not_missing = where(finite(Z) eq 1)
if (where_not_missing[0] eq -1) then message,'There is no valid pixel!'

if (TRIGRID) then begin
    Zin=reform(Z,n)
    Zin=Zin[where_not_missing]
    Xin=(reform(rebin(X,nx,ny),n))[where_not_missing]
    Yin=(reform(transpose(rebin(Y,ny,nx)),n))[where_not_missing]
    triangulate,Xin,Yin,tr,b
    interp_array=trigrid(Xin,Yin,Zin,tr,xout=xout,yout=yout)
endif else begin
    z_x = Z & z_y = Z
    for i=0l,nx-1l do begin
      where_valid = where(finite(Z[i,*]) eq 1)
      if (where_valid[0] ne -1) then z_x[i,*] = interpol(Z[i,where_valid], Y[where_valid], Y)
    endfor
    Xout = X
    for j=0l,ny-1l do begin
      where_valid = where(finite(Z[*,j]) eq 1)
      if (where_valid[0] ne -1) then z_y[*,j] = interpol(Z[where_valid,j], X[where_valid], X)
    endfor
    Yout = Y

    interp_array = array
    interp_array[where_missing] = 0.5*(z_x[where_missing] + z_y[where_missing])
endelse

return,interp_array
END
