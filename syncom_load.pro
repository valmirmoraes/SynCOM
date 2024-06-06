PRO SYNCOM_LOAD, ModPramsStruct, LoadStruc

  ;+
  ; Name:
  ;
  ;      SynCOM_LOAD
  ;
  ; Purpose: Reads input parameters and returns information for each blob
  ;    gets geometry and units into FORWARD standards
  ;
  ; Calling sequence:
  ;
  ;      SYNCOM_LOAD,filename,n_blobs,instr_cadence,initial_R_sun,size_scale,LoadStruc
  ;
  ; Inputs:
  ;
  ;  filename: file containing an array called database[3600,3]
  ;      (frequency,velocity,date) for each .1 degree of Craig's polar angle)
  ;      Date is not being used at the moment -- set to the date of the statistics
  ;
  ;  n_blobs: number of blobs -- free parameter
  ;  initial_R_sun: position where blobs first emerge
  ;      set to 1 Rsun for FORWARD (free parameter)
  ;  instr_cadence: used to scale the temporal statistics appropriately depending
  ;      on what instrument was used to create them
  ;        ***not being used***
  ;  size_scale: scaling factor used to scale the blob size
  ;  if set to 1, the edge of each blob just touches the edge of the next blob
  ;
  ; Outputs:
  ;          LoadStruc  - structure containing Outarray and Velocity
  ;    Velocity - array containing velocity flow field vs polar angle - dimension 3600 (.1 degree steps)
  ;    Outarray - Information about each blob - dimension n_blob X 7
  ;                     0 - radius coordinate
  ;                     1 - phi coordinate
  ;                     2 - theta coordinate
  ;                     3 - initial time t
  ;                           model time that a given blob first appears at r=initial_R_sun
  ;                           units: seconds
  ;                     4 - period
  ;                           time interval between reappearances (at r=initial_R_sun) of a given blob
  ;                           units: seconds
  ;                     5 - radial velocity
  ;                           velocity of the blob
  ;                           units: km/sec
  ;                     6 - blob size
  ;                           blobs are currently considered as spheres, with radius blob size
  ;                           units: Rsun
  ;
  ; Called by SYNCOM_RHO
  ;
  ;
  ; Author and history:
  ;
  ;   Written by Valmir Moraes   Jun 2023
  ;-

  slash=path_sep()

  COMPILE_OPT IDL2 ;default long and square brackets for array subscripts

  ;  file_name = "/Users/vpereir1/Downloads/SynCOM_codes/syncom_20140414_densfix.sav"
  file_name = '/Users/vpereir1/Desktop/SynCOM_project/stereo_data.sav'

  restore, file_name

  n_blobs = ModPramsStruct.SYNCOM_N_BLOBS
  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN

  ; Converts Craig's coordinate system to standard
  ;          we assume z is the vertical axis, y is the horizontal axis, x axis is coming out of page
  ;   Craig: position angle (PSI) starting at y=1 (e.g., West limb equator) and increase clockwise
  ;   FORWARD: position angle (PSI) starts z=1 (e.g., North pole) and increase counterclockwise
  ;
  ;   units=.1 degree

  PSI_ORDER=(findgen(3600)-2700)*(-1)
  for i=0,3600-1 do if PSI_ORDER[i] lt 0.0 then PSI_ORDER[i] = PSI_ORDER[i] + 3600.0

  ; Restores frequency and velocity from database
  ; both will be reordered as new PSI conversion:

  ; this will be used when solar period profile is available
  ;
  ;  FREQUENCY_temp = DOUBLE(smooth(freq_temp,20)) ; FREQUENCY -> in Hz sampling every .1 degree of PSI
  ;  FREQUENCY = FREQUENCY_temp[PSI_ORDER]
  ;  PERIOD = (1./FREQUENCY) ; units seconds

  PERIOD_temp = (randomu(22,3600)*0 + 3.0)*3600
  PERIOD = congrid(PERIOD_temp,3600)

  Lr = (randomu(22,3600)*(1.0) + (0.1)) ; blob size in units in Rsun

    restore, '/Users/vpereir1/Desktop/SynCOM_project/stereo_data.sav'
  theta = findgen(360.) & vr = 250 + 100*cos(2*!Pi*theta/180.0) & v_temp = congrid(vr,3600.)
  VELOCITY_temp = DOUBLE(smooth(v_temp, 10,/edge_trun)) ; VELOCITY -> in km/second sampling every .1 degree of PSI
  VELOCITY = VELOCITY_temp[PSI_ORDER]

  ; creates array of random positions for each blob
  ;   this will be in physical units of FORWARD
  ;   r in units of RSUN, theta, phi in RADIANS
  ;   theta is colatitude, 0 is North pole, pi/2 equator, pi is South pole
  ;   phi is longitude, 0 is at X axis from 0 to 2 pi

  n_theta = 180.0 & n_phi = 360.0
  radial_i= double(randomu(seed,n_blobs)*0.0+initial_R_sun)      ; radial component starting from the solar base
  phi_i   = double(randomu(seed,n_blobs)*n_phi*!DTOR)            ; phi component in radians
  theta_i = double(randomu(seed,n_blobs)*n_theta*!DTOR)          ; theta component in radians
  ; dimension of all n_blobs

  ; establish polar angle PSI associated with each blob position
  ;    this is in FORWARD standard as defined above

  PSI_rad = theta_i ; radians
  for i=0, n_blobs-1 do if sin( phi_i[i] ) GE 0 then PSI_rad[i] = 2.*!dpi - theta_i[i] else PSI_rad[i] = theta_i[i]

  PSI_deg = (PSI_rad*!RADEG)*10.0 ; Convert PSI_rad in radians to PSI_deg in .1 degrees

  v_arr = PSI_rad*0. ; array dimension nblobs
  for i=0, n_blobs-1 do v_arr[i] = VELOCITY[PSI_deg[i]] ; read velocity from database
  ; assigned to .1 degree polar angle steps
  ; reorder velocity array into ascendent order
  ind = reverse(sort(v_arr))

  v_arr      = v_arr[ind]       ; units in km/seconds
  period_arr = PERIOD[ind]      ; units in seconds

  L_arr = Lr[ind]
  ;  L_arr = reverse(sort(L_arr_temp[ind]))

  radial_i   = radial_i[ind]    ; units in Rsun
  phi_i      = phi_i[ind]       ; units in rad
  theta_i    = theta_i[ind]     ; units in rad
  PSI_deg_i  = PSI_deg[ind]     ; units in degrees

  ; output array: each blob has 7 points
  outarray=dblarr(n_blobs,8)

  time_0 = 0
  for i=0, n_blobs-1 do begin
    outarray[i,0] = radial_i[i]   ; units in Rsun
    outarray[i,1] = phi_i[i]      ; units in rad
    outarray[i,2] = theta_i[i]    ; units in rad
    outarray[i,3] = time_0        ; units in seconds
    outarray[i,4] = period_arr[i] ; units in seconds
    outarray[i,5] = v_arr[i]      ; units in km/seconds
    outarray[i,6] = L_arr[i]      ; units in Rsun
    outarray[i,7] = PSI_deg_i[i]  ; units in degrees

    ; these have been ordered with increasing velocities, but there can be
    ; situations where a given velocity is chosen for more than one blob, either because
    ; there are two polar angles in the database with the same velocity, or because the same
    ; polar angle has been randomly chosen by more than one blob.
    ; the next line will make sure that blobs with the same velocity launch at the same time.
    ; In the latter case (same polar angle) this will double down on the blob and make it brighter
    ; (multipled by number of blobs at that polar angle.
    ; In the former case (same velocity, different polar angle) it will mean they launch at the same time.
    ;
    if fix(outarray[i,5]) eq fix(outarray[i-1,5]) then outarray[i,3] = outarray[i-1,3] else time_0 = time_0 + 1.
  endfor

  LoadStruc = {outarray:outarray,$
    velocity:velocity $
  }
END
