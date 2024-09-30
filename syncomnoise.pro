;+
;    Name:
;        SYNCOMNOISE
;
;    Purpose:
;        Adds random noise to the input image and simulates brightness variations based on model parameters.
;        Optionally, converts the image into rectangular coordinates. This procedure is useful for simulating
;        observational effects such as noise and brightness fluctuations in synthetic solar wind images.
;
;    Calling Sequence:
;        SYNCOMNOISE, ModPramsStruct, img, new_img, rect_img, file_name [, /rectangular, /noise_add, /luminosity_add]
;
;    Example:
;        ; Add noise and simulate brightness behavior:
;        SYNCOMNOISE, ModPramsStruct, img, new_img, /noise_add, /luminosity_add
;
;        ; Convert the image to rectangular coordinates:
;        SYNCOMNOISE, ModPramsStruct, img, new_img, rect_img, /rectangular
;
;    Inputs:
;        ModPramsStruct   ---   Structure containing the model parameters, including:
;                               - SYNCOM_NX: Number of grid points along the x-axis (position angle).
;                               - SYNCOM_NY: Number of grid points along the y-axis (radial distance).
;                               - SYNCOM_noise_level: Percentage of noise to be added.
;                               - SYNCOM_max_intensity: Maximum intensity value for brightness simulation.
;                               - SYNCOM_INITIAL_R_SUN: Initial radial position in Rsun.
;
;        img              ---   Input image array to be modified.
;
;    Optional Inputs:
;        file_name        ---   Path to the file containing mean and standard deviation profiles for brightness behavior.
;                               DEFAULT: '/Users/vpereir1/IDLWorkspace/Default/stereo_analysis.sav'
;
;    Keywords:
;        rectangular      ---   If set, converts the polar image into rectangular coordinates.
;
;        noise_add        ---   If set, adds random noise to the image based on the noise level specified in `ModPramsStruct`.
;
;        luminosity_add   ---   If set, adjusts the image to simulate brightness variations based on intensity profiles
;                               derived from COR2 data. Each pixel is modified according to the mean and standard
;                               deviation of observed intensity values.
;
;    Outputs:
;        new_img          ---   Output image with added noise and/or brightness adjustments.
;
;        rect_img         ---   Output image in rectangular coordinates (if the rectangular keyword is set).
;
;    Description of Procedure:
;        1. This procedure first reads the model parameters from `ModPramsStruct`.
;        2. If the `/noise_add` keyword is set, random noise is added to the input image based on the specified
;           noise level. The amount of noise is proportional to the value set in `SYNCOM_noise_level`.
;        3. If the `/luminosity_add` keyword is set, the image brightness is modified based on intensity profiles
;           from COR2 data. This involves adjusting each pixel according to the observed mean and standard deviation
;           values for intensity.
;        4. If the `/rectangular` keyword is set, the procedure converts the polar image into rectangular coordinates
;           using the `polar_to_rect_tr` function.
;
;    Notes:
;        - This procedure is useful for simulating the observational effects of noise and brightness variations
;          in synthetic solar wind images.
;        - The `/rectangular` keyword is optional and is used only when a conversion from polar to rectangular coordinates
;          is required.
;
;    Called by:
;        SYNCOM
;
;    Calls:
;        polar_to_rect_tr
;
;    Common Blocks:
;        None
;
;    Author and History:
;        Written by Valmir Moraes, Jul 2023
;        Revised for clarity by Valmir Moraes, Sep 2024
;-

PRO SYNCOMnoise, ModPramsStruct, img, new_img, rect_img, file_name, $
                 rectangular=rectangular, noise_add=noise_add, luminosity_add=luminosity_add

  ; Record the start time of the procedure for performance tracking
  t0 = systime(/s)

  ; Extract relevant parameters from the input structure
  NX            = ModPramsStruct.SYNCOM_NX               ; Number of grid points along the x-axis
  NY            = ModPramsStruct.SYNCOM_NY               ; Number of grid points along the y-axis
  noise_level   = ModPramsStruct.SYNCOM_noise_level      ; Noise level percentage to be added
  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN    ; Initial radial position in Rsun

  ; Load the mean and standard deviation measurements for creating intensity profile
  if keyword_set(file_name) eq 0 then file_name = ModPramsStruct.FILENAME
  restore, file_name

  ; Initialize the output image array by copying the input image
  new_img = img > 0.  ; Ensure that the image values are non-negative

  ; -------------------------- Adding Random Noise to the Image --------------------------
  ; If the noise_add keyword is set, add random noise to the image based on the noise level
  if keyword_set(noise_add) then begin
    ; Create a noise array with values scaled by the noise level
    noise_array = new_img > 0. & level = noise_level / 100.  ; Normalize noise level
    noise_array = level * randomn(seed, NX, NY)              ; Generate random noise

    ; Add the noise array to the image
    new_img = img + noise_array  ; Add noise to the original image
    print, "random noise added"
  endif
  ; --------------------------------------------------------------------------------------


  ; ---------------------- Simulating Brightness Behavior in the Image -------------------
  ; If the luminosity_add keyword is set, modify the image to simulate brightness behavior
  if keyword_set(luminosity_add) then begin
    ; Loop through each pixel in the image
    for r = 0, NY-1 do for x = 0, NX-1 do $
      ; Adjust the brightness using predefined mean and standard deviation profiles
      new_img[x, r] = ( reform(new_img[x, r]) * reform(std1[x, r]) ) + reform(mean1[x, r])
    print, "brightness behavior added"
  endif
  ; --------------------------------------------------------------------------------------


  ; ----------------------- Converting the Image to Rectangular Coordinates ---------------
  ; If the rectangular keyword is set, convert the image from polar to rectangular coordinates
  if keyword_set(rectangular) then begin
    ; Convert the polar image to rectangular coordinates using the polar_to_rect_tr function
    rect_img = polar_to_rect(new_img, [0, 359.9], [5.0, 14.226], n=1024)  ; Full polar range and radial range
    print, "rectangular image created"
  endif
  ; --------------------------------------------------------------------------------------


  ; Print the total runtime of the procedure for performance evaluation
  print, "run time", systime(/s) - t0

END
