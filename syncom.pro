PRO SYNCOM, ModPramsStruct,LoadStruc,syncom_data, syncom_version, time_t, time0
  t0=systime(/s)

  ;+
  ; Name:
  ;
  ;      SynCOM
  ;
  ;
  ; Purpose: Describe what your model does here
  ;
  ; Calling sequence:
  ;
  ;          SYNCOM,r,theta,phi,ModPramsStruct, ModSolStruct
  ;
  ;
  ;
  ; Inputs:
  ;          r, theta, phi -- position in 3D space where model is to be evaluated
  ;                               r in units of RSUN, th, ph in RADIANS
  ;
  ;          ModPramsStruct - structure associated with model, containing
  ;                           model name (SYNCOM), model parameters
  ;                           set up in templateprams.pro
  ;
  ;
  ; Outputs: ModSolStruct - Solution of model, containing density,temperature,
  ;                         pressure
  ;
  ;
  ; Called by None
  ;
  ; Calls FOR_HYDROCALC, SYNCOM_RHO,
  ;    * if you want to add a hydrostatic density/pressure background
  ;
  ;
  ; Author and history:
  ;
  ;   Written by Valmir Moraes   Jun 2023
  ;-

  COMPILE_OPT IDL2 ;default long and square brackets for array subscripts

  ;extract parameter variables from params structure
  ;
  ;  t=tag_names(ModPramsStruct)
  ;  for i=0,n_elements(t)-1 do void=execute(t[i]+'=ModPramsStruct.(i)')

  if n_elements(syncom_version) eq 0.0 then syncom_version="v1"
  ;  if n_elements(ModPramsStruct) ne 0.0 and n_elements(LoadStruc) ne 0.0 then begin
  ;
  ;;    save, ModPramsStruct,LoadStruc, filename="SynCOM_"+strtrim(string(syncom_version),2)+"_variables.sav"
  ;
  ;  endif else restore, "/Users/vpereir1/WORKING/SYNCOM/model/SynCOM_sample_50_blobs/SynCOM_v1_variables.sav"

  NX       = ModPramsStruct.SYNCOM_NX
  NY       = ModPramsStruct.SYNCOM_NY
  n_blobs  = ModPramsStruct.SYNCOM_N_BLOBS              ; number of blobs

  outarray = LoadStruc.outarray

  time_0       = (randomn(22,n_blobs)*200.+1.)
  radial_i     = outarray[*,0]                 ; units of Rsun
  radial_i     = (radial_i/0.014)              ; units of pixel
  period_array = outarray[*,4]                 ; units in seconds
  ;  period_array = smooth(period_array,5, /edge_trunc)                 ; units in seconds
  ;  period_array = outarray[*,4]*0 + 1.5*3600    ; units in seconds
  ;  period_array = period_array/300.             ; units in seconds
  ;  period_array = (848./ (period_array/300.) )  ; units in seconds
  v_array      = outarray[*,5]                 ; units in km/seconds
  v_array      = (v_array * 300./9744.)        ; units in pixels/frame
  L_array      = (outarray[*,6])/0.1                 ; units in degrees
  ;  L_array      = L_array[(sort(( L_array )))]/0.1           ; units in degrees

  ;  L_array      = (randomn(seed,n_blobs)*0.+0.5)/0.1 ; units in degrees

  PSI          = outarray[*,7]                 ; units in degrees
  ;
  ;  f_=minmax(period_array)/3600
  ;  v_=minmax(v_array)*(9744./300.)
  ;  r_=minmax(L_array)*0.1
  ;
  ;  fname='constraints.txt'
  ;
  ;  openw,21,fname,/append
  ;  printf,21,f_,v_,r_,FORMAT='(F10.6,2X,F10.6)'
  ;  close,21

  ;  PSI = [0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330]*10.

  syncom_data = dblarr(nx,ny,time_t-time0)

  for t=time0,time_t-1 do begin
    SYNCOM_image, ModPramsStruct, syncom_version, time_0,radial_i,v_array,period_array, L_array, PSI, t, img

    t_temp = t-time0
    syncom_data[*,*,t_temp] = img
  endfor

  save, syncom_data,ModPramsStruct,LoadStruc, filename="SynCOM_"+strtrim(string(syncom_version),2)+"_cube.sav"

  print, "run time", systime(/s)-t0
END
