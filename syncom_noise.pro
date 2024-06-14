PRO SYNCOM_noise, ModPramsStruct, img, new_img, rect_img, rectangular=rectangular, noise_add=noise_add, luminosity_add=luminosity_add 
  ;+
  ; Name:
  ;      SYNCOM_noise
  ;
  ; Purpose:
  ;      Adds random noise and mimics brightness behavior to the input image based on model parameters.
  ;      Optionally, converts the image into rectangular coordinates.
  ;
  ; Calling Sequence:
  ;      SYNCOM_noise, ModPramsStruct, img, new_img, rect_img, rectangular=rectangular, noise_add=noise_add, luminosity_add=luminosity_add
  ;
  ; Inputs:
  ;      ModPramsStruct - Structure containing model parameters, including:
  ;                       - SYNCOM_NX: Number of grid points along the x-axis
  ;                       - SYNCOM_NY: Number of grid points along the y-axis
  ;                       - SYNCOM_noise_level: Percentage of noise to be added
  ;                       - SYNCOM_max_intensity: Maximum intensity for brightness behavior
  ;                       - SYNCOM_INITIAL_R_SUN: Initial radial position in Rsun
  ;
  ;      img              - Input image array.
  ;
  ; Keywords:
  ;      noise_add      - If set, adds random noise to the image.
  ;      luminosity_add - If set, modifies the image to mimic brightness behavior.
  ;      rectangular    - If set, converts the image into rectangular coordinates.
  ;
  ; Outputs:
  ;      new_img - Output image array with added noise and brightness behavior.
  ;      rect_img - Output rectangular image array (if the rectangular keyword is set).
  ;
  ; Author:
  ;      Written by Valmir Moraes, Jun 2023
  ;-

  ; Record the start time of the procedure
  t0 = systime(/s)
  
  ; Extract parameters from the input structure
  NX            = ModPramsStruct.SYNCOM_NX
  NY            = ModPramsStruct.SYNCOM_NY
  noise_level   = ModPramsStruct.SYNCOM_noise_level
  max_intensity = ModPramsStruct.SYNCOM_max_intensity
  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN
  
  ; Restore mean and standard deviation measurements from COR2 for creating luminosity profile mask
  restore,'/Users/vpereir1/mean_stddev.sav'

  ; Initialize the new image array
  new_img = img > 0.

  ; ---------------------------------- Adjustable Noise Level: ----------------------------------
  ; Adds random noise to the image based on the specified noise level percentage
  if n_elements(noise_level) ne 0. then begin
    ; Create a noise array with the same dimensions as the image
    noise_array = new_img > 0. & level = noise_level/100.
    noise_array = level*randomn(seed, nx, ny)

    ; Add the noise array to the image
    new_img = img + noise_array

    print, "random noise added"
  endif
  ; ---------------------------------------------------------------------------------------------


  ; ------------------------------ Mimicing Brightness Behavior: --------------------------------
  ; Modifies the image to mimic brightness behavior based on mean and standard deviation profiles
  if n_elements(max_intensity) ne 0. then begin
  
    ; Loop through each pixel in the image
    for r=0,ny-1 do for x=0,nx-1 do $
        ; Adjust the brightness of each pixel using mean and standard deviation profiles
        new_img[x,r] = ( reform(new_img[x,r]) * reform(std1[x,r]) ) + reform(mean1[x,r])

    print, "brightness behavior added"
  endif    
  ; ---------------------------------------------------------------------------------------------
  
  ; ----------------------- Converts Image into Rectangular coordinates: ------------------------
  ; Converts the polar image to rectangular coordinates if the rectangular keyword is set
  if keyword_set(rectangular) then begin

    ; Convert the image using the polar_to_rect_tr function
    rect_img = polar_to_rect_tr(new_img, [0,359.9], [5.0, 14.226], n=1024)

    print, "rectangular image created"
  endif
  ; ---------------------------------------------------------------------------------------------

  ; Print the total runtime of the procedure
  print, "run time", systime(/s)-t0
END





;PRO SYNCOM_normalize, ModPramsStruct, data, noise_data;, noise_level, max_intensity
;  t0 = systime(/s)
;
;  NX            = ModPramsStruct.SYNCOM_NX
;  NY            = ModPramsStruct.SYNCOM_NY
;  noise_level   = ModPramsStruct.SYNCOM_noise_level
;;  max_intensity = ModPramsStruct.SYNCOM_max_intensity
;;  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN
;  
;  if n_elements(noise_data) eq 0. then noise_data = data*0.
;  restore,'/Users/vpereir1/Desktop/SynCOM_project/normalize.sav'
;  
;  for time_t=0, n_elements(data[0,0,*])-1 do begin    
;    img = reform(data[*,*,time_t])
;
;    new_img = NORMALIZE_array(ModPramsStruct, img, time_t, mean2,std2, noise_level)
;    
;    noise_data[*,*,time_t] = new_img
;  endfor
;
;  print, "run time", systime(/s)-t0
;
;END
;
;function NORMALIZE_array, ModPramsStruct, img,time_t, mean1, std1,noise_level
;  t0 = systime(/s)
;  
;  new_img = img*0.
;  NX            = ModPramsStruct.SYNCOM_NX
;  NY            = ModPramsStruct.SYNCOM_NY
;  noise_level   = ModPramsStruct.SYNCOM_noise_level
;
;  for x=0, nx-1 do for y=0,ny-1 do new_img[x,y] = (reform(img[x,y])+mean1[x,y]) * std1[x,y]
;
;  ; ---------------------------------- Adjustable Noise Level: ----------------------------------
;  ; adds random noise according to set percentage:
;  if n_elements(noise_level) ne 0. then begin
;    noise_array = new_img > 0. & level = noise_level/100.
;    noise_array = level*randomn(seed, nx, ny)
;
;    img_ = new_img > 0.
;    img_ = new_img + noise_array
;  endif
;
;  print, "run time",time_t, systime(/s)-t0
;  
;  return, img_ > 0.
;end
