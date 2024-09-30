;+
;    Name:
;        SYNCOMLOAD
;
;    Purpose:
;        Reads input parameters and generates information for each blob, including position, velocity, 
;        and size, based on predefined or user-supplied data. This procedure prepares blob data for 
;        the SynCOM simulation by calculating the physical parameters necessary for blob propagation.
;
;    Calling Sequence:
;        SYNCOMLOAD, ModPramsStruct, LoadStruc [, /SIMPLE], file_name
;
;    Example:
;        ; Load blob data using the default file path and solar velocity profile:
;        SYNCOMLOAD, ModPramsStruct, LoadStruc
;
;        ; Use a sinusoidal velocity profile and a custom blob data file:
;        SYNCOMLOAD, ModPramsStruct, LoadStruc, /SIMPLE, file_name="custom_path/stereo_data.sav"
;
;    Inputs:
;        ModPramsStruct --- Structure containing input parameters such as:
;                          - SYNCOM_N_BLOBS: Number of blobs to simulate.
;                          - SYNCOM_INITIAL_R_SUN: Initial radial position (in solar radii) where blobs first emerge.
;
;    Optional Inputs:
;        file_name    --- String specifying the file path for the blob data. 
;                        If not provided, defaults to '/Users/vpereir1/Desktop/SynCOM_project/stereo_data.sav'.
;
;    Keywords:
;        SIMPLE       --- Optional keyword. If set, a sinusoidal velocity profile is used, overriding 
;                        the default solar velocity profile.
;
;    Outputs:
;        LoadStruc    --- Structure containing the following output arrays:
;                         - Velocity: Array of velocity values for each blob, sampled at 0.1-degree intervals in the polar angle direction.
;                         - Period: Array of random period values for each blob.
;                         - Outarray: Array with information about each blob, with the following columns:
;                           0 - Radial coordinate (R_sun),
;                           1 - Phi coordinate (radians),
;                           2 - Theta coordinate (radians),
;                           3 - Initial time (seconds),
;                           4 - Period (seconds),
;                           5 - Radial velocity (km/s),
;                           6 - Blob size (R_sun),
;                           7 - Polar angle (degrees).
;
;    Description of Procedure:
;        1. The procedure reads input parameters from the provided structure, or restores them 
;           from a file if not supplied.
;        2. If the SIMPLE keyword is set, a sinusoidal velocity profile is generated.
;        3. Randomized blob positions, velocities, periods, and sizes are assigned and stored in arrays.
;        4. The final structure containing the blob information is output for use in the SynCOM simulation.
;
;    Notes:
;        - The default velocity profile is solar, unless overridden by the SIMPLE keyword.
;        - Blob properties such as size, velocity, and period are generated from random distributions 
;          to simulate the diverse nature of solar wind blobs.
;
;    Called by:
;        SYNCOM
;
;    Calls:
;        NONE
;
;    Common Blocks:
;        None
;
;    Author and History:
;        Written by Valmir Moraes, Jun 2023.
;        Revised for clarity and structure, Sep 2024.
;-

PRO SYNCOMLOAD, ModPramsStruct, LoadStruc, SIMPLE=SIMPLE, file_name

  slash = path_sep()

  COMPILE_OPT IDL2  ; Ensure long integers and enforce IDL2 array indexing

  ; Set the default file path if file_name is not provided
  if keyword_set(file_name) eq 0 then file_name = ModPramsStruct.FILENAME
  restore, file_name  ; Load the blob data from the specified or default file

  n_blobs = ModPramsStruct.SYNCOM_N_BLOBS
  initial_R_sun = ModPramsStruct.SYNCOM_INITIAL_R_SUN

  ; Convert position angle (PSI) from Craig's system to FORWARD standards (counterclockwise from North)
  PSI_ORDER = findgen(3600)
  for i = 0, 3600 - 1 do if PSI_ORDER[i] lt 0.0 then PSI_ORDER[i] += 3600.0

  ; Restore and reorder frequency and velocity data according to the new PSI ordering
  FREQUENCY_temp = DOUBLE(smooth(freq_temp, 20))
  FREQUENCY = FREQUENCY_temp[PSI_ORDER]
  PERIOD = (1.0 / FREQUENCY)  ; Convert frequency to period (seconds)

  ; Randomly assign period values to each position angle in seconds.
  ; The periods are randomized between 1.5 and 3.0 hours (converted to seconds).
  PERIOD = (randomu(22, 3600) * 5400.0 + 5400.0)       ; Random between 1.5 hours (5400s) and 3 hours (10800s)

  ; Randomly assign blob sizes to each position angle in R_sun, within the range [0.1, 1.1] R_sun.
  Lr = (randomu(22, 3600) * 1.0 + 0.1)                 ; Random size from 0.1 to 1.1 R_sun

  ; If SIMPLE is set, use a sinusoidal velocity profile.
  if keyword_set(SIMPLE) then begin
    theta = findgen(360.0)                             ; Generate theta values from 0 to 359 degrees.
    vr = 250.0 + 100.0 * cos(2 * !Pi * theta / 180.0)  ; Velocity varies sinusoidally between 150 km/s and 350 km/s.
    v_temp = congrid(vr, 3600)                         ; Expand the velocity profile to 3600 elements.
  endif

  ; Smooth the velocity array and reorder by PSI
  VELOCITY_temp = DOUBLE(smooth(v_temp, 10, /edge_trun))
  VELOCITY = VELOCITY_temp[PSI_ORDER]

  ; Generate random positions for each blob and convert to polar coordinates
  n_theta = 180.0
  n_phi = 360.0
  radial_i = double(randomu(seed, n_blobs) * 0.0 + initial_R_sun)  ; Radial position (R_sun)
  phi_i = double(randomu(seed, n_blobs) * n_phi * !DTOR)           ; Phi (radians)
  theta_i = double(randomu(seed, n_blobs) * n_theta * !DTOR)       ; Theta (radians)

  ; Convert blob positions to polar angle (PSI) in FORWARD standards
  PSI_rad = theta_i
  for i = 0, n_blobs - 1 do if sin(phi_i[i]) ge 0 then PSI_rad[i] = 2.0 * !dpi - theta_i[i] else PSI_rad[i] = theta_i[i]

  PSI_deg = (PSI_rad * !RADEG) * 10.0  ; Convert radians to 0.1-degree units

  ; Assign velocities to each blob based on their PSI angle
  v_arr = PSI_rad * 0.0
  for i = 0, n_blobs - 1 do v_arr[i] = VELOCITY[PSI_deg[i]]

  ; Sort blobs by velocity
  ind = reverse(sort(v_arr))

  v_arr = v_arr[ind]            ; Velocity (km/s)
  period_arr = PERIOD[ind]      ; Period (seconds)
  L_arr = Lr[ind]               ; Blob size (R_sun)
  radial_i = radial_i[ind]      ; Radial position (R_sun)
  phi_i = phi_i[ind]            ; Phi (radians)
  theta_i = theta_i[ind]        ; Theta (radians)
  PSI_deg_i = PSI_deg[ind]      ; Polar angle (degrees)

  ; Initialize output array with blob data: radial position, angles, time, period, velocity, size, and PSI
  outarray = dblarr(n_blobs, 8)
  time_0 = 0
  for i = 0, n_blobs - 1 do begin
    outarray[i, 0] = radial_i[i]     ; R_sun
    outarray[i, 1] = phi_i[i]        ; Radians
    outarray[i, 2] = theta_i[i]      ; Radians
    outarray[i, 3] = time_0          ; Initial time (seconds)
    outarray[i, 4] = period_arr[i]   ; Period (seconds)
    outarray[i, 5] = v_arr[i]        ; Velocity (km/s)
    outarray[i, 6] = L_arr[i]        ; Blob size (R_sun)
    outarray[i, 7] = PSI_deg_i[i]    ; Polar angle (degrees)

    ; Launch blobs with the same velocity at the same time
    if fix(outarray[i, 5]) eq fix(outarray[i - 1, 5]) then outarray[i, 3] = outarray[i - 1, 3] else time_0 += 1.0
  endfor

  ; LoadStruc contains the output blob array and velocity information
  LoadStruc = {outarray: outarray, velocity: VELOCITY, period: PERIOD}

END
