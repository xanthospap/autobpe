
sp3_type = {'d': 'CODwwwwn.EPH.Z',
  'f': 'cofwwwwn.eph.Z',
  'r': 'CODwwwwn.EPH_R',
  'u': 'COD.EPH_U',
  'p': 'CODwwwwn.EPH_Pi',
  '2d': 'CO2wwwwn.EPH.Z',
  '2f': 'cf2wwwwn.eph.Z'
}
''' A dictionary to hold pairs of sp3 file types and corresponding
    sp3 file names.
'''

def getCodErp(stype, datetm=None, out_dir=None, use_repro_13=False, prd=0):
  ''' Download a CODE Erp file (i.e. CODwwwwn.ERP.Z). All erp (earth orientation
      parameter) files are downloaded from CODE's ftp webserver (ftp.unibe.ch),
      except from final, clean one-day solution (i.e. **cof**) which are
      downloaded from CDDIS (cddis.gsfc.nasa.gov) and reprocessed final, clean 
      one-day solution (i.e. **cf2**) which are downloaded from CDDIS 
      (cddis.gsfc.nasa.gov) at repro2.

      :param stype: A char denoting the type of erp to be
                    downloaded. Can be:

                     * 'd' final, 3-day solution,
                     * 'f' final, one-day solution
                     * 'r' rapid solution,
                     * 'u' ultra-rapid solution,
                     * 'p' prediction

                     The ``stype`` parameter is matched to a corresponding file, 
                     using the :py:data:`erp_type` dictionary.

      :param datetm: A Python ``datetime`` object; not needed
                     if downloading an ultra-rapid product.

      :param out_dir: Output directory (i.e. where the file is to be saved at).

      :param prd:    If the user wants the predicted erp (i.e.
                     ``stype = 'p'``, then the prd denotes:

                     * ``prd = 0`` indicates 1-day predictions (0-24 hours)
                     * ``prd != 0`` indicates 2-day predictions (24-48 hours)

      :param use_repro_13: If set to ``True``, the erp file downloaded
                     will be the one from the reprocessing campaign
                     **REPRO 2013**. For more info, see
                     ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN.
                     Only available when the parameter ``stype`` is ``'d'``
                     of ``'f'``.

      :returns: In sucess, a tuple is returned; first element is the
                  name of the saved file, the second element is the name
                  of the file on web.

      .. note::
        This function is very similar to products.getCodSp3(...)

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodErp.' %out_dir)

  ## if we are to use repro_2013, then the type must be
  ## either 'd' or 'f'; they are translated to '2d' or '2f'
  ## respectively.
  if use_repro_13 == True and stype != 'd' and stype != 'f':
    raise RuntimeError('Reprocessed erp only available for type: final -> getCodErp.')
  elif use_repro_13 == True and (stype == 'd' or stype == 'f'):
    stype = '2' + stype

  ## date must be specified, except for ultra-rapid
  if stype != 'u' and not datetm:
    raise RuntimeError('Must specify date -> getCodErp.')

  ## generic erp file name (including e.g. 'wwww')
  try:
    generic_filen = erp_type[stype]
  except:
    raise RuntimeError('Invalid erp type -> getCodErp.')

  ## we need some dates ...
  if datetm:
    try:
      week, sow = bernutils.gpstime.pydt2gps(datetm)
      dow   = int(datetm.strftime('%w'))
      iyear = int(datetm.strftime('%Y'))
    except:
      raise

  ## --- Ftp Server --- ##
  if stype == 'f' or stype == '2f':
    HOST = IGS_HOST
  else:
    HOST = COD_HOST

  ## ---  Directory in ftp server --- ##
  if   stype == 'f':
    dirn   = '%s/%4i/' %(IGS_DIR, week)
  elif stype == '2f':
    dirn   = '%s/%4i/' %(IGS_DIR_2013, week)
  elif stype == 'd':
    dirn   = '%s/%4i/' %(COD_DIR, int(iyear))
  elif stype == '2d':
    dirn   = '%s/%4i/' %(COD_DIR_2013, int(iyear))
  else:
    dirn = COD_DIR + '/'

  ## --- Name of the file --- ##
  dfile = generic_filen
  ## all but the ultra-rapid files, contain date
  if stype != 'u':
    dfile = dfile.replace('wwww','%4i'%week)
    # dow only set if rapid or prediction
    if stype == 'r' or stype == 'p':
        dfile = dfile.replace('n','%1i'%dow)
  ## in case of predicted erp, we must replace the 'i'
  if stype == 'u':
    if prd == 0:
      dfile = dfile.replace('i','')
    else:
      dfile = dfile.replace('i','2')

  ## --- Name of the saved file --- ##
  saveas = dfile
  if out_dir:
    if out_dir[-1] != '/':
      out_dir += '/'
    saveas = os.path.join(out_dir,saveas)

  ## --- Download --- ##
  try:
    localfile, webfile = bernutils.webutils.grabFtpFile(HOST,dirn,dfile,saveas)
  except:
    raise

  return localfile, webfile

def getCodSp3(stype,datetm=None,out_dir=None,use_repro_13=False,prd=0):
  ''' Download CODE Sp3 file (i.e. CODwwwwn.EPH.Z). All sp3 (orbit)
      files are downloaded from CODE's ftp webserver (ftp.unibe.ch),
      except from final, clean one-day solution (i.e. cof) which are
      downloaded from CDDIS (cddis.gsfc.nasa.gov) and reprocessed
      final, clean one-day solution (i.e. cf2) which are
      downloaded from CDDIS (cddis.gsfc.nasa.gov) at repro2.

      :param stype: A char denoting the type of orbit to be
                    downloaded. Can be:

                    * 'd' final, 3-day solution,
                    * 'f' final, one-day solution
                    * 'r' rapid solution,
                    * 'u' ultra-rapid solution,
                    * 'p' prediction

                    The ``stype`` parameter is matched to a corresponding file, 
                    using the :py:data:`sp3_type` dictionary.

        :param datetm: A Python ``datetime`` object; not needed
                       if downloading an ultra-rapid product.

        :param out_dir: Output directory.

        :param prd:    If the user wants the predicted orbit (i.e.
                       ``stype = 'p'``, then the prd denotes:

                       * ``prd = 0`` indicates 1-day predictions (0-24 hours)
                       * ``prd != 0`` indicates 2-day predictions (24-48 hours)

        :param use_repro_13: If set to ``True``, the orbit file downloaded
                       will be the one from the reprocessing campaign
                       **REPRO 2013**. For more info, see
                       ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN.
                       Only available when the parameter ``stype`` is ``'d'``
                       of ``'f'``.

        :returns: In sucess, a tuple is returned; first element is the
                  name of the saved file, the second element is the name
                  of the file on web.

        .. note::
            A short list of orbit products under the /CODE directory:
            source ftp://ftp.unibe.ch/aiub/CODE/0000_CODE.ACN

            * CODwwwwn.EPH.Z
              GNSS ephemeris/clock data in 7 daily
              files at 15-min intervals in SP3
              format, including accuracy codes
              computed from a long-arc analysis
              Files generated from three-day long-arc solutions.

            * COFwwwwn.EPH.Z
              GNSS ephemeris/clock data in 7 daily
              files at 15-min intervals in SP3
              format, including accuracy codes
              computed from a clean one-day solution.
              Files generated from clean one-day solutions.

              Orbit positions correspond to the estimates
              for the middle day of a 3-day in case of a
              long-arc analysis.

            * CODwwwwn.EPH_R
              GNSS/GPS ephemeris/clock data in at
              15-min intervals in SP3 format,
              including accuracy codes computed
              from a long-arc analysis.

              Orbit positions correspond to the estimates
              for the last day of a 3-day long-arc analysis.

            * COD.EPH_U
              GNSS ephemeris/broadcast clock data
              in at 15-min intervals in SP3 format,
              including accuracy codes computed
              from a long-arc analysis.

              Orbit positions correspond to the estimates
              for the last 24 hours of a 3-day long-arc
              analysis plus predictions for the following
              24 hours.

            * CODwwwwn.EPH_Pi 
              GNSS/GPS ephemeris/clock data at
              15-min intervals in SP3 format,
              including accuracy codes computed 
              from a long-arc analysis.

              "P2" indicates 2-day predictions (24-48 hours);
              "P" indicates 1-day predictions (0-24 hours).

            Products under the /REPRO_2013 directory
            source ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN

            * CO2wwwwn.EPH.Z
              GNSS ephemeris/clock data in 7 daily
              files at 15-min intervals in SP3 
              format, including accuracy codes
              computed from a long-arc analysis.
              Files generated from three-day long-arc solutions.

            * CF2wwwwn.EPH.Z
              GNSS ephemeris/clock data in 7 daily
              files at 15-min intervals in SP3
              format, including accuracy codes
              computed from a clean one-day solution.
              Files generated from clean one-day solutions.

  '''

  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodSp3.' %out_dir)

  ## if we are to use repro_2013, then the type must be
  ## either 'd' or 'f'; they are translated to '2d' or '2f'
  ## respectively.
  if use_repro_13 == True and stype != 'd' and stype != 'f':
    raise RuntimeError('Reprocessed orbits only available for type: final -> getCodSp3.')
  elif use_repro_13 == True and (stype == 'd' or stype == 'f'):
    stype = '2' + stype

  ## date must be specified, except for ultra-rapid
  if stype != 'u' and not datetm:
    raise RuntimeError('Must specify date -> getCodSp3.')

  ## generic sp3 file name (including e.g. 'wwww')
  try:
    generic_filen = sp3_type[stype]
  except:
    raise RuntimeError('Invalid sp3 type -> getCodSp3.')

  ## we need some dates ...
  if datetm:
    try:
      week, sow = bernutils.gpstime.pydt2gps(datetm)
      dow   = int(datetm.strftime('%w'))
      iyear = int(datetm.strftime('%Y'))
    except:
      raise

  ## --- Ftp Server --- ##
  if stype == 'f' or stype == '2f':
    HOST = IGS_HOST
  else:
    HOST = COD_HOST

  ## ---  Directory in ftp server --- ##
  if   stype == 'f':
    dirn   = '%s/%4i/' %(IGS_DIR, week)
  elif stype == '2f':
    dirn   = '%s/%4i/' %(IGS_DIR_2013, week)
  elif stype == 'd':
    dirn   = '%s/%4i/' %(COD_DIR, int(iyear))
  elif stype == '2d':
    dirn   = '%s/%4i/' %(COD_DIR_2013, int(iyear))
  else:
    dirn = COD_DIR + '/'

  ## --- Name of the file --- ##
  dfile = generic_filen
  ## all but the ultra-rapid files, contain date
  if stype != 'u':
    dfile = dfile.replace('wwww','%4i'%week)
    dfile = dfile.replace('n','%1i'%dow)
  ## in case of predicted orbit, we must replace the 'i'
  if stype == 'u':
    if prd == 0:
      dfile = dfile.replace('i','')
    else:
      dfile = dfile.replace('i','2')

  ## --- Name of the saved file --- ##
  saveas = dfile
  if out_dir:
    if out_dir[-1] != '/':
      out_dir += '/'
    os.path.join(out_dir,saveas)

  ## --- Download --- ##
  try:
    localfile, webfile = bernutils.webutils.grabFtpFile(HOST,dirn,dfile,saveas)
  except:
    raise

  return localfile, webfile
