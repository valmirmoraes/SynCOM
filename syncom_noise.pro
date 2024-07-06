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
  ;      img - Input image array.
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
  restore,'/Users/vpereir1/Desktop/SynCOM_project/SynCOM_codes/SynCOM codes/mean_stddev.sav'

  ; Initialize the new image array
  new_img = img > 0.

  ; ---------------------------------- Adjustable Noise Level: ----------------------------------
  ; Adds random noise to the image based on the specified noise level percentage
  if keyword_set(noise_add) then begin
    ; Create a noise array with the same dimensions as the image
    noise_array = new_img > 0. & level = noise_level/100.
    noise_array = level*randomn(seed, nx, ny)

    ; Add the noise array to the image
    new_img = img + noise_array

;    print, "random noise added"
  endif
  ; ---------------------------------------------------------------------------------------------


  ; ------------------------------ Mimicing Brightness Behavior: --------------------------------
  ; Modifies the image to mimic brightness behavior based on mean and standard deviation profiles
  if keyword_set(luminosity_add) then begin
  
    ; Loop through each pixel in the image
    for r=0,ny-1 do for x=0,nx-1 do $
        ; Adjust the brightness of each pixel using mean and standard deviation profiles
        new_img[x,r] = ( reform(new_img[x,r]) * reform(std1[x,r]) ) + reform(mean1[x,r])

;    print, "brightness behavior added"
  endif    
  ; ---------------------------------------------------------------------------------------------

  ; ----------------------- Converts Image into Rectangular coordinates: ------------------------
  ; Converts the polar image to rectangular coordinates if the rectangular keyword is set
  if keyword_set(rectangular) then begin

    ; Convert the image using the polar_to_rect_tr function
    rect_img = polar_to_rect_tr(new_img, [0,359.9], [5.0, 14.226], n=1024)

;    print, "rectangular image created"
  endif
  ; ---------------------------------------------------------------------------------------------

  ; Print the total runtime of the procedure
  print, "run time", systime(/s)-t0

END


function polar_to_rect_tr, img_p, phi_range, rho_range, n=n
  ;+
  ; Name:
  ;      polar_to_rect_tr
  ;
  ; Purpose:
  ;      Transforms a polar image to a rectangular (Cartesian) coordinate system using triangulation.
  ;
  ; Calling Sequence:
  ;      result = polar_to_rect_tr(img_p, phi_range, rho_range, n=n)
  ;
  ; Inputs:
  ;      img_p     - 2D array containing the input polar image. The first dimension represents the azimuthal angle,
  ;                  and the second dimension represents the radial coordinate.
  ;      phi_range - 2-element array containing the minimum and maximum polar angles in degrees.
  ;      rho_range - 2-element array containing the minimum and maximum radial heliocentric distances in desired units (e.g., solar radii).
  ;      n         - (Optional) Number of bins in the x and y directions of the transformed rectangular image. Default value is 1024.
  ;
  ; Outputs:
  ;      A 2D array containing the transformed rectangular image.
  ;
  ; Example:
  ;      result = polar_to_rect_tr(data_sample, [0, 359.9], [5.0, 14.226], n=1024)
  ;      help, result
  ;      ** Structure <251fe058>, 3 tags, length=2105344, data length=2105344, refs=1:
  ;      IMG             DOUBLE    Array[1024, 1024]
  ;      X               DOUBLE    Array[1024]
  ;      Y               DOUBLE    Array[1024]
  ;
  ;      window, xs=1024, ys=1024 & loadct, 3 & tvscl, result.img
  ;
  ; Author:
  ;      (c) V. Uritsky, CUA at NASA/GSFC 2024
  ;-

  ; Set default value for 'n' if not provided
  if n_elements(n) eq 0 then n = 1024L

  ; Get the dimensions of the input polar image
  sz = size(img_p, /dim)
  Np = sz[0] ; Number of azimuthal points
  Nr = sz[1] ; Number of radial points

  ; Calculate the increments for azimuthal angles and radial distances
  d_phi = (phi_range[1] - phi_range[0]) / float(Np - 1)
  d_rho = (rho_range[1] - rho_range[0]) / float(Nr - 1)

  ; Generate 1D arrays for azimuthal angles and radial distances
  phi_1d = findgen(Np) * d_phi + phi_range[0]
  rho_1d = findgen(Nr) * d_rho + rho_range[0]

  ; Initialize 2D arrays for azimuthal angles and radial distances
  phi_2d = fltarr(Np, Nr)
  rho_2d = fltarr(Np, Nr)

  ; Fill the 2D arrays with corresponding values
  for i = 0, Nr - 1 do phi_2d[*, i] = phi_1d * !Pi / 180 ; Convert degrees to radians
  for i = 0, Np - 1 do rho_2d[i, *] = rho_1d

  ; Convert polar coordinates to Cartesian coordinates
  x_2d = rho_2d * cos(phi_2d)
  y_2d = -rho_2d * sin(phi_2d)

  ; Perform triangulation on the Cartesian coordinates
  triangulate, x_2d, y_2d, Tr

  ; Interpolate the polar image onto a rectangular grid
  img_rect = trigrid(x_2d, y_2d, img_p, Tr, nx=n, ny=n, xgrid=x_1d, ygrid=y_1d)

  ; Initialize 2D arrays for the rectangular grid points
  x_2d = fltarr(n, n)
  y_2d = fltarr(n, n)

  ; Fill the 2D arrays with grid point values
  for i = 0, n - 1 do x_2d[*, i] = x_1d
  for i = 0, n - 1 do y_2d[i, *] = y_1d

  ; Apply a mask to set pixels within the minimum radial distance to zero (simulating the Sun's mask)
  sun_mask = where((x_2d^2 + y_2d^2) lt rho_range[0]^2)
  img_rect[sun_mask] = 0

  ; Return the transformed rectangular image
  return, img_rect
end



