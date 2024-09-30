
  ;+
  ; Name:
  ;      correlation_vel
  ;
  ; Purpose:
  ;        Calculate the velocity in a distance-time plot by cross-correlating two signals
  ;        taken at different radial positions. The function can detrend the signals and interpolate
  ;        the cross-correlation peak to enhance accuracy.
  ;
  ;    Calling Sequence:
  ;        result = correlation_vel(data, r1=r1, r2=r2, L=L, order=order, time_scale=time_scale, /detrend, /interpolated)
  ;
  ;    Example:
  ;        ; Compute velocity without interpolation or detrending:
  ;        velocity_corr = correlation_vel(data, r1=0, r2=1, L=100.)
  ;
  ;        ; Compute velocity with interpolation for peak refinement:
  ;        velocity_corr = correlation_vel(data, r1=0, r2=1, L=100., order=2, /interpolated)
  ;
  ;        ; Compute velocity with interpolation and detrending:
  ;        velocity_corr = correlation_vel(data, r1=0, r2=1, L=100., order=2., time_scale=100., /detrend, /interpolated)
  ;
  ;    Inputs:
  ;        data         ---  3D array containing distance-time data (dimensions: angles x timesteps x radial positions).
  ;                          Alternatively, a 2D array (timesteps x radial positions) can be used if nangles = 1.
  ;        r1           ---  Initial radial position index.
  ;        r2           ---  Final radial position index.
  ;        L            ---  Length of the lag window for cross-correlation.
  ;        order        ---  Order of the polynomial for interpolation (optional).
  ;        time_scale   ---  Time scale for smoothing signals when detrending (optional).
  ;
  ;    Optional Inputs:
  ;        timeCadence  ---  Time cadence of the chosen instrument (default: 300 s).
  ;        pixelSize    ---  Pixel size of the chosen instrument (default: 0.014 solar radii per pixel).
  ;        Rsun2Km      ---  Conversion factor from solar radii to kilometers (default: 696,000 km per solar radii).
  ;
  ;    Keywords:
  ;        detrend      ---  If set, detrends the signals before performing cross-correlation.
  ;        interpolated ---  If set, performs polynomial interpolation to find the fitted peak of the cross-correlation.
  ;
  ;    Outputs:
  ;        velocity     ---  Array containing the calculated velocities for each angle.
  ;                          The velocity is given in units of km/s, derived from the lag between cross-correlation peaks.
  ; 
  ;    Description of Procedure:
  ;        1. The function performs cross-correlation between signals extracted from the
  ;           input data at two radial positions (r1 and r2) for each angular slice.
  ;        2. If detrend is set, it first removes the background trend from the signals using a moving
  ;           average with the given time_scale.
  ;        3. The cross-correlation function is calculated between the two signals, and the lag corresponding
  ;           to the peak of the cross-correlation is identified.
  ;        4. If interpolated is set, polynomial interpolation is applied to refine the peak position
  ;           and enhance the velocity estimate.
  ;        5. The velocity is calculated as the radial distance between r1 and r2, divided by the
  ;           time lag at the cross-correlation peak. The result is scaled by the time cadence and spatial scale
  ;
  ;    Notes:
  ;        - This function is useful for estimating radial flow velocities in distance-time plots, particularly
  ;          for solar wind and other transient phenomena.
  ;        - When cross-correlation is used, noise and trends can affect the accuracy of the peak detection.
  ;          Applying detrending and interpolation can mitigate these effects and produce more accurate results.
  ;
  ; Called by:
  ;    NONE
  ;
  ; Calls:
  ;    INTERPOLATED
  ; 
  ;    Author and History:
  ;        Written by Valmir Moraes, Jun 2024
  ;        Revised for clarification and structure by Valmir Moraes, Sep 2024
  ;-
  function correlation_vel, data, r1=r1, r2=r2, L=L, order=order, time_scale=time_scale, $
                          detrend=detrend, interpolated=interpolated, $
                          timeCadence=timeCadence, pixelSize=pixelSize, Rsun2Km=Rsun2Km

  ; Set default values for timeCadence, pixelSize, and Rsun2Km if not provided by the user
  if n_elements(timeCadence) eq 0 then timeCadence = 300.0   ; Default time cadence in seconds
  if n_elements(pixelSize)   eq 0 then pixelSize = 0.014     ; Default pixel size in solar radii
  if n_elements(Rsun2Km)     eq 0 then Rsun2Km = 696000.0    ; Solar radii to kilometers conversion factor

  spatialScale = Rsun2Km * pixelSize ; Calculate spatial scale based on instrument pixel size
  pixel2Rsun   = FIX(1. / pixelSize) ; Pixel size corresponding to 1 solar radius
  
  ; Get dimensions of data array (either 3D: [angles, timesteps, radial positions] or 2D: [timesteps, radial positions])
  sz_data = size(data, /DIMENSION)
  if n_elements(sz_data) eq 3 then begin
    nangles = sz_data[0]      ; Number of angular slices
    ntimesteps = sz_data[1]   ; Number of time steps
    nsteps = sz_data[2]       ; Number of radial positions
  endif else begin
    nangles = 1               ; Default to 1 angle if data is 2D
    ntimesteps = sz_data[0]   ; Number of time steps
    nsteps = sz_data[1]       ; Number of radial positions
  endelse

  ; Create an array of lags centered at zero for cross-correlation
  lags = (findgen(L + 1) - L / 2)

  ; Initialize the output velocity array
  velocity = dblarr(nangles)

  ; Loop over each angle to compute velocity via cross-correlation
  for x = 0, nangles - 1 do begin
    ; Extract signals for the specified radial positions (r1 and r2) at the current angle
    if n_elements(sz_data) eq 3 then begin
      signal1 = reform(data[x, *, r1 * pixel2Rsun])  ; Signal at radial position r1
      signal2 = reform(data[x, *, r2 * pixel2Rsun])  ; Signal at radial position r2
    endif else begin
      signal1 = reform(data[*, r1 * pixel2Rsun])     ; Single angle signal for r1
      signal2 = reform(data[*, r2 * pixel2Rsun])     ; Single angle signal for r2
    endelse

    ; Detrend the signals if the detrend keyword is set
    if keyword_set(detrend) then begin
      signal1 = signal1 - smooth(signal1, time_scale, /edge_trun)
      signal2 = signal2 - smooth(signal2, time_scale, /edge_trun)
    endif

    ; Calculate the cross-correlation between the two signals
    cc = c_correlate(signal1, signal2, lags, /double)
    max_cc = max(cc, i_peak)  ; Find the maximum of the cross-correlation function
    peak_lag = lags[i_peak]   ; Identify the lag corresponding to the peak

    ; If interpolation is requested and valid, apply polynomial interpolation to refine the peak
    if keyword_set(interpolated) and ((i_peak-2) ge 0) and ((i_peak+2) le (n_elements(lags)-1)) then begin
      ; Perform polynomial interpolation around the peak using a 5-point window
      peak_fit = interpoleted([lags[i_peak-2], lags[i_peak-1], lags[i_peak], lags[i_peak+1], lags[i_peak+2]], $
        [cc[i_peak-2], cc[i_peak-1], cc[i_peak], cc[i_peak+1], cc[i_peak+2]], order)
        
      ; Calculate the velocity based on the interpolated peak
      velocity[x] = (r2 - r1) * 71.0 * spatialScale / (peak_fit * timeCadence)

    endif else begin
      ; Calculate the velocity based on the non-interpolated peak lag
      velocity[x] = (r2 - r1) * 71.0 * spatialScale / (peak_lag * timeCadence)

    endelse
  endfor

  ; Return the array of calculated velocities for each angle
  return, velocity
end
