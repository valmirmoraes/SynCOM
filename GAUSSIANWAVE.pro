;+
;    Name:
;        GAUSSIANWAVE
;
;    Purpose:
;        Generates a 1D or 2D Gaussian wave, referred to as a "propagating blob."
;        This is used to represent solar wind features that propagate through space.
;        The Gaussian is defined by pixel dimensions, a central position (mean), and a standard deviation (width).
;
;    Calling Sequence:
;        result = GAUSSIANWAVE(npixel=npixel, avr=avr, st_dev=st_dev)
;
;    Example:
;        ; Generate a 2D Gaussian wave with dimensions [3600, 659], centered at [0,150] and with widths [10,10]:
;        result = GAUSSIANWAVE(npixel=[3600,659], avr=[0,150], st_dev=[10,10])
;        help, result
;
;    Inputs:
;        npixel  ---  Number of pixels in each dimension:
;                    1D: [nx], where nx is the number of pixels along the x-axis.
;                    2D: [nx, ny], where nx is the number of pixels along the x-axis and ny along the y-axis.
;
;        avr     ---  Central position (mean) of the Gaussian blob in each dimension:
;                    1D: [avr_x], where avr_x is the central position along the x-axis.
;                    2D: [avr_x, avr_y], where avr_x and avr_y are the central positions along the x and y axes, respectively.
;
;        st_dev  ---  Standard deviation (width) of the Gaussian blob in each dimension:
;                    1D: [st_dev_x], where st_dev_x is the width along the x-axis.
;                    2D: [st_dev_x, st_dev_y], where st_dev_x and st_dev_y are the widths along the x and y axes, respectively.
;
;    Outputs:
;        result  ---  A 1D or 2D array representing the Gaussian wave (propagating blob).
;
;    Description of Procedure:
;        1. The function checks whether the input specifies a 1D or 2D Gaussian based on the dimensions of npixel.
;        2. For a 1D Gaussian, it creates a Gaussian curve based on the input mean and standard deviation.
;        3. For a 2D Gaussian, it creates a Gaussian surface using the specified mean and standard deviation in both dimensions.
;        4. The resulting Gaussian wave is returned as a 1D or 2D array.
;
;    Notes:
;        - This function is used to generate propagating blobs for solar wind simulations.
;        - The Gaussian wave is created to simulate a smooth, symmetric blob that propagates with time.
;        - For 2D Gaussian waves, the blob is shifted along the x-axis based on its central position.
;
;    Called by:
;        SYNCOMIMAGE
;
;    Calls:
;        None
;
;    Common Blocks:
;        None
;
;    Author and History:
;        Written by Valmir Moraes, Jun 2023
;        Revised for clarity and structure by Valmir Moraes, Sep 2024
;-

function gaussianwave, npixel=npixel, avr=avr, st_dev=st_dev

  ; -------------------- Determine whether the Gaussian wave is 1D or 2D based on npixel input -------------------- 
  sz_npix = size(npixel, /DIMENSION)

  ; Case for 1D Gaussian wave
  if sz_npix eq 1 then begin
    ndim = 1                   ; Set dimension to 1D
    nx = npixel[0]             ; Number of pixels along x-axis
    avr = avr                  ; Mean (central position) in 1D
    st_dev = st_dev            ; Standard deviation (width) in 1D
  endif

  ; Case for 2D Gaussian wave
  if sz_npix eq 2 then begin
    ndim = 2                   ; Set dimension to 2D
    npix = npixel              ; Number of pixels in both dimensions
    avr = avr                  ; Mean (central position) in both dimensions
    st_dev = st_dev            ; Standard deviation (width) in both dimensions
  endif

  ; -------------------- Generate Gaussian wave (propagating blob) based on the dimensions -------------------- 
  case ndim of
    1: begin
      ; 1D Gaussian wave (propagating blob)
      x = dindgen(nx)  ; Generate x-axis values

      ; Create the 1D Gaussian function representing the propagating blob
      G = exp( -( (x - avr[0])^2 / (2 * st_dev[0]^2) ) )  ; Gaussian curve

      return, G
    end
    
    2: begin
      ; 2D Gaussian wave (propagating blob)
      nx = npix[0] & x = dindgen(nx)  ; x-axis values
      ny = npix[1] & y = dindgen(ny)  ; y-axis values

      G = fltarr(nx, ny)  ; Initialize empty 2D array

      ; Create the Gaussian along the x and y axes
      Gx = exp( -( (x - avr[0])^2 / (2 * st_dev[0]^2) ) )  ; Gaussian along x-axis
      Gy = exp( -( (y - avr[1])^2 / (2 * st_dev[1]^2) ) )  ; Gaussian along y-axis

      ; Combine x and y Gaussians into a 2D Gaussian surface
      G = Gx # Gy

      ; Shift the Gaussian along the x-axis based on its mean position (central position of the blob)
      G = shift(G, [floor(avr[0] - nx/2.0), 0])

      return, G
    end
  endcase
end
