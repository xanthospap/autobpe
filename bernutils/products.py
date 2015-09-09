import os
import datetime
import ftplib
import bernutils.gpstime
import bernutils.webutils

COD_HOST  = 'ftp.unibe.ch'
IGS_HOST  = 'cddis.gsfc.nasa.gov'

COD_DIR       = '/aiub/CODE'
COD_DIR_2013  = '/aiub/REPRO_2013/CODE'
IGS_DIR       = '/gnss/products'
IGS_DIR_2013  = '/gnss/products/repro2'

erp_type = {'d': 'CODwwww7.ERP.Z',
  'f': 'cofwwww7.erp.Z',
  'r': 'CODwwwwn.ERP_R',
  'u': 'COD.ERP_U',
  'p': 'CODwwwwn.ERP_Pi',
  '2d': 'CO2wwww7.ERP.Z',
  '2f': 'cf2wwww7.erp.Z'
}
''' A dictionary to hold pairs of erp file types and corresponding
    erp file names.
'''

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

dcb_type = {'p2': 'P1P2yymm.DCB',
  'c1': 'P1C1yymm.DCB',
  'c1_rnx': 'P1C1yymm_RINEX.DCB',
  'c2_rnx': 'P2C2yymm_RINEX.DCB'
}
''' A dictionary to hold pairs of dcb file types and corresponding
    dcb file names.
'''

def _getRunningDcb_(filename, saveas):
  ''' Utility function to assist :py:func:`getCodDcb`; do *NOT* use as 
      standalone. This function is used within the :py:func:`getCodDcb` to 
      download a running dcb file from CODE.
  '''
  HOST = COD_HOST
  dirn = COD_DIR
  try:
    return bernutils.webutils.grabFtpFile(HOST, dirn, filename, saveas)
  except:
    raise

def _getFinalDcb_(year, filename, saveas):
  ''' Utility function to assist :py:func:`getCodDcb`; do *NOT* use as 
      standalone. This function is used within the :py:func:`getCodDcb` to 
      download a final dcb file from CODE.
  '''
  HOST = COD_HOST
  dirn = '%s/%04i/' %(COD_DIR, year)
  try:
    return bernutils.webutils.grabFtpFile(HOST,dirn,filename,saveas)
  except:
    raise

def getCodDcb(stype, datetm, out_dir=None):
  ''' Download .DCB file from CODE's ftp webserver. Depending on the input date 
      (i.e. ``datetm``), one of the following will happen:

      * if today and ``datetm`` are the same year and same month, the the 
        running dcb file will be downloaded,
      * if deltadays between today and ``datetm`` is less than 30 days, then 
        the final dcb file will first be checked. If it is not available, then 
        the running dcb will be downloaded isntead,
      * if deltadays between today and ``datetm`` is 30 or more, then the final 
        dcb file file will be downloaded.

      :param stype: Can be one of:

          * ``'p2'`` for P1P2 dcb, or
          * ``'c1'`` for P1C1 dcb, or
          * ``'c1_rnx'`` for P1C1_RINEX dcb, or
          * ``'c2_rnx'`` for P1C2_RINEX dcb

          The ``stype`` parameter is matched to a corresponding file, using the
          :py:data:`dcb_type` dictionary.

      :param datetm:  A python ``datetime`` object.
      :param out_dir: Path to directory where the downloaded file shall
                      be stored.

      :returns:       A list/tuple with two strings; the first one is the 
                      filename of the downloaded file. The second element is the
                      (original) name of the remote file.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodDcb.' %out_dir)

  ## Only interested in the date part of datetm
  if type(datetm) == datetime.datetime:
    datetm = datetm.date()

  try:
    generic_file = dcb_type[stype]
  except:
    raise RuntimeError('Invalid dcb type: [%s]' %stype)

  # if the current month is the same as the month requested, then
  # download the running average.
  today = datetime.datetime.now()
  dt    = today.date() - datetm ##.date()
  iyear = int(datetm.strftime('%Y'))
  iyr2  = int(datetm.strftime('%y'))
  imonth= int(datetm.strftime('%m'))

  ## get running dcb
  if today.year == datetm.year and today.month == datetm.month:
    filename = generic_file.replace('yymm','')
    saveas   = filename
    if out_dir: saveas = os.path.join(out_dir, filename)
    try:
      localfile, webfile = _getRunningDcb_(filename, saveas)
      return localfile, webfile
    except:
      raise

  ## try for final; if fail, try for running
  elif dt.days < 30:
    filename = generic_file.replace('yymm', ('%02i%02i' %(iyr2, imonth)))
    filename+= '.Z'
    saveas   = filename
    if out_dir:  saveas = os.path.join(out_dir, filename)
    try:
      localfile, webfile = _getFinalDcb_(iyear,filename,saveas)
      return localfile, webfile
    except:
      filename = generic_file.replace('yymm', '')
      saveas   = filename
      if out_dir:
        saveas = os.path.join(out_dir, filename)
      try:
        localfile, webfile = _getRunningDcb_(filename,saveas)
        return localfile, webfile
      except:
        raise

  ## get final dcb
  elif dt.days >= 30:
    filename = generic_file.replace('yymm', ('%02i%02i' %(iyr2, imonth)))
    filename+= '.Z'
    saveas   = filename
    if out_dir: saveas = os.path.join(out_dir, filename)
    try:
      localfile, webfile = _getFinalDcb_(iyear,filename,saveas)
      return localfile, webfile
    except:
      raise
  else:
    raise RuntimeError('This date seems invalid (for dcb)')

def erpTimeSpan(filen, as_mjd=True):
  ''' Given an ERP filename, this function will return the min
      and max dates for which the file has info.

      :param filen:  The filename of the erp file.
      :param as_mjd: (Optional) if set to ``True``, the mina and max dates are
                     returned in Modified Julian Date format; else they are
                     returned as Python ``datetime`` instances.
      :returns:      A tuple of  denoting [max_date, min_date] for which erp
                     are available.
  '''

  try:
    fin = open(filen, 'r')
  except:
    raise RuntimeError('Cannot open erp file: %s' %filen)

  for i in range(1,5):
    line = fin.readline()

  line = fin.readline()
  if line.split()[0] != 'MJD':
    fin.close()
    raise RuntimeError('Invalid erp format: %s' %filen)

  line     = fin.readline()
  mjd_list = []
  dummy_it = 0

  line = fin.readline()
  while (line and dummy_it < 1000):
    if as_mjd == True: ## append as MJD instances
      mjd_list.append(float(line.split()[0]))
    else: ## append as datetime.datetime instances
      mjd_list.append(bernutils.gpstime.mjd2pydt(float(line.split()[0])))
    dummy_it += 1
    line = fin.readline()

  fin.close()

  if dummy_it >= 1000:
    raise RuntimeError('Failed reading erp: %s' %filen)

  return max(mjd_list), min(mjd_list)


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