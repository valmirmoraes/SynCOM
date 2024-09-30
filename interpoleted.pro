;+
;    Name:
;        interpoleted
;
;    Purpose:
;        Perform polynomial interpolation to find the peak in the cross-correlation or any
;        dataset where x and y values are provided. The function uses a least-squares fitting
;        approach to fit a polynomial of the specified order to the input data and returns
;        the x-value corresponding to the peak of the fit.
;
;    Calling Sequence:
;        peak_fit = interpoleted(x, y, order)
;
;    Inputs:
;        x        ---  Array of x-values (e.g., lags in cross-correlation or any independent variable).
;        y        ---  Array of y-values (e.g., cross-correlation values or dependent variable).
;        order    ---  The order of the polynomial for interpolation (e.g., 2 for quadratic, 3 for cubic).
;
;    Outputs:
;        peak_fit ---  The x-value corresponding to the peak of the interpolated polynomial fit.
;                      This is the maximum of the fitted curve and represents the best estimate
;                      of the peak position in x.
;
;    Description of Procedure:
;        1. The function first determines the range of x-values and creates a finer grid (`x_fit`)
;           over which the polynomial will be evaluated. The step size for the interpolation grid is `dx = 0.01`.
;        2. A polynomial fit is applied to the original data (x, y) using Singular Value Decomposition (SVD),
;           which is a robust method for solving least-squares fitting problems.
;        3. The polynomial coefficients from the fit are used to evaluate the fitted curve (`y_fit`) over
;           the finer grid.
;        4. The maximum of the fitted curve (`y_fit`) is identified, and the corresponding x-value (`peak_fit`)
;           is returned. This x-value represents the interpolated peak location.
;
;    Example:
;        ; Given lags and cross-correlation values, find the interpolated peak:
;        peak_fit = interpoleted([lags[i_peak-2], lags[i_peak-1], lags[i_peak], lags[i_peak+1], lags[i_peak+2]], $
;                                [cc[i_peak-2], cc[i_peak-1], cc[i_peak], cc[i_peak+1], cc[i_peak+2]], 2)
;        ; This will fit a quadratic curve (order 2) and return the interpolated peak.
;
;    Notes:
;        This function is useful in situations where data is discrete or noisy, and a smooth polynomial
;        interpolation is desired to accurately identify the peak location.
;
;    Modification History:
;        Written by Valmir Moraes, Jan 2024
;-

function interpoleted, x, y, order

  ; Define the step size for interpolation. A finer grid (dx = 0.01) is created for fitting.
  dx = 0.01

  ; Create a grid of x-values for evaluating the fitted polynomial. The grid spans the
  ; range of the original x-values with step size dx.
  x_fit = findgen((max(x) - min(x)) / dx) * dx + min(x)

  ; Initialize an array to store the fitted y-values corresponding to the fine grid (x_fit).
  y_fit = fltarr(n_elements(x_fit))

  ; Perform the polynomial fit using SVD (Singular Value Decomposition).
  ; The result is a set of coefficients for the polynomial of the specified order.
  fit = svdfit(x, y, order + 1)

  ; Evaluate the polynomial on the finer grid (x_fit) using the fitted coefficients.
  for i = 0, order do y_fit += fit[i] * x_fit^i

  ; Identify the maximum value of the fitted polynomial (y_fit) and find the corresponding
  ; x-value (peak_fit) where the maximum occurs.
  mx = max(y_fit, imx)  ; 'imx' is the index of the maximum in y_fit
  peak_fit = x_fit[imx] ; The x-value corresponding to the peak

  ; Return the x-value that corresponds to the peak of the fitted polynomial.
  return, peak_fit

end
