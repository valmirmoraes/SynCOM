;+
;    Name:
;        SYNCOMIMAGE
;
;    Purpose:
;        Generates a synthetic solar wind image for a specific time step, based on the positions,
;        velocities, and other properties of the blobs in the model. This simulates the dynamic
;        behavior of solar wind structures over time by adding Gaussian-shaped blobs to a grid.
;
;    Calling Sequence:
;        SYNCOMIMAGE, ModPramsStruct, syncom_version, time_0, radial_i, v_array, period_array, L_array, PSI, time_t, img
;
;    Example:
;        ; Generate an image at time step 10:
;        SYNCOMIMAGE, ModPramsStruct, "v1", time_0, radial_i, v_array, period_array, L_array, PSI, 10, img
;
;    Inputs:
;        ModPramsStruct   ---   Structure containing the model parameters, including:
;                               - SYNCOM_NX: Image size in the position angle direction.
;                               - SYNCOM_NY: Image size in the radial direction.
;                               - SYNCOM_N_BLOBS: Number of blobs to simulate.
;
;        syncom_version   ---   Version name for the SynCOM simulation (e.g., "v1").
;
;        time_0           ---   Initial time offset for blob appearance (free parameter).
;
;        radial_i         ---   Array of initial radial positions for each blob (in pixels).
;
;        v_array          ---   Array of radial velocities for each blob (in pixels/frame).
;
;        period_array     ---   Array of periods for blob reappearance at the initial radial position (in seconds).
;
;        L_array          ---   Array of blob sizes (in degrees) for each blob.
;
;        PSI              ---   Array of polar angle values (in degrees) for each blob.
;
;        time_t           ---   Current time step (in frames) for the simulation.
;
;    Outputs:
;        img              ---   2D array representing the generated synthetic solar wind image at the current time step.
;
;    Description of Procedure:
;        1. The procedure calculates the position of each blob based on its velocity, initial radial position, and the current time step.
;        2. Gaussian blobs are generated for each blob in the grid using their polar angle, radial position, size, and velocity.
;        3. Blobs are added to the image grid with perturbations based on their period and velocity.
;        4. The resulting image is the sum of all the blobs and represents the solar wind structure at the current time step.
;        5. The final image is saved in FITS format for further analysis.
;
;    Notes:
;        - Blobs are Gaussian-shaped, and their size is determined by the input parameters.
;        - The simulation can handle multiple blobs and updates their positions based on their velocities at each time step.
;        - The time_0 parameter allows the user to offset the starting time of blob appearance, adding flexibility to the simulation.
;
;    Called by:
;        SYNCOM
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

PRO SYNCOMimage, ModPramsStruct, syncom_version, time_0, radial_i, v_array, period_array, L_array, PSI, time_t, img

  ; Start time of the procedure to measure runtime
  t0 = systime(/s)

  ; Number of blobs to simulate
  n_blobs = ModPramsStruct.SYNCOM_N_BLOBS

  ; Size of the image grid along the x-axis (position angle) and y-axis (radial distance)
  NX = ModPramsStruct.SYNCOM_NX
  NY = ModPramsStruct.SYNCOM_NY

  ; Calculate the radial position of each blob at the current time step
  radial_t = (time_t + time_0) * v_array  ; units in pixels

  ; Create an empty array for storing the synthetic image (size: 3600 x 659)
  img = dblarr(3600, 659)

  ; Loop over all blobs to generate and add them to the image
  for i = 0, n_blobs - 1 do begin

    ; Create a Gaussian blob with position (PSI[i], radial_i[i]) and standard deviation (blob size)
    a_arr = gaussianwave(npixel=[NX, NY], avr=[PSI[i], radial_i[i]], st_dev=[L_array[i], 2*L_array[i]])

    ; Add additional perturbations (repeated blobs) based on the blob's period and velocity
    a_arr = a_arr + shift(a_arr, [0, ( 2) * period_array[i] * v_array[i] + ( 2) * L_array[i]]) + $
                    shift(a_arr, [0, ( 4) * period_array[i] * v_array[i] + ( 4) * L_array[i]]) + $
                    shift(a_arr, [0, ( 6) * period_array[i] * v_array[i] + ( 6) * L_array[i]]) + $
                    shift(a_arr, [0, (-2) * period_array[i] * v_array[i] + (-2) * L_array[i]]) + $
                    shift(a_arr, [0, (-4) * period_array[i] * v_array[i] + (-4) * L_array[i]]) + $
                    shift(a_arr, [0, (-6) * period_array[i] * v_array[i] + (-6) * L_array[i]])

    ; Apply radial shift to account for the blob's movement at the current time step
    a_arr = shift(a_arr, [0, radial_t[i]])

    ; Add the blob to the image
    img = temporary(img) + a_arr
  endfor

  ; Save the generated image as a FITS file
  WRITEFITS, "SynCOM_" + strtrim(string(syncom_version), 2) + "_" + strtrim(string(time_t), 2) + ".fts", img

  ; Print the runtime of the procedure for this time step
  print, "run time", time_t, systime(/s) - t0

END
