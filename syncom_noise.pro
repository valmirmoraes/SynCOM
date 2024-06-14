PRO SYNCOM_noise, ModPramsStruct, img, new_img;, noise_level, max_intensity
  t0 = systime(/s)
  
  NX            = ModPramsStruct.SYNCOM_NX
  NY            = ModPramsStruct.SYNCOM_NY
  noise_level   = ModPramsStruct.SYNCOM_noise_level
  max_intensity = ModPramsStruct.SYNCOM_max_intensity
  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN

  new_img = img > 0.

  ; ---------------------------------- Adjustable Noise Level: ----------------------------------
  ; adds random noise according to set percentage:
  if n_elements(noise_level) ne 0. then begin
    noise_array = new_img > 0. & level = noise_level/100.
    noise_array = level*randomn(seed, nx, ny)

    new_img = img + noise_array

    print, "random noise added"
  endif
  ; ---------------------------------------------------------------------------------------------


  ; ------------------------------ Mimicing Brightness Behavior: --------------------------------
  ; adds brightness behaviour:
  if n_elements(max_intensity) ne 0. then begin
    pix_size  = 0.014 & y0 = initial_R_sun/pix_size
    
    intensity = (( (y0 + findgen(ny))/(ny+y0) ) )^(-3.)

    for x=0, nx-1 do new_img[x,*] = smooth(reform(new_img[x,*])*intensity*max_intensity, 10)

    print, "brightness behavior added"
  endif    
  
  print, "run time", systime(/s)-t0
END


PRO SYNCOM_normalize, ModPramsStruct, data, noise_data;, noise_level, max_intensity
  t0 = systime(/s)

  NX            = ModPramsStruct.SYNCOM_NX
  NY            = ModPramsStruct.SYNCOM_NY
  noise_level   = ModPramsStruct.SYNCOM_noise_level
;  max_intensity = ModPramsStruct.SYNCOM_max_intensity
;  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN
  
  if n_elements(noise_data) eq 0. then noise_data = data*0.
  restore,'/Users/vpereir1/Desktop/SynCOM_project/normalize.sav'
  
  for time_t=0, n_elements(data[0,0,*])-1 do begin    
    img = reform(data[*,*,time_t])

    new_img = NORMALIZE_array(ModPramsStruct, img, time_t, mean2,std2, noise_level)
    
    noise_data[*,*,time_t] = new_img
  endfor

  print, "run time", systime(/s)-t0

END

function NORMALIZE_array, ModPramsStruct, img,time_t, mean1, std1,noise_level
  t0 = systime(/s)
  
  new_img = img*0.
  NX            = ModPramsStruct.SYNCOM_NX
  NY            = ModPramsStruct.SYNCOM_NY
  noise_level   = ModPramsStruct.SYNCOM_noise_level

  for x=0, nx-1 do for y=0,ny-1 do new_img[x,y] = (reform(img[x,y])+mean1[x,y]) * std1[x,y]

  ; ---------------------------------- Adjustable Noise Level: ----------------------------------
  ; adds random noise according to set percentage:
  if n_elements(noise_level) ne 0. then begin
    noise_array = new_img > 0. & level = noise_level/100.
    noise_array = level*randomn(seed, nx, ny)

    img_ = new_img > 0.
    img_ = new_img + noise_array
  endif

  print, "run time",time_t, systime(/s)-t0
  
  return, img_ > 0.
end
