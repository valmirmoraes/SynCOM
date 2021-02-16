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
