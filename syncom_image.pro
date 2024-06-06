PRO SYNCOM_image, ModPramsStruct,syncom_version, time_0,radial_i, v_array,period_array, L_array, PSI, time_t, img
t0=systime(/s)

  ;+
  ; Name:
  ; 
  ;      SynCOM_IMAGE
  ;      
  ;
  ; Purpose: Returns the densities on the grid
  ;
  ; Calling sequence:
  ; 
  ;      SYNCOM_IMAGE,ModPramsStruct,syncom_version, time_0,radial_i, v_array,period_array, L_array, PSI, time_t, img
  ;
  ;
  ; Inputs:
  ;          syncom_version - label that indicates the version of the run
  ;          
  ;          time_0, time_t - specified intitial and final time of the run
  ;          
  ;          radial_i, v_array, period_array, L_array, PSI - inputs provided by SYNCOM_LOAD
  ;          radial_i - initial position of blob's launch
  ;          v_array  - velocity for specific position angle
  ;          period_array - period for specific position angle 
  ;          L_array - blob radius for specific position angle
  ;          PSI - position angle array for STEREO configuration
  ;
  ;          ModPramsStruct - structure associated with model, containing
  ;                           model name (SYNCOM), model parameters
  ;                           set up in syncomprams.pro
  ;                           
  ;
  ; Outputs: img - output SynCOM image for a specific time_t
  ;
  ;
  ; Called by SYNCOM
  ;
  ; Calls SYNCOM_LOAD
  ; 
  ;
  ; Author and history:
  ;
  ;   Written by Valmir Moraes   Jun 2023
  ;-

  n_blobs = ModPramsStruct.SYNCOM_N_BLOBS    ; number of blobs

  NX     = ModPramsStruct.SYNCOM_NX ; size of x-axis
  NY     = ModPramsStruct.SYNCOM_NY ; size of y-axis
  
  radial_t = (time_t+time_0) * v_array ; blob position at time t
         
  img = dblarr(3600,659) ; creates empty array for new image
  
  for i=0, n_blobs-1 do begin

    a_arr = gaussian_wave( npixel=[nx, ny], avr=[PSI[i], radial_i[i]], st_dev = [L_array[i], 2*L_array[i]]  ) ; makes blob
 
;    a_arr = a_arr + shift(a_arr, [ 0, 2*period_array[i]*v_array[i] + 2*L_array[i] ]) ; adds new blob after each space "perturbation"
    a_arr = a_arr + shift(a_arr, [0, (2)*period_array[i]*v_array[i]  + (2)*L_array[i]])   + $
                    shift(a_arr, [0, (4)*period_array[i]*v_array[i]  + (4)*L_array[i]])   + $
                    shift(a_arr, [0, (-2)*period_array[i]*v_array[i] + (-2)*L_array[i]])  + $
                    shift(a_arr, [0, (-4)*period_array[i]*v_array[i] + (-4)*L_array[i]]) ; adds new blobs after each space "perturbation"

    a_arr = shift(a_arr, [ 0, radial_t[i] ] ) ; adding simple accelaration to each blob

    img = temporary(img) + a_arr
  endfor
  

  WRITEFITS, "SynCOM_"+strtrim(string(syncom_version),2)+"_"+strtrim(string(time_t),2)+".fts", img
  print, "run time", time_t, systime(/s)-t0
END

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
