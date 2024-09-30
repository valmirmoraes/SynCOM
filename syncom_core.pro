;+
;    Name:
;        SYNCOM_CORE
;
;    Purpose:
;        Generate synthetic solar wind images based on input parameters and blob data,
;        simulating the evolution of solar wind structures over time. The procedure simulates 
;        the outward propagation of blobs in the solar corona, producing time-dependent images 
;        representing the solar wind's transient behavior.
;
;    Calling Sequence:
;        SYNCOM_CORE, N_BLOBS=N_BLOBS, syncom_data, time_t=time_t, time0=time0, syncom_version=syncom_version, scale_factor=scale_factor, simple=simple
;
;    Example:
;        ; Minimal calling sequence:
;        SYNCOM_CORE, N_BLOBS=1000, syncom_data, time_t=10, time0=0
;
;        ; Using optional inputs, specific version and scale factor:
;        SYNCOM_CORE, N_BLOBS=1000, syncom_data, time_t=10, time0=0, syncom_version="example", scale_factor=2
;
;        ; Includes the keyword use, if set, for a sinusoidal velocity profile:
;        SYNCOM_CORE, N_BLOBS=1000, syncom_data, time_t=10, time0=0, syncom_version="example", scale_factor=2, /simple
;
;    Inputs:
;        N_BLOBS        ---    Number of blobs to simulate (free parameter).
;
;        time_t         ---    The end time of the simulation (in frames).
;
;        time0          ---    The start time of the simulation (in frames).
;
;    Optional Inputs:
;        syncom_version ---    Version of the SynCOM model (optional). Defaults to "v1" if not set.
;
;        scale_factor   ---    Factor used to scale the blob sizes in the image (optional). Defaults to 1.0 if not provided.
;
;    Keywords:
;        simple         ---    Defines the velocity profile to be used in the simulation. (Optional)
;                             0 - Solar velocity profile (default).
;                             1 - Sinusoidal velocity profile.
;
;    Outputs:
;        syncom_data    ---    3D array containing the synthetic solar wind images over time.
;                             Dimensions: [NX, NY, time_t - time0], where NX and NY are the grid sizes in the angular and radial directions.
;
;    Description of Procedure:
;        1. The procedure first initializes the model parameters using the SYNCOM_PRAMS and SYNCOMLOAD modules.
;        2. It generates a time series of synthetic solar wind images by simulating the radial propagation 
;           of blobs through the solar corona.
;        3. At each time step (from time0 to time_t), the SYNCOMIMAGE procedure is called to create an individual 
;           snapshot of the solar wind based on the positions, velocities, and sizes of the blobs.
;        4. If the "simple" keyword is set, a sinusoidal velocity profile is used for the blob propagation, otherwise 
;           the default solar velocity profile is applied.
;        5. The resulting data cube of images is stored in the syncom_data array and saved as an output file.
;
;    Notes:
;        - The procedure simulates solar wind propagation by calculating the radial movement of blobs, with the 
;          option to scale their size using the scale_factor parameter.
;        - The velocity profile can be customized using the "simple" keyword, allowing for sinusoidal velocity profile 
;          if desired.
;
;    Called by:
;        NONE
;
;    Calls:
;        SYNCOM_PRAMS, SYNCOMLOAD, SYNCOM_IMAGE
;    
;    Common Blocks:
;        None
;
;    Author and History:
;        Written by Valmir Moraes, Jun 2023
;        Revised for clarification and structure by Valmir Moraes, Sep 2024
;-


PRO SYNCOM_CORE, N_BLOBS=N_BLOBS, syncom_data, time_t=time_t, time0=time0, syncom_version, scale_factor, simple=simple
  t0 = systime(/s)  ; Start timer for performance tracking

  COMPILE_OPT IDL2  ; Use IDL2 options for array indexing and type enforcement

  ; ------------------- Initialize model parameters and load blob data -------------------
  SYNCOM_PRAMS, ModPramsStruct, SYNCOM_N_BLOBS=N_BLOBS  ; Get model parameters (grid size, number of blobs)
  NX        = ModPramsStruct.SYNCOM_NX       ; Grid size in the x-direction (position angle)
  NY        = ModPramsStruct.SYNCOM_NY       ; Grid size in the y-direction (radial distance)
  n_blobs   = ModPramsStruct.SYNCOM_N_BLOBS  ; Number of blobs to simulate
  cadence   = ModPramsStruct.SYNCOM_CADENCE  ; Simulation cadence (time steps)
  pixelSize = ModPramsStruct.SYNCOM_PIXEL    ; Pixel size in solar radii
  
  SYNCOMLOAD, ModPramsStruct, LoadStruc, simple=simple  ; Load blob data (positions, velocities, etc.)
  outarray = LoadStruc.outarray                         ; Extract blob data from loaded structure

  ; If syncom_version and scale_factor is not provided, set it to default ("v1") and 1.0
  if n_elements(syncom_version) eq 0 then syncom_version = "v1"
  if n_elements(scale_factor) eq 0 then scale_factor = 1.0
  
  Rsun2Km = 696000.0                 ; Solar radii to kilometers conversion factor
  spatialScale = Rsun2Km * pixelSize ; Calculate spatial scale based on instrument pixel size


  ; ------------------- Initialize simulation arrays and parameters ----------------------
  time_0       = (randomn(22, n_blobs) * 200. + 1.)         ; Initialize the start time for each blob (randomized)
  radial_i     = outarray[*, 0] / pixelSize                 ; Initial radial positions of blobs (converted to pixels)
  period_array = outarray[*, 4]                             ; Periods of reappearance for each blob (in seconds)
  v_array      = (outarray[*, 5] * cadence / spatialScale)  ; Radial velocities of blobs (converted to pixels/frame)
  L_array      = scale_factor * (outarray[*, 6]) / 0.1      ; Blob sizes, scaled by scale_factor (in degrees)
  PSI          = outarray[*, 7]                             ; Polar angles of the blobs (in degrees)

  ; Initialize the output array to store synthetic images
  syncom_data = dblarr(NX, NY, time_t - time0)


  ; -------------------- Generate synthetic images for each time step --------------------
  for t = time0, time_t-1 do begin
    ; Call SYNCOMIMAGE to generate the image at the current time step
    SYNCOMimage, ModPramsStruct, syncom_version, time_0, radial_i, v_array, period_array, L_array, PSI, t, img
        
    t_temp = t - time0             ; Calculate the current time step relative to time0
    syncom_data[*,*,t_temp] = img  ; Store the generated image in the syncom_data array
  endfor


  ; -------------------------- Save the output data cube to a file -----------------------
  save, syncom_data, ModPramsStruct, LoadStruc, filename = "SynCOM_" + strtrim(string(syncom_version), 2) + "_cube.sav"

  ; Print the total runtime for performance tracking
  print, "run time", systime(/s) - t0

END

