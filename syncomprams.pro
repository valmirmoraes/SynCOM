PRO SYNCOMPRAMS,$
  ;************* don't delete next line
  outarray,syncomfile=syncomfile, $
  date=date,working_dir=working_dir,$
  ;************* keep the next two if you want temperature and/or field-aligned flow
  hydro=hydro0,$
  cdensprof=cdensprof,ct0=ct0,$
  odensprof=odensprof,ot0=ot0,$
  ;*************add your own model parameters, e.g. time=time0
  SYNCOM_CADENCE=SYNCOM_CADENCE0, SYNCOM_NT=SYNCOM_NT0,$
  SYNCOM_ACC=SYNCOM_ACC0, SYNCOM_N_BLOBS=SYNCOM_N_BLOBS0, SYNCOM_TIME=SYNCOM_TIME0,$
  SYNCOM_DENS_SCALE=SYNCOM_DENS_SCALE0, SYNCOM_INITIAL_R_SUN=SYNCOM_INITIAL_R_SUN0,SYNCOM_SIZE=SYNCOM_SIZE0, $
  VERBOSE=VERBOSE0, syncom_noise_level=syncom_noise_level0, syncom_max_intensity=syncom_max_intensity0, $
  ;*************don't delete below
  saveprams=saveprams,readprams=readprams
  ;+
  ;
  ;Name: SYNCOMPRAMS
  ;
  ;Purpose: To create structure containing information about SYNCOM
  ; To be called by driver routine and resulting structure will be named
  ;
  ; ModPramsStruct (with ModPramsStruct.name='syncom')
  ;
  ;
  ; Called by FOR_MODELDEFAULTS
  ;
  ;Keyword Inputs:
  ;
  ; PHYSICAL PROPERTIES
  ;
  ;  SYNCOM_CADENCE - Time cadence: Provided by the instrument
  ; used to scale the temporal statistics appropriately depending
  ;                      on what instrument was used to create them
  ;                        UNITS SECONDS/FRAMES
  ;                        DEFAULT 300.d0
  ;                              ***not being used***
  ;
  ;  SYNCOM_N_BLOBS      - Number of Blobs (free parameter)
  ;                        DEFAULT 1000.0
  ;
  ;  SYNCOM_ACC          - Turns acceleration (1) ON
  ;                        DEFAULT 0.d0 : OFF
  ;       ***placeholder***
  ;
  ;  SYNCOM_TIME         - Model Time T -- affects blob location
  ;                        UNITS SECONDS
  ;                        DEFAULT 0.d0
  ;
  ;  SYNCOM_INITIAL_R_SUN - Initial radial position
  ;       position where blobs first emerge
  ;                      set to 1 Rsun for FORWARD (free parameter)
  ;                        UNITS R_SUN
  ;                        DEFAULT 1.d0
  ;  SYNCOM_SIZE -- blob spatial scaling (free parameter)
  ;       if set to 1, the edge of each blob
  ;         just touches the edge of the next blob
  ;
  ;  SYNCOM_DENS_SCALE   - Density scale fator
  ;         scaling factor for density
  ;                               needed because initial analysis done in intensity
  ;                        DEFAULT 1E8
  ;
  ;
  ;   SYNCOMFILE: filename (including extension) of the save file of
  ;       file containig statistical data found in $FORWARD_DB/SYNCOM directory
  ;       Default will be set to $FORWARD_DB/syncom_20140414_densfix.sav
  ;
  ;     NOTE ---  SYNCOMFILE OVERWRITES DATE IF SET AND DIFFERENT
  ;               BE CAREFUL FOR EXAMPLE IF YOU WANT CMER AND BANGLE TO BE FOR
  ;               A SOMEWHAT DIFFERENT DATE THAN THE ONE IN THE CUBE - in this
  ;               case, you should explicitly define CMER, and BANG as keywords
  ;               In other words -- if you use keyword SYNCOMFILE, DATE will
  ;               be completely ignored and actually replaced by date from name of SYNCOMFILE.
  ;               Note widget should not send SYNCOMFILE explicitly, that is,
  ;               for most calls it will send DATE but not SYNCOMFILE;
  ;               unless SYNCOMFILE as a file is selected via the widget
  ;               or if READPRAMS is set it will use that SYNCOMFILE
  ;               (if there is one; generally, it will not be saved in READPRAMS
  ;               unless it is an original keyword)
  ;
  ;  DATE ---     if this is set,  it will look for datacube
  ;               for this date (or close to it) in $FORWARD_DB/SYNCOM
  ;               If SYNCOMFILE set, it will overrule and overwrite DATE.
  ;
  ; HYDRO, CDENSPROF, ODENSPROF, CT0, OT0:
  ;               how to handle the plasma throughout the corona.
  ;               DEFAULT HYDRO 3
  ;               Vasquez 2003
  ;
  ;       FOR CDENSPROF, ODENSPROF, CTO, OT0 DEFAULTS SEE NUMCUBE/FOR_HYDRODEFAULTS

  ;
  ; BOOKKEEPING
  ;
  ;
  ;
  ; SAVEPRAMS - if keyword set to a string, write parameters to filename
  ;                       (which is the keyword value saveprams)
  ;                       or if set to 1, then replace with pramarray
  ;
  ;
  ; READPRAMS - if keyword set, read in parameters from filename
  ;                       (which is the keyword value filename)
  ;                       or if a structure than read directly
  ;                       NOTE, flagged keywords will overwritten
  ;
  ; ModPramsStruct Outputs:
  ;
  ;               As above, plus
  ;
  ;               NAME --- SynCOM -- so that procedure can be called in intensint
  ;               LABEL -- SynCOM -- for plot label
  ;               MAGMOD -- 0 -- meaning it is NOT a magnetized model
  ;     (change to 1 if you have magnetic field
  ;
  ;               T0
  ;
  ;
  ;Output:outarray - structure containing keyword output model parameters
  ;
  ;Common Blocks: None
  ;
  ; Author and history:
  ;
  ;   Written by Valmir Moraes   Jun 2023
  ;-

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

  ; Parameters
  ; If keyword set for a given parameter, then this is used.
  ; If keyword not specified, then use value from readparams if set. If readparams not set,
  ; uses the default values as listed in these following statements

  ; if you want field-aligned velocity keep this parameter-- at the moment default value is zero, no flow
  ; velimpose=n_elements(velimpose0) eq 0?(n_elements(velimpose_rd) eq 0?0.0:velimpose_rd):velimpose0

  ; if you want temperature keep this next
  syncom_cadence=n_elements(syncom_cadence0) eq 0?(n_elements(syncom_cadence_rd) eq 0?300.0:syncom_cadence_rd):syncom_cadence0
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


  ; Plasma parameters
  hydro=n_elements(hydro0) eq 0?(n_elements(hydro_rd) eq 0?0:hydro_rd):hydro0

  if exist(cdensprof) then cdensprofsave=cdensprof
  if exist(ct0) then ct0save=ct0
  for_hydrodefaults,$
    hydro=hydro,cdensprof=cdensprof,ct0=ct0,$
    odensprof=odensprof,oT0=oT0,$
    rcdensprof=cdensprof_rd,rct0=cT0_rd,$
    rodensprof=odensprof_rd,rot0=oT0_rd,$
    vodensprof=vodensprof,$
    vcdensprof=vcdensprof
  ;
  ; note the HYDRO = 4 requires rerunning for_hydrodefaults
  ;  with HYDRO=3 for the closed field regions

  hydrosave=hydro
  if hydro eq 4 then begin
    for_hydrodefaults,$
      hydro=3,cdensprof=cdensprofsave,ct0=ct0save,$
      rcdensprof=cdensprof_rd,rct0=cT0_rd,$
      vcdensprof=vcdensprof
    cdensprof=cdensprofsave
    ct0=ct0save
  endif
  hydro=hydrosave

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
  magmod=0

  ;
  ; set up  pram input array
  ;


  pramarray={Name:name,$
    syncomfile:syncomfilesave,$
    hydro:double(hydro),cdensprof:cdensprof,ct0:ct0,$
    ;          odensprof:odensprof,ot0:ot0,$
    syncom_cadence:syncom_cadence, $
    syncom_n_blobs:syncom_n_blobs, $
    syncom_acc:syncom_acc, $
    syncom_time:syncom_time, $
    syncom_initial_R_sun:syncom_initial_R_sun, $
    verbose:verbose, $
    syncom_size:syncom_size, $
    syncom_nt:syncom_nt,syncom_nx:syncom_nx,syncom_ny:syncom_ny, $
    syncom_noise_level:syncom_noise_level, $
    syncom_max_intensity:syncom_max_intensity, $
    syncom_dens_scale:syncom_dens_scale $
  }

  ; if requested, save input parameters to a file (stored in file named saveprams if it is a string)

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


  outarray={Name:name,$
    Label:label,$
    magmod:magmod,$
    filename:syncomfile,$
    syncom_cadence:syncom_cadence, $
    syncom_n_blobs:syncom_n_blobs, $
    syncom_acc:syncom_acc, $
    syncom_time:syncom_time, $
    syncom_nt:syncom_nt,syncom_nx:syncom_nx,syncom_ny:syncom_ny, $
    syncom_initial_R_sun:syncom_initial_R_sun, $
    syncom_dens_scale:syncom_dens_scale, $
    Hydro:double(Hydro), $
    CDensProf:VCDensProf, $
    verbose:verbose, $
    syncom_size:syncom_size, $
    syncom_noise_level:syncom_noise_level, $
    syncom_max_intensity:syncom_max_intensity, $
    ;            ODensProf:VODensProf,$
    ;            OT0:OT0,
    CT0:CT0}

  date=dateuse

END
