function open_file, name
  
  ; NAME - location where FITS files are stored
  ; 
  ; name = "/Users/valmirmoraesfilho/Downloads/PUNCH project/L7/*.fts"
  
  file = file_search(name)
  
  img = readfits(file[0], /silent)
  sz = size(img, /dim)
  nx = sz[0] & ny = sz[1] & nt = n_elements(file)  
  
  data = fltarr(nx, nt, ny) & for i=0, nt-1 do data(*, i, *) = readfits(file[i], /silent)

; -------------------------------------------------------------------------------------------
; NEARST NEIGHBOUR AVERAGE: for pixels with min/max too large
; 
; some frames were presenting bad pixels (max or min out of the ordinary)
; -------------------------------------------------------------------------------------------
  data[2712,339,145] = float(1/2)*data[2712,338,144]+float(1/2)*data[2712,340,146]
  data[2718,339,145] = float(1/2)*data[2718,338,144]+float(1/2)*data[2718,340,146]
  data[2724,339,145] = float(1/2)*data[2724,338,144]+float(1/2)*data[2724,340,146]
  data[2726,339,145] = float(1/2)*data[2726,338,144]+float(1/2)*data[2726,340,146]
  data[2728,339,145] = float(1/2)*data[2728,338,144]+float(1/2)*data[2728,340,146]
  data[2729,339,145] = float(1/2)*data[2729,338,144]+float(1/2)*data[2729,340,146]
  data[2735,339,145] = float(1/2)*data[2735,338,144]+float(1/2)*data[2735,340,146]
  data[2737,339,145] = float(1/2)*data[2737,338,144]+float(1/2)*data[2737,340,146]
  data[2738,339,145] = float(1/2)*data[2738,338,144]+float(1/2)*data[2738,340,146]
  data[2739,339,145] = float(1/2)*data[2739,338,144]+float(1/2)*data[2739,340,146]
  data[2740,339,145] = float(1/2)*data[2740,338,144]+float(1/2)*data[2740,340,146]
  data[2741,339,145] = float(1/2)*data[2741,338,144]+float(1/2)*data[2741,340,146]
  data[2893,339,145] = float(1/2)*data[2893,338,144]+float(1/2)*data[2893,340,146]
; -------------------------------------------------------------------------------------------
  
  data = congrid(data, 360, nt, ny)
  
  return, data

end

; -------------------------------------------------------------------------------------------
; 
; -------------------------------------------------------------------------------------------

function back_removal, data, x
 
; ------------------------------------------------------------------------------------------- 
;  nw = 20 & n0 = 0 & n1 = n0 + nw - 1
;  sz = size(reform(data[x, n0:n1, *]), /dimension)
;  nt = sz[0]
;  ny = sz[1]
;  
;  data0 = reform(data[x,n0:n1,*])
;  
;  bg0 = dblarr(ny)
;  bdata = dblarr(nt,ny)
;  for y=0, ny-1 do bg0[y] = min(data0[*,y])
;  for t=0, nt-1 do bdata[t,*] = data0[t,*] - smooth(bg0,10)
;  
;  bdata[*,0] = max(bdata) & bdata[*,1] = min(bdata)
;  
;  return, bdata
;
; -------------------------------------------------------------------------------------------

  sz = size(reform(data[x, *, *]), /dimension)
;  sz = size(reform(data[x, 0:24, *]), /dimension)
  nt = sz[0]
  ny = sz[1]
  
  data0 = reform(data[x,*,*])
;  data0 = reform(data[x, 0:24, *]
;  data0 = median(reform(data[x,*,*]), 3)
  
  bg0 = dblarr(ny)
  bdata = dblarr(nt,ny)
  for y=0, ny-1 do bg0[y] = min(data0[*,y])
  for t=0, nt-1 do bdata[t,*] = data0[t,*] - smooth(bg0,10)
  
  bdata[*,0] = max(bdata) & bdata[*,1] = min(bdata)
  
  return, bdata
  
end

; -------------------------------------------------------------------------------------------
