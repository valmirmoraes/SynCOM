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
;
; -------------------------------------------------------------------------------------------

pro corr, data, lag_peak=lag_peak, v=v, x=x
  
  if not keyword_Set(data) then begin
    name = "/Users/valmirmoraesfilho/Downloads/PUNCH project/L7/*.fts"

    data = open_file(name)
    
  endif


  sz = size(data, /dim)
  nx = sz[0]
  nt = sz[1]
  ny = sz[2]
  
  max_delay = 150.0 & lag = findgen(2L*max_delay+1)-1L*max_delay
  
; -------------------------------------------------------------------------------------------
; cross correlates using first frame in relation to others, at x degree angle
; 
; finds max for specific cross correlation and locates its lag peak
; 
; from lag calculates velocity 
; -------------------------------------------------------------------------------------------
;  
;  cc_peak = fltarr(nt)
;  lag_peak = fltarr(nt)
;  
;  v = fltarr(nt)
;  dXdT = (0.014*696000)/((findgen(nt)+1)*5*60.0)
;  
;  for t=x, nt-1 do begin
;    
;    ;bdata = back_removal(data, 5)
;    bdata = back_removal(data, x)
;    
;    cc = c_correlate(bdata[0,50:*], bdata[t,50:*], lag)
;;    cc = c_correlate(bdata[x,50:*], bdata[t,50:*], lag)
;
;    mx = max(abs(cc), ind)
;    cc_peak[t] = cc[ind]
;    lag_peak[t] = lag[ind]
;
;  endfor 
;  
;  v = lag_peak*dXdT
;  
; -------------------------------------------------------------------------------------------
;
; -------------------------------------------------------------------------------------------
; cross correlates using the 5th recursive frames, for x degree angle
;
; finds max for specific cross correlation and locates its lag peak
;
; from lag calculates velocity
; -------------------------------------------------------------------------------------------
;
; size of LAG/Velocity array comes from 395/5 = 79
; 
; Calculating velocity:
; distance: was taken from FITS header
; time: skipping 5 frames, 5 min for each frame.
  
  cc_peak = fltarr(79)
  lag_peak = fltarr(79)
  
  v = fltarr(79)
  dXdT = (0.014*696000)/(5*5*60.0)
  
  for t=0, 395-1,5 do begin
  
    bdata = back_removal(data, x)
  
    cc = c_correlate(bdata[t,50:*], bdata[t+5,50:*], lag)
    mx = max(abs(cc), ind)
    
    u=t/5
    cc_peak[u] = cc[ind]
    lag_peak[u] = lag[ind]
  
  endfor
  
  v = lag_peak*dXdT

; -------------------------------------------------------------------------------------------
;
; -------------------------------------------------------------------------------------------
; cross correlates using recursive frames, for all angles
;
; finds max for specific cross correlation and locates its lag peak
;
; from lag calculates velocity
; -------------------------------------------------------------------------------------------
;
;  cc_peak = fltarr(nx, nt)
;  lag_peak = fltarr(nx, nt)
;
;  for x=0, nx-1 do begin
;    
;    if x mod 5 eq 0 then print, x
;    
;    for t=0, nt-1 do begin
;      
;      bdata = back_removal(data, x)
;      cc = c_correlate(bdata[t-1,50:*],bdata[t,50:*], lag)
;
;      mx = max(abs(cc), ind)
;      cc_peak[x, t] = cc[ind]
;      lag_peak[x, t] = lag[ind]
;
;    endfor
;  endfor
;
; -------------------------------------------------------------------------------------------
;
;  dXdT = (0.014*696000)/((findgen(nt)+1)*5*60.0)
;  v = fltarr(nx,nt)
;  for i=0, nx-1 do v(x,*) = lag_peak(x,*)*dxdt

end

; -------------------------------------------------------------------------------------------
;
; -------------------------------------------------------------------------------------------

pro ROI,data,x

  img = reform(data(x,*,*))
  img2 = reform(data(x,*,*))

; -------------------------------------------------------------------------------------------
;  img_m = img & for y=0, 658 do img_m(*,y) = mean(img(*,y), /double)
;  img_s = img & for y=0, 658 do img_s(*,y) = stddev(img(*,y), /double)
;  img_ = img & for t=0, 398 do img_(t,*) = [img(t,*) - img_m(t,*)]/img_s(t,*)
;  
;  return, img_
;  
;  m_img = median(img,3)
;  tvscl, m_img

  img_roi = img[0:2,0:49]
  img_roi2 = img[0:2,0:49];1:50]
;  img_roi2 = img2[0:1,1:10]
  
  sz = size(img_roi, /dim)
  nx = sz[0] 
  ny = sz[1]
  
  L = 2
  img_roi = congrid(img_roi, nx*L, ny*L)
  img_roi2 = congrid(img_roi2, nx*L, ny*L)
  
  sz = size(img_roi, /dim)
  nx = sz[0]
  ny = sz[1]

  window, 0, xsize=nx, ysize=ny 
  tvscl, img_roi
  
  window, 1, xsize=nx, ysize=ny 
  tvscl, img_roi2

  cc = CORREL_IMAGES( img_roi, img_roi2, /monitor, /numpix)
  
  print, cc
  stop

end
