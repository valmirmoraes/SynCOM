;+
;
;    Name: POLAR_TO_RECT
;
; Purpose: Transforms a polar image into a rectangular (Cartesian) coordinate system using triangulation.
;          The transformation is based on provided ranges for azimuthal angles (phi) and radial distances (rho).
;          The function interpolates the polar image onto a rectangular grid, converting polar coordinates to Cartesian.
;
; Calling Sequence:
;
;    result = POLAR_TO_RECT_TR(img_p, phi_range, rho_range, n=n)
;      
;      img_p: 2D array containing the input polar image.
;      phi_range: Array specifying the minimum and maximum azimuthal angles in degrees.
;      rho_range: Array specifying the minimum and maximum radial distances (e.g., solar radii).
;      n: (Optional) Number of bins in the x and y directions of the output rectangular image (default is 1024).
;
;
; Keyword Inputs:
;
; img_p          ---    2D input array representing the polar image. The first dimension corresponds to the azimuthal angle,
;                       and the second dimension corresponds to the radial coordinate.
;
;
; phi_range      ---    2-element array specifying the minimum and maximum azimuthal angles (in degrees) for the polar image.
;
;
; rho_range      ---    2-element array specifying the minimum and maximum radial distances (e.g., solar radii).
;
;
; n              ---    (Optional) Number of bins in the x and y directions of the rectangular image. Default is 1024.
;
;
; Outputs:
;
; result         ---    2D array containing the transformed rectangular image.
;
;
; Description of Procedure:
;
;    The procedure transforms a polar image to a rectangular (Cartesian) grid by converting polar coordinates
;    to Cartesian coordinates. The input polar image is triangulated and interpolated onto the rectangular grid.
;    The procedure applies a mask to the region inside the minimum radial distance, setting pixel values to zero
;    to simulate the Sun’s mask.
;
;
; Example:
;    result = POLAR_TO_RECT(data_sample, [0, 359.9], [5.0, 14.226], n=1024)
;    help, result
;
;
; Called by:
;    SYNCOMNOISE
;
; Calls:
;    NONE
;
; Common Blocks: None
;
; Author and history:
;
;   (c) V. Uritsky, CUA at NASA/GSFC, 2024
;   Revised for clarity by Valmir Moraes   Sep 2024
;   
;-

function polar_to_rect, img_p, phi_range, rho_range, n=n

  ; --------------------- Set the default value for 'n' if not provided ---------------------
  if n_elements(n) eq 0 then n = 1024L  ; Default size of the output rectangular image
  
  ; ---------------- Get the dimensions of the input polar image ----------------------------
  sz = size(img_p, /dim)  ; Get the size of the polar image
  Np = sz[0]  ; Number of azimuthal points (phi)
  Nr = sz[1]  ; Number of radial points (rho)

  ; ----------------- Calculate the increments for azimuthal angles and radial distances -----------------
  d_phi = (phi_range[1] - phi_range[0]) / float(Np - 1)  ; Step size for azimuthal angles (degrees)
  d_rho = (rho_range[1] - rho_range[0]) / float(Nr - 1)  ; Step size for radial distances

  ; ----------------- Generate 1D arrays for azimuthal angles and radial distances -----------------
  phi_1d = findgen(Np) * d_phi + phi_range[0]  ; Array of azimuthal angles in degrees
  rho_1d = findgen(Nr) * d_rho + rho_range[0]  ; Array of radial distances

  ; ---------------- Initialize 2D arrays for azimuthal and radial coordinates ----------------
  phi_2d = fltarr(Np, Nr)  ; 2D array for azimuthal angles (in radians)
  rho_2d = fltarr(Np, Nr)  ; 2D array for radial distances

  ; ----------------- Fill the 2D arrays with corresponding values -----------------
  for i = 0, Nr - 1 do phi_2d[*, i] = phi_1d * !Pi / 180  ; Convert azimuthal angles from degrees to radians
  for i = 0, Np - 1 do rho_2d[i, *] = rho_1d              ; Assign radial distances

  ; ------------------ Convert polar coordinates to Cartesian coordinates -------------------
  x_2d = rho_2d * cos(phi_2d)  ; X-coordinates in the Cartesian system
  y_2d = -rho_2d * sin(phi_2d) ; Y-coordinates in the Cartesian system (negative for clockwise)

  ; ------------------ Perform triangulation on the Cartesian coordinates -------------------
  triangulate, x_2d, y_2d, Tr  ; Triangulate the (x, y) points for interpolation

  ; ------------------ Interpolate the polar image onto a rectangular grid ------------------
  img_rect = trigrid(x_2d, y_2d, img_p, Tr, nx=n, ny=n, xgrid=x_1d, ygrid=y_1d)  ; Interpolate to a rectangular grid

  ; ------------------ Initialize arrays for the rectangular grid points --------------------
  x_2d = fltarr(n, n)  ; Initialize 2D array for x-grid points
  y_2d = fltarr(n, n)  ; Initialize 2D array for y-grid points

  ; ----------------- Fill the grid point arrays with corresponding values ------------------
  for i = 0, n - 1 do x_2d[*, i] = x_1d  ; X-grid points
  for i = 0, n - 1 do y_2d[i, *] = y_1d  ; Y-grid points

  ; ----------------- Apply a mask to pixels within the minimum radial distance --------------
  ; This mask sets the values inside the inner radius (rho_range[0]) to zero, simulating the Sun’s mask
  sun_mask = where((x_2d^2 + y_2d^2) lt rho_range[0]^2)  ; Find pixels inside the minimum radial distance
  img_rect[sun_mask] = 0  ; Set these pixels to zero

  ; ---------------- Return the transformed rectangular image -----------------
  return, img_rect
end




