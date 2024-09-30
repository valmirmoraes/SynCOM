;+
;    Name:
;        SYNCOM_PRAMS
;
;    Purpose:
;        To create a structure that defines the parameters and settings for the SYNCOM model.
;        The structure is used by driver routines to simulate solar wind blobs and generate synthetic images.
;        The structure is stored in `ModPramsStruct` and contains essential physical properties, model
;        configuration, and simulation settings.
;
;    Calling Sequence:
;        SYNCOM_PRAMS, ModPramsStruct, SYNCOM_N_BLOBS=1000
;
;    Example:
;        ; Create a parameter structure with 1000 blobs and default settings:
;        SYNCOM_PRAMS, ModPramsStruct, SYNCOM_N_BLOBS=1000
;
;        ; Save parameters to a file:
;        SYNCOM_PRAMS, ModPramsStruct, SYNCOM_N_BLOBS=1000, SAVEPRAMS='params.sav'
;
;    Inputs:
;        SYNCOM_N_BLOBS       ---   Number of blobs to simulate (free parameter).
;                                   DEFAULT: 1000
;
;    Optional Inputs:
;        SYNCOM_CADENCE       ---   Time interval between successive frames (in seconds).
;                                   DEFAULT: 300.0
;
;        SYNCOM_PIXEL         ---   Spatial resolution per pixel (in units of solar radii).
;                                   DEFAULT: 0.014
;
;        SYNCOM_NX            ---   Resolution of the simulated image in the angular direction.
;                                   Position angle range: 0 to 360 degrees.
;                                   UNITS: Pixels
;                                   DEFAULT: 3600
;
;        SYNCOM_NY            ---   Resolution of the simulated image in the radial direction.
;                                   Radial distance range: 5 to 14.226 solar radii.
;                                   UNITS: Pixels
;                                   DEFAULT: 659
;
;        SYNCOM_SIZE          ---   Controls the size of the blobs in the simulation.
;                                   Blob sizes range from 0.1 to 1.0 R_sun.
;                                   DEFAULT: 1.0
;
;        SYNCOM_ACC           ---   Enables or disables blob acceleration.
;                                   1: ON, 0: OFF
;                                   DEFAULT: 0 (OFF)
;
;        SYNCOM_INITIAL_R_SUN ---   Initial radial position where blobs emerge (in solar radii).
;                                   DEFAULT: 1.0 R_sun
;
;        SYNCOM_NOISE_LEVEL   ---   Background noise level to be added to the simulation.
;                                   DEFAULT: 0.0 (No noise)
;
;        SYNCOM_MAX_INTENSITY  ---  Maximum allowed intensity for blobs.
;                                   DEFAULT: 1.0E-10
;
;        SYNCOMFILE           ---   Name of the file containing statistical data for the model.
;                                   DEFAULT: $FORWARD_DB/syncom_20140414_densfix.sav
;
;        DATE                 ---   Specifies the date to retrieve the datacube from $FORWARD_DB/SYNCOM.
;                                   Overridden if SYNCOMFILE is set.
;
;    Optional Keywords:
;        SAVEPRAMS            ---   If set, saves the model parameters to a specified file.
;                                   Can also be set to 1 to overwrite the parameter array.
;
;        READPRAMS            ---   Reads parameters from a file or structure and overwrites
;                                   existing parameters.
;
;    Outputs:
;        ModPramsStruct       ---   Structure containing the SYNCOM model parameters, including:
;                                   - NAME: 'SynCOM'
;                                   - LABEL: 'SynCOM'
;                                   - T0: Initial time in the simulation
;
;    Description of Procedure:
;        1. The procedure generates a structure (ModPramsStruct) with the model parameters
;           necessary for the SYNCOM simulation. This structure includes cadence, pixel size,
;           blob count, size scaling, and other physical properties.
;        2. The procedure reads parameters from a file (if provided), or directly from input arguments.
;           Overwritten parameters are handled accordingly.
;        3. ModPramsStruct is then used by other SYNCOM procedures to generate synthetic
;           solar wind simulations.
;
;    Notes:
;        - ModPramsStruct contains all the necessary parameters to define the simulation setup.
;        - This procedure does not perform the simulation itself but creates the input structure
;          required for other SYNCOM routines to carry out the simulation.
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
;        Written by Valmir Moraes, Jun 2023
;        Revised for clarity by Valmir Moraes, Sep 2024
;-

PRO SYNCOM_PRAMS,$
  ;************* don't delete next line
  outarray,syncomfile=syncomfile, $
  date=date,working_dir=working_dir,$
  ;*************add your own model parameters, e.g. time=time0
  SYNCOM_N_BLOBS=SYNCOM_N_BLOBS0, $
  SYNCOM_CADENCE=SYNCOM_CADENCE0,SYNCOM_PIXEL=SYNCOM_PIXEL0,$
  SYNCOM_NX=SYNCOM_NX0,SYNCOM_NY=SYNCOM_NY0,$
  SYNCOM_ACC=SYNCOM_ACC0,SYNCOM_SIZE=SYNCOM_SIZE0,SYNCOM_INITIAL_R_SUN=SYNCOM_INITIAL_R_SUN0, $
  SYNCOM_NOISE_LEVEL=SYNCOM_NOISE_LEVEL0,SYNCOM_MAX_INTENSITY=SYNCOM_MAX_INTENSITY0, $
  ;*************don't delete below
  saveprams=saveprams,readprams=readprams


  slash=path_sep()

  COMPILE_OPT IDL2 ;default long and square brackets for array subscripts

  if keyword_set(syncomfile) then syncomfilesave=syncomfile else syncomfilesave=''

  ;
  ; set parameter defaults
  ;

  if keyword_set(readprams) then begin
    ; read parameter file (a structure file or structure)
    case datatype(readprams) of
      'STR': restgen,inarray,file=readprams
      'STC': inarray=readprams
      else: message, 'must provide a named readprams file or a structure'
    endcase
    t=tag_names(inarray)
    for i=0,n_elements(t)-1 do void=execute(t[i]+'_rd=inarray.(i)')
  endif

  ; if you want temperature keep this next 
  syncom_cadence=n_elements(syncom_cadence0) eq 0?(n_elements(syncom_cadence_rd) eq 0?300.0:syncom_cadence_rd):syncom_cadence0
  syncom_pixel=n_elements(syncom_pixel0) eq 0?(n_elements(syncom_pixel_rd) eq 0?0.014:syncom_pixel_rd):syncom_pixel0
  syncom_n_blobs=n_elements(syncom_n_blobs0) eq 0?(n_elements(syncom_n_blobs_rd) eq 0?1000.0:syncom_n_blobs_rd):syncom_n_blobs0
  syncom_acc=n_elements(syncom_acc0) eq 0?(n_elements(syncom_acc_rd) eq 0?0.0:syncom_acc_rd):syncom_acc0
  syncom_initial_R_sun=n_elements(syncom_initial_R_sun0) eq 0?(n_elements(syncom_initial_R_sun_rd) eq 0?5.0:syncom_initial_R_sun_rd):syncom_initial_R_sun0
  syncom_time=n_elements(syncom_time0) eq 0?(n_elements(syncom_time_rd) eq 0?0.0:syncom_time_rd):syncom_time0
  syncom_dens_scale=n_elements(syncom_dens_scale0) eq 0?(n_elements(syncom_dens_scale_rd) eq 0?1e8:syncom_dens_scale_rd):syncom_dens_scale0
  syncom_size=n_elements(syncom_size0) eq 0?(n_elements(syncom_size_rd) eq 0?1.0:syncom_size_rd):syncom_size0
  verbose=n_elements(verbose0) eq 0?(n_elements(verbose_rd) eq 0?0:verbose_rd):verbose0
  syncom_nt=n_elements(syncom_nt0) eq 0?(n_elements(syncom_nt_rd) eq 0?848.0:syncom_nt_rd):syncom_nt0
  syncom_nx=n_elements(syncom_nx0) eq 0?(n_elements(syncom_nx_rd) eq 0?3600.0:syncom_nx_rd):syncom_nx0
  syncom_ny=n_elements(syncom_ny0) eq 0?(n_elements(syncom_ny_rd) eq 0?659.0:syncom_ny_rd):syncom_ny0
  syncom_noise_level=n_elements(syncom_noise_level0) eq 0?(n_elements(syncom_noise_level_rd) eq 0?0.0:syncom_noise_level_rd):syncom_noise_level0
  syncom_max_intensity=n_elements(syncom_max_intensity0) eq 0?(n_elements(syncom_max_intensity_rd) eq 0?1.0E-14:syncom_max_intensity_rd):syncom_max_intensity0

  ;
  ; need to be careful with SYNCOMFILE and DATE
  ;

  if not keyword_set(syncomfile) and not keyword_set(date) then begin
    print,'*****************************************************************'
    print,'*****************************************************************'
    print,'*****************************************************************'
    print,'*****************************************************************'
    print,'No file or date entered, so will use default 20140414 datacube'
    print,'*****************************************************************'
    print,'*****************************************************************'
    print,'*****************************************************************'
    print,'*****************************************************************'
  endif

  usesyncom=0
  if keyword_set(syncomfile) then begin
    if file_exist(syncomfile) then usesyncom = 1 else begin
      if file_exist(file_dirname(GET_ENVIRON('FORWARD_DB'))+slash+file_basename(GET_ENVIRON('FORWARD_DB'))+slash+'SYNCOM_DB'+slash+syncomfile) then usesyncom=1 else begin
        syncomfile=0
        if not keyword_set(date) then begin
          if keyword_set(nowidgmess) then message,/info,' The SYNCOM datacube referred to in this parameter file is not in the local directory or $FORWARD_DB/SYNCOM_DB, so will use default (20140414) datacube' else d = dialog('SYNCOM datacube referred to in this parameter file is not in the local directory or $FORWARD_DB/SYNCOM_DB, so will use default (20140414) datacube',/warning)
          endif else begin
          if keyword_set(nowidgmess) then message,/info,'The SYNCOM datacube referred to in this parameter file is not in the local directory, so will use date provided ' else d = dialog('The SYNCOM datacube referred to in this parameter file is not in the local directory, so will use date provided',/warning)
        endelse
      endelse
    endelse
  endif


  if not keyword_set(date) and usesyncom eq 0 then begin
    syncomfile=file_dirname(GET_ENVIRON('FORWARD_DB'))+slash+file_basename(GET_ENVIRON('FORWARD_DB'))+slash+'SYNCOM_DB'+slash+'syncom_20140414_densfix.sav'
    usesyncom=1
  endif

  ;
  ; SYNCOMFILE overwrites all
  ;

  if usesyncom eq 1 then begin

    ;
    ; use date ssociated with syncomfile
    ;
    dateread=strmid(file_basename(syncomfile),7,8)
    year=strmid(dateread,0,4)
    month=strmid(dateread,4,2)
    day=strmid(dateread,6,2)
    dateuse=year+'-'+month+'-'+day
    now=dateuse

  endif else begin

    ;
    ; if DATE set and no SYNCOMFILE, get it from $DB
    ; use the closest available
    ;

    dateuse=date

    date_exist_db=file_search(file_dirname(GET_ENVIRON('FORWARD_DB'))+slash+file_basename(GET_ENVIRON('FORWARD_DB'))+slash+'SYNCOM_DB'+slash+'*',count=nfiles)
    date_array=(long(strmid(file_basename(date_exist_db),7,8)))
    dateread=strtrim(string(long(date_array)),2)
    year=strmid(dateread,0,4)
    month=strmid(dateread,4,2)
    day=strmid(dateread,6,2)

    nowarray=year+'-'+month+'-'+day

    datesec=anytim(date)
    datesec_array=anytim(nowarray)
    datediff=abs(datesec_array-datesec)
    test=where(datediff eq min(datediff))

    now=nowarray[test]
    now=now[0]
    syncomfile=date_exist_db[test]
    syncomfile=syncomfile[0]
    print,'User date is:',date
    print,'Nearest date is:',now
    print,'Using nearest file:',syncomfile

  endelse

  ;
  ; information for label
  ;

  exlab='!c observer date='+dateuse

  label='SynCOM model, cube='+now+exlab
  name='syncom'

  ;
  ; set up  pram input array
  ;


  pramarray={Name:name,$
    syncomfile:syncomfilesave,$
    syncom_cadence:syncom_cadence,syncom_pixel:syncom_pixel, $
    syncom_n_blobs:syncom_n_blobs, $
    syncom_acc:syncom_acc, $
    syncom_time:syncom_time, $
    syncom_initial_R_sun:syncom_initial_R_sun, $
    syncom_size:syncom_size, $
    syncom_nx:syncom_nx,syncom_ny:syncom_ny, $
    syncom_noise_level:syncom_noise_level, $
    syncom_max_intensity:syncom_max_intensity $
  }
  
  ;
  ; if requested, save input parameters to a file (stored in file named saveprams if it is a string)
  ;
  
  if keyword_set(saveprams) then begin
    savefilename=saveprams
    if n_elements(working_dir) eq 1 and datatype(saveprams) eq 'STR' then begin
      if working_dir ne '' then savefilename=working_dir+slash+saveprams
    endif

    case 1 of
      datatype(saveprams) eq 'STR': savegen,pramarray,file=savefilename,/replace
      else: saveprams=pramarray
    endcase
  endif
  
  file_name = '/Users/vpereir1/IDLWorkspace/Default/stereo_analysis.sav'


  outarray={Name:name,$
    Label:label,$
    filename:file_name,$
    syncom_cadence:syncom_cadence,syncom_pixel:syncom_pixel, $
    syncom_n_blobs:syncom_n_blobs, $
    syncom_acc:syncom_acc, $
    syncom_time:syncom_time, $
    syncom_nx:syncom_nx,syncom_ny:syncom_ny, $
    syncom_initial_R_sun:syncom_initial_R_sun, $
    syncom_size:syncom_size, $
    syncom_noise_level:syncom_noise_level, $
    syncom_max_intensity:syncom_max_intensity}

END
