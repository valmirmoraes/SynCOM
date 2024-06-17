; Function to calculate the velocity in a distance-time plot using cross-correlation
function correlation_vel, data, r1, r2, L, order, time_scale, detrend=detrend, interpolated=interpolated
  ;+
  ; Name:
  ;      correlation_vel
  ;
  ; Purpose:
  ;      Calculate the velocity in a distance-time plot using cross-correlation.
  ;
  ; Example: 
  ;      velocity_corr = correlation_vel(data, 0, 1, 100.) ; correlated velocity 
  ;      
  ;      velocity_corr = correlation_vel(data, 0, 1, 100., 2, /interpolated) ; correlated velocity interpolated
  ;      
  ;      velocity_corr = correlation_vel(data, 0, 1, 100., 2, 100., /interpolated, /detrend) ; correlated velocity interpolated detrended
  ;      
  ; Inputs:
  ;      data         - 3D Array containing the distance-time data (dimensions: angles x timesteps x radial positions).
  ;      r1           - Initial radial position index.
  ;      r2           - Final radial position index.
  ;      L            - Length of the lag window for cross-correlation.
  ;      order        - Order of the polynomial for peak interpolation.
  ;      time_scale   - Time scale for smoothing profiles when detrending.
  ;
  ; Keywords:
  ;      detrend      - If set, detrends the profiles before cross-correlation.
  ;      interpolated - If set, performs interpolation to find the peak of the cross-correlation.
  ;
  ; Outputs:
  ;      velocity     - Array containing the calculated velocities for each angle.
  ;
  ; Author:
  ;      Written by Valmir Moraes, Jun 2023
  ;-

  ; Set default values for timeCadence and pixelSize if not provided
  if n_elements(timeCadence) eq 0 then timeCadence = 300.0 ; Default time cadence in seconds
  if n_elements(pixelSize)   eq 0 then pixelSize = 9744.0  ; Default pixel size in kilometers

  ; Get dimensions of data array
  sz_data = size(data, /DIMENSION)
  nangles = sz_data[0]      ; Number of angles
  ntimesteps = sz_data[1]   ; Number of time steps
  nsteps = sz_data[2]       ; Number of radial positions

  ; Create an array of lags for cross-correlation
  lags = (findgen(L + 1) - L / 2)

  ; Initialize the velocity array
  velocity = dblarr(nangles)

  ; Loop over each angle to calculate the velocity
  for x = 0, nangles - 1 do begin
    ; Extract profiles at the specified radial positions
    profile1 = reform(data[x, *, r1 * 71])
    profile2 = reform(data[x, *, r2 * 71])

    ; Detrend the profiles if the keyword is set
    if keyword_set(detrend) then begin
      profile1 = profile1 - smooth(profile1, time_scale, /edge_trun)
      profile2 = profile2 - smooth(profile2, time_scale, /edge_trun)
    endif

    ; Calculate the cross-correlation between the profiles
    cc = c_correlate(profile1, profile2, lags, /double)
    max_cc = max(cc, i_peak)  ; Find the peak of the cross-correlation
    peak_lag = lags[i_peak]   ; Corresponding lag at the peak

    ; Interpolate the peak if the keyword is set
    if keyword_set(interpolated) and ((i_peak-2) ge 0) and ((i_peak+2) le (n_elements(lags)-1))  then begin
      ; Interpolate the peak using the specified order
      peak_fit = interpoleted([lags[i_peak-2], lags[i_peak-1], lags[i_peak], lags[i_peak+1], lags[i_peak+2]], $
        [cc[i_peak-2], cc[i_peak-1], cc[i_peak], cc[i_peak+1], cc[i_peak+2]], order)
      ; Calculate the velocity based on the interpolated peak
      velocity[x] = (r2 - r1) * 71.0 * pixelSize / (peak_fit * timeCadence)
    endif else begin
      ; Calculate the velocity based on the peak lag
      velocity[x] = (r2 - r1) * 71.0 * pixelSize / (peak_lag * timeCadence)
    endelse
  endfor

  ; Return the calculated velocity array
  return, velocity
end



; Function to perform interpolation and find the peak
function interpoleted, x, y, order
  ;+
  ; Name:
  ;      interpoleted
  ;
  ; Purpose:
  ;      Perform a polynomial interpolation to find the peak in the cross-correlation.
  ;      Can be used for any format that has a x and y values.
  ;
  ; Example:
  ;      peak_fit = interpoleted([lags[i_peak-2], lags[i_peak-1], lags[i_peak], lags[i_peak+1], lags[i_peak+2]], $
  ;                              [cc[i_peak-2], cc[i_peak-1], cc[i_peak], cc[i_peak+1], cc[i_peak+2]], order)
  ;                              
  ; Inputs:
  ;      x        - Array of x-values (lags).
  ;      y        - Array of y-values (cross-correlation values).
  ;      order    - Order of the polynomial for interpolation.
  ;
  ; Outputs:
  ;      peak_fit - x-value corresponding to the peak of the interpolated polynomial.
  ;
  ; Author:
  ;      Written by Valmir Moraes, Jun 2023
  ;-

  ; Set the interpolation step size
  dx = 0.01
  x_fit = findgen((max(x) - min(x)) / dx) * dx + min(x)

  ; Initialize the fit array
  y_fit = fltarr(n_elements(x_fit))

  ; Fit a polynomial of the specified order to the data
  fit = svdfit(x, y, order + 1)
  for i = 0, order do y_fit += fit[i] * x_fit^i

  ; Find the maximum value of the fit and its corresponding x-value
  mx = max(y_fit, imx)
  peak_fit = x_fit[imx]

  ; Return the x-value corresponding to the peak of the fit
  return, peak_fit
end
