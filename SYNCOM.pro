;
function gaussian_wave, npixel=npixel, avr=avr, st_dev=st_dev

  ; ----------------- Defining Gaussian wave's dimensions and parameters: -----------------
  sz_npix = size(npixel,/dim)
  if (sz_npix ne 1) or (sz_npix eq 1) then begin
    ndim = 1
    nx = npixel[0] ; if only 1D, then npixel = nx
    avr = avr
    st_dev = st_dev
  endif
  if (sz_npix gt 1) then begin
    ndim = sz_npix
    npix = npixel
    avr = avr[*,0]
    st_dev = st_dev[*,0]
  endif

  ; ------------------------------- CASE for each dimension: -------------------------------
  case ndim of
    1: begin
      x = dindgen(nx)

      G = exp( -( x - avr[0] )^2/( 2*st_dev[0]^2 ) )

      return, g
    end
    2: begin
      nx = npix[0] & x = dindgen(nx)
      ny = npix[1] & y = dindgen(ny)

      G = fltarr(nx,ny)

      Gx = exp( -( x - nx/2.0 )^2/( 2*st_dev[0]^2 ) )
      Gy = exp( -( y - avr[1] )^2/( 2*st_dev[1]^2 ) )

      G = Gx # Gy
      
      for i=0, ny-1 do G[*,i] = shift( G[*,i], avr[0] - nx/2.0 )

      return, G
    end
  endcase
end

;
function parker_acc
  r_min = 4 & x_unit=0.014 & Rs=6.96e5

  n_col = 2
  close, 1
  openr, 1, "acceleration_Parker.txt"
  s=''
  n=0ll

  while not eof(1) do begin readf, 1, s & n=n+1 & endwhile & close, 1

  n_rows = n & data1 = fltarr(n_col, n_rows) & openr, 1, "velocity_Parker.txt"
  for i=0ll, n_rows-1 do begin
    readf, 1, s
    s_arr = strsplit(s, /extract)
    if n_elements(s_arr) eq 2 then data1[0:1, i] = float(s_arr)
  endfor
  close, 1

  n_rows = n & data2 = fltarr(n_col, n_rows) & openr, 1, "acceleration_Parker.txt"
  for i=0ll, n_rows-1 do begin
    readf, 1, s
    s_arr = strsplit(s, /extract)
    if n_elements(s_arr) eq 2 then data2[0:1, i] = float(s_arr)
  endfor

  parker = fltarr(3,n)
  for i=0,658 do begin
    parker[0,i]=(data1[0,i]/Rs/1000-4)
    parker[1,i]=data1[1,i]/1000
    parker[2,i]=data2[1,i]/1000
  endfor
  ;  close, 1

  acc = mean(data2[1,*])/1000.0

  return, acc
end

; Function produces a structure containing parameters used to create blobs
function param_struc, npixel=npixel, nt=nt, n_blobs=n_blobs, acc=acc, x_unit=x_unit, t_unit=t_unit
  t0=systime(/s)
  
  nx = npixel[0] & ny = npixel[1] ; image dimensions
  
  ; spacial and time units
  if not keyword_set(t_unit) then t_unit = 300.0    ; time cadance according to instrument in seconds
  if not keyword_set(x_unit) then x_unit = 9744.0   ; pixel size in km

  ; -------------------------------- Define Model Parameters --------------------------------  
  
  ; restores file containing frequency for each position angle
  restore, "/Users/vpereir1/Desktop/SynCOM_project/spectral_analysis.sav"
  frequency = reform(output[1,*])
  if nx ne 360.0 then frequency = congrid(frequency,nx)
  T_time = nt/( ( 1.0/frequency )/ t_unit )
  
  ; restores file containing mean radial velocity for each position angle
  restore, "/Users/vpereir1/Desktop/SynCOM_project/velocity.sav"
  if nx ne 360.0 then velocity = congrid(velocity,nx)
  for i=0, nx-1 do if velocity[i] eq 0.0 then velocity[i] = velocity[i-1]*0.5 + velocity[i+1]*0.5
  vr = smooth(velocity, 10) * t_unit/x_unit
  
  ; calculates Parker acceleration according to numerical simulation (in meters per second squared, m/s^2)
  if keyword_set(acc) then acc = parker_acc() else acc = 0.0 ;
  
  ; creates array of positions for each blob
  x0_arr = randomu(seed, n_blobs)*nx
  y0_arr = ny + ny/5*(randomu(seed, n_blobs) - 0.5)
  
  v_array = dblarr(nx,nt)
  for x=0, nx-1 do v_array[x,*] = vr[x]*findgen(nt) + acc*0.5*findgen(nt)^2.0
  
  ; empty arrays
  a_arr = fltarr(nx, 2.0*ny, nt) ; temporary array for each blob
  n_arr = fltarr(n_blobs,5)      ; array where initial values will be stored
  
  print, "Parameter structure: Done", systime(/s)-t0

  return, {a_arr:a_arr, n_arr:n_arr, npixel:npixel, nt:nt, n_blobs:n_blobs, x0_arr:x0_arr, y0_arr:y0_arr, $
              vr:vr, v_array:v_array, T_time:T_time, acc:acc, x_unit:x_unit, t_unit:t_unit}
end 

; Function produces an array containing propagating blobs: each blob takes about 8.5 seconds to produce
function model_engine, param=param, n_arr=n_arr;, n_blobs=n_blobs, npixel=npixel, nt=nt 
  t0 = systime(/s)
  
  ; ----------------------------------- Image Dimensions ----------------------------------
  
  nx      = param.npixel[0]
  ny      = param.npixel[1]     & ny_double = 2.0*ny 
  nt      = param.nt
  n_blobs = param.n_blobs
  a_arr   = param.a_arr         & a = a_arr
  n_arr   = param.n_arr
  
  ; -------------------------------- Define Model Settings --------------------------------

  ; initial parameters
  x0_arr = param.x0_arr         ; position angle array
  y0_arr = param.y0_arr         ; radial position array
  vr     = param.vr             ; radial velocity array (obtained from data)
  v_array= param.v_array
  T_time = param.T_time         ; time period array (obtained from data)
  acc    = param.acc            ; Parker mean acceleration (obtained from numerical simulation)
  x_unit = param.x_unit         ; time cadance according to instrument in seconds
  t_unit = param.t_unit         ; pixel size in km
 
;  ; empty arrays 
;  a_arr = fltarr(nx, 2.0*ny, nt) ; temporary array for each blob
;  a = a_arr
;  n_arr = fltarr(n_blobs,5)      ; array where initial values will be stored

  ; ------------------------------ Building Model Simulation ------------------------------
  ; loop through blob:
  for i=0, n_blobs-1 do begin
    print, "blob time: ", i, systime(/s)-t0;+strtrim(string(i, format="(F6.2)"),2)+, +strtrim(string(systime(/s)-t0, format="(F10.2)"),2)
    
    ; size of radial "perturbation" (in pixel units):
    L = T_time[x0_arr[i]] * vr[x0_arr[i]] ;* (t_unit/x_unit)

    ; saving initial parameters for each blob:
    n_arr[i,0] = x0_arr[i]
    n_arr[i,1] = y0_arr[i]
    n_arr[i,2] = vr[x0_arr[i]]
    n_arr[i,3] = T_time[x0_arr[i]]
    n_arr[i,4] = L & L_half = L*0.5 & L_minus = -L
    
    ; loop in time step for each blob:
    for s=0, nt-1 do begin
      a_arr[*,*,s] = gaussian_wave( npixel=[nx, ny_double], avr=[x0_arr[i], y0_arr[i]], st_dev = [L_half, L]  ) ; makes blob

;      a_arr[*,*,s] = temporary(a_arr[*,*,s]) + shift(reform(a_arr[*,*,s]), [0, L_minus]) ; adds new blob after each space "perturbation"
      a_arr[*,*,s] = a_arr[*,*,s] + shift(reform(a_arr[*,*,s]), [0, 2*L]) ; adds new blob after each space "perturbation"

      t =1.0*s ; time taken for blob to move
      a_arr[*,*,s] = shift(reform(a_arr[*,*,s]), [ 0, v_array[x0_arr[i], s] ] ) ; adding simple accelaration to each blob

    endfor
    
    a = temporary(a) + a_arr

  endfor
      
  print, "run time", systime(/s)-t0
  return, a[*,ny:2.0*ny-1,*]
end

; Function responsible to incrementing noise and brigthness behavior to an array
function add_feature, array, max_intensity=max_intensity, noise_level=noise_level
  t0 = systime(/s)

  sz_npix = size(array)
  nx = sz_npix[1] & ny = sz_npix[2] & nt = sz_npix[3]
  
  new_array = array > 0.

  case sz_npix[0] of
;    2: begin
;      nx = sz_npix[2] & nt = sz_npix[1] 
;
;      ; ---------------------------------- Adjustable Noise Level: ----------------------------------
;      ; adds random noise according to set percentage:
;      if not keyword_set(noise_level) then noise_level=0.0 else begin
;        noise_level = level*randomn(seed, nx, nt)
;
;        new_array = array + noise_level
;        print, "random noise added"
;      endelse
;
;      G_new = new_array
;      ; -------------------------------- Creating Intensity array: ----------------------------------
;      ; adds brightness behaviour:
;      if keyword_set(max_intensity) then begin
;;        G_new = new_array
;
;        R_initial = 4 & pix_size  = 0.014 & y0 = R_initial/pix_size
;        intensity = ( ( (y0 + findgen(ny) )/y0)*max_intensity )^(-3)
;        
;        for t=0, nt-1 do G_new[t,*] = G_new[t,*]*intensity
;        print, "brightness behavior added"
;      endif
;
;    end

    3: begin
;      nx = sz_npix[0] & ny = sz_npix[1] & nt = sz_npix[2]
      ; ---------------------------------- Adjustable Noise Level: ----------------------------------
      ; adds random noise according to set percentage:
      if keyword_set(noise_level) ne 0 then begin
        noise_array = new_array > 0 & level = noise_level/100.
        noise_arr = level*randomn(seed, nx, ny)
      
        for t=0, nt-1 do new_array[*,*,t] = reform(new_array[*,*,t]) + noise_arr
      
        print, "random noise added"
      endif
      ; ---------------------------------------------------------------------------------------------

      G_new = new_array[*,*,302:nt-1]
      sz_npix = size(G_new)
      nx = sz_npix[1] & ny = sz_npix[2] & nt = sz_npix[3]
      
      ; ------------------------------ Mimicing Brightness Behavior: --------------------------------
      ; adds brightness behaviour:
      if keyword_Set(max_intensity) ne 0 then begin
        R_initial = 4.0 & pix_size  = 0.014 & y0 = R_initial/pix_size
        intensity = (( (y0 + findgen(ny))/(ny+y0) ) )^(-3)
        
        for t=0, nt-1 do for x=0, nx-1 do G_new[x,*,t] = smooth(reform(G_new[x,*,t])*intensity*max_intensity, 10)
;        for x=0, nx-1 do begin
;          for t=0, nt-1 do G_new[x,t,*] = smooth( reform( new_array[x,*,t] ) * intensity * max_intensity, 10 )
;        endfor
;        
        print, "brightness behavior added"
      endif     

    end
  endcase
;  print, "run time", 

  
  return, G_new
end
