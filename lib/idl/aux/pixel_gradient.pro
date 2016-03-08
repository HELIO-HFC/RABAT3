PRO pixel_gradient,array,grad_x,grad_y


; Pad array
img = pad_array(array, /silent)

sz = size(img)
if (sz[0] ne 2) then message,'Input array must have 2 dimensions!'
nx = sz[1] & ny = sz[2]
n = nx*ny

offsets = [ -nx-1l, -nx, -nx+1l, -1l, 0l, 1l, nx-1l, nx, nx+1l]

grad_x=fltarr(nx,ny) & grad_y=fltarr(nx,ny)
for i=0l,n-nx-2l do begin
   li = i/nx
   if (li eq 0l) then continue
   if (i ge li*nx-1l) and (i le li*nx) then continue
   
   pi = fltarr(9)
   for j=0,8 do pi[j] = img[i + offsets[j]]

   grad_x[i] = (pi[6] + 2.0*pi[7] + pi[8]) - (pi[0] + 2.0*pi[1] + pi[2])
   grad_y[i] = (pi[2] + 2.0*pi[5] + pi[8]) - (pi[0] + 2.0*pi[3] + pi[6])
endfor

grad_x  =  grad_x(1:nx-2,1:ny-2)
grad_y  =  grad_y(1:nx-2,1:ny-2)

END
