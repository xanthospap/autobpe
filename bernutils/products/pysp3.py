import os
import datetime
import ftplib

import bernutils.gpstime
import bernutils.webutils
import bernutils.products.prodgen

__DEBUG_MODE__ = True

COD_HOST      = bernutils.products.prodgen.COD_HOST
IGS_HOST      = bernutils.products.prodgen.IGS_HOST
COD_DIR       = bernutils.products.prodgen.COD_DIR
COD_DIR_2013  = bernutils.products.prodgen.COD_DIR_2013
IGS_DIR       = bernutils.products.prodgen.IGS_DIR
IGS_DIR_REP2  = bernutils.products.prodgen.IGS_DIR_REP2

def __igs_sp3_all_final__(igs_repro2=False):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final igs-generated sp3 file, based
      on the input parameters. These information can be later used to download the
      file.

      :param igs_repro2: Use IGS repro2 (2nd reprocessing campaign) erp products.

  '''
  HOST     = IGS_HOST
  if igs_repro2 == True:
    FILENAME = 'ig2yyPwwww.sp3.Z'
    DIR      = IGS_DIR_REP2 + '/wwww/'
  else:
    FILENAME = 'igswwwwd.sp3.Z'
    DIR      = IGS_DIR + '/wwww/'

  return [[ FILENAME, HOST, DIR ]]

def __igs_sp3_all_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid rapid igs-generated sp3 file.These 
      information can be later used to download the file.

  '''
  return [[ 'igrwwwwd.sp3.Z', IGS_HOST, IGS_DIR + '/wwww/' ]]

def __igs_sp3_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid igs-generated sp3 file.
      These information can be later used to download the file.

  '''
  ret_list = []
  for i in xrange(0, 24, 6):
    ret_list.append(['iguwwwwd_%02i.sp3.Z'%i, IGS_HOST, IGS_DIR+ '/wwww/'])
  return ret_list

def __igs_sp3_all_prediction__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid prediction igs-generated sp3 file.
      These information can be later used to download the file.

  '''
  return [[]]

def __cod_sp3_all_final__(use_repro_13=False, use_one_day_sol=False, igs_repro2=False):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final code-generated sp3 file, based
      on the input parameters. These information can be later used to download the
      file.

      param use_repro_13:     Use (or not) CODE's REPRO_2013 products (only 
                              available via CODE's ftp server).

      :param use_one_day_sol: Use the clean, one-day-solution (only available
                              via igs/cddis ftp sever).

      :param igs_repro2:      Use IGS repro2 (2nd reprocessing campaign) sp3 products.
                              (can be used in combination with ``use_one_day_sol``.

      :returns:               A valid sp3 FILENAME, a HOST and a DIRectory (in 
                              the HOST where the file FILENAME is to be found)
                              for each possible, valid, sp3 file. Using these
                              information, one can download the file. Every possible
                              (triple) combination is returned as a list (so the
                              function returns a list of lists).

      .. note:: 
        # One-day-solutions are only available at the CDDIS ftp host.
        # The options here should **exactly match** the ones described 
          in the  ``products.rst`` file.

  '''
  # Manage repro2 igs campaign erp files.
  if igs_repro2 == True:
    HOST = IGS_HOST
    DIR  = IGS_DIR_REP2 + '/wwww/'
    ## One-day solution: (CDDIS)/repro2/wwww/cf2wwwwd.eph.Z
    if use_one_day_sol == True:
      FILENAME = 'cf2wwwwd.eph.Z'
    ## Normal erp (3-day) (CDDIS)/repro2/wwww/co2wwwwd.eph.Z
    else:
      FILENAME = 'co2wwwwd.eph.Z'

  else:
    ## One-day solution (CDDIS)/wwww/cofwwwwd.eph.Z
    if use_one_day_sol == True:
      FILENAME = 'cofwwwwd.eph.Z'
      HOST     = IGS_HOST
      DIR      = IGS_DIR + '/wwww/'

    ## CODE's 2013 re-processing (CODE)/REPRO_2013/CODE/yyyy/CODwwwwd.EPH.Z
    elif use_repro_13 == True:
      FILENAME = 'CODwwwwd.EPH.Z'
      HOST     = COD_HOST
      DIR      = COD_DIR_2013 + '/yyyy/'

    ## Normal, 3-day file (CODE)/CODE/yyyy/CODwwwwd.EPH.Z
    else:
      FILENAME = 'CODwwwwd.EPH.Z'
      HOST     = COD_HOST
      DIR      = COD_DIR + '/yyyy/'

  return [[ FILENAME, HOST, DIR ]]

def __cod_sp3_all_final_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final-rapid code-generated sp3 file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
                the file FILENAME is to be found) list for every possible 
                final-rapid sp3 file. So, alist of lists.

      .. note:: 
        #. The options here should **exactly match** the ones described in the
           ``products.rst`` file.
        #. There are two possible fina-rapid sp3 files, stored in different
           product areas and in different formats (.Z or uncompressed). The function
           will thus return information for both.

  '''

  ## final rapid (in yyy_M folder)
  FILENAME_FR1 = 'CODwwwwd.EPH_M.Z'
  HOST_FR1     = COD_HOST
  DIR_FR1      = COD_DIR + '/yyyy_M/'

  ## final rapid (in root folder)
  FILENAME_FR2 = 'CODwwwwd.EPH_M'
  HOST_FR2     = COD_HOST
  DIR_FR2      = COD_DIR

  return  [[FILENAME_FR1, HOST_FR1, DIR_FR1], 
           [FILENAME_FR2, HOST_FR2, DIR_FR2]]

def __cod_sp3_all_early_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid early-rapid code-generated sp3 file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where
                the file FILENAME is to be found), for the early-rapid erp file.

      .. note:: The options here should **exactly match** the ones described in
        the ``products.rst`` file.

  '''
  return [[ 'CODwwwwd.EPH_R', COD_HOST, COD_DIR ]]

def __cod_sp3_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid code-generated sp3 file.
      These information can be later used to download the file.

      :returns: A valid sp3 FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found). These are concatenated into a list.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  return [[ 'COD.EPH_U', COD_HOST, COD_DIR ]]

def __cod_sp3_all_prediction__(str_id='5D'):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid prediction code-generated sp3 file,
      based on the input parameters. These information can be later used to 
      download the file.

      :param str_id: The id of the solution type (as string). Can be any of:

        * ``'5D'``,
        * ``'P2'``
        * ``'P'``

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found) for a CODE prediction sp3 file, 
        depending on the ``str_id`` parameter.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  if str_id == '5D':
    FILENAME = 'CODwwwwd.EPH_5D'
  elif str_id == 'P2':
    FILENAME = 'CODwwwwd.EPH_P2'
  elif str_id == 'P':
    FILENAME = 'CODwwwwd.EPH_P'
  else:
    raise RuntimeError('Invalid SP3 prediction flag %s.', str_id)

  return [[ FILENAME, COD_HOST, COD_DIR ]]

def getIgsSp3(datetm, out_dir=None, igs_repro2=False):
  ''' This function is responsible for downloading an optimal, valid sp3 file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the sp3 information,
                              as a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :param igs_repro2:      (Optional) Use IGS 2nd reprocessing campaign 
                              product files.

      :returns:               A list containing saved file and the remote file.

      .. note:: 
        #. Parameter ``igs_repro2`` is only relevant to final products
           (else it'll be ignored).
        #. The options here should **exactly match** the ones described in
           the ``products.rst`` file.
        #. This functions uses :func:`bernutils.products.pyerp.__igs_sp3_all_final__`,
           :func:`bernutils.products.pyerp.__igs_sp3_all_rapid__`,
           :func:`bernutils.products.pyerp.__igs_sp3_all_ultra_rapid__` and
           :func:`bernutils.products.pyerp.__igs_sp3_all_prediction__`.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getIgsSp3.' %out_dir)

  ## transform date to datetime (if needed)
  if type(datetm) == datetime.date:
    datetm = datetime.datetime.combine(datetm, datetime.datetime.min.time())

  ## compute delta time (in days) from today
  dt = datetime.datetime.today() - datetm
  dt = dt.days + (dt.seconds // 3600) /24.0

  options = []

  ## depending on deltatime, get a list of optional erp files
  if dt >= 17:
    options =  __igs_sp3_all_final__(igs_repro2)
  elif dt >= 4:
    options  =  __igs_sp3_all_final__(igs_repro2)
    options +=  __igs_sp3_all_rapid__()
  elif dt >= 0:
    options  = __igs_sp3_all_rapid__()
    options += __igs_sp3_all_ultra_rapid__()
  elif dt > -1:
    options  = __igs_sp3_all_ultra_rapid__()
    options += __igs_sp3_all_prediction__()
  elif dt > -15:
    options  = __igs_sp3_all_prediction__()
  else:
    raise RuntimeError('DeltaTime two far in the future %+03.1f' %dt)

  ## compute the needed date formats
  week, sow = bernutils.gpstime.pydt2gps(datetm)
  dow       = int(datetm.strftime('%w'))
  iyear     = int(datetm.strftime('%Y'))
  yy        = int(datetm.strftime('%y'))

  ## need to replace the dates
  options = [ i.replace('yyyy', ('%04i' %iyear)).replace('wwwwd', ('%04i%01i' %(week, dow))).replace('wwww', ('%04i' %week)).replace('yy', ('%02i' %yy)) for slst in options for i in slst ]
  options = [ options[x:x+3] for x in xrange(0, len(options), 3) ]

  if __DEBUG_MODE__ == True:
    print 'Delta days is : %+04.1f' %dt
    for i in options:
      print 'will try: ', i

  ## the successeful triple is ..
  ret_list = []
  nr_tries = 0

  ##  for every possible  erp file, see if we can download it. we stop at the
  ##+ first successeful download.
  for triple in options:
    nr_tries += 1
    try:
      if out_dir: 
        saveas = os.path.join(out_dir, triple[0])
      else:
        saveas = triple[0]
      info = bernutils.webutils.grabFtpFile(triple[1], triple[2], triple[0], saveas)
      ret_list = [saveas, '%s%s%s' %(triple[1], triple[2], triple[0])]
      break
    except:
      pass

  if len(ret_list) == 0:
    raise RuntimeError('Failed to download sp3 file (0/%1i)' %len(options))

  if __DEBUG_MODE__ == True:
    print 'Tries: %1i/%1i Downloaded %s to %s' %(nr_tries, len(options), ret_list[1], ret_list[0])

  return ret_list

def getCodSp3(datetm, out_dir=None, use_repro_13=False, use_one_day_sol=False, igs_repro2=False):
  ''' This function is responsible for downloading an optimal, valid sp3 file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the sp3 information, as
                              a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :param use_repro_13:    (Optional) Use (or not) CODE's REPRO_2013 products
                              (only an option for final sp3.

      :param use_one_day_sol: (Optional) Use the clean, one-day-solution.

      :param igs_repro2:      (Optional) Use IGS 2nd reprocessing campaign 
                              product files.

      :returns:               A list containing saved file and the remote file.

      .. note::
        #. Parameters ``use_repro_13``, ``use_one_day_sol`` and ``igs_repro2``
           are only relevant to final products (else they'll be ignored).
        #. Final, one-day-solutions and igs repro2 erp's are only available
           at the CDDIS ftp host.
        #. The options here should **exactly match** the ones described in
           the ``products.rst`` file.
        #. This functions uses :func:`bernutils.products.pysp3.__cod_sp3_all_final__`,
           :func:`bernutils.products.pysp3.__cod_sp3_all_final_rapid__`,
           :func:`bernutils.products.pysp3.__cod_sp3_all_early_rapid__`,
           :func:`bernutils.products.pysp3.__cod_sp3_all_ultra_rapid__` and
           :func:`bernutils.products.pysp3.__cod_sp3_all_prediction__`.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodErp.' %out_dir)

  ## transform date to datetime (if needed)
  if type(datetm) == datetime.date:
    datetm = datetime.datetime.combine(datetm, datetime.datetime.min.time())

  ## check input parameters
  if use_repro_13 == True and (use_one_day_sol == True or igs_repro2 == True):
    raise RuntimeError('Invalid sp3 options! Cannot have both cod and erp hosts')

  ## compute delta time (in days) from today
  dt = datetime.datetime.today() - datetm
  dt = dt.days + (dt.seconds // 3600) /24.0

  options = []

  ## depending on deltatime, get a list of optional erp files
  if dt >= 15:
    options =   __cod_sp3_all_final__(use_repro_13, use_one_day_sol, igs_repro2)
  elif dt >= 4:
    options  =  __cod_sp3_all_final__(use_repro_13, use_one_day_sol, igs_repro2)
    options +=  __cod_sp3_all_final_rapid__()
  elif dt >= 0:
    options  =  __cod_sp3_all_final_rapid__()
    options +=  __cod_sp3_all_early_rapid__()
  elif dt > -1:
    options  = __cod_sp3_all_early_rapid__()
    options += __cod_sp3_all_ultra_rapid__()
  elif dt > -15:
    options  = __cod_sp3_all_prediction__()
  else:
    raise RuntimeError('DeltaTime two far in the future %+03.1f' %dt)

  ## compute the needed date formats
  week, sow = bernutils.gpstime.pydt2gps(datetm)
  dow       = int(datetm.strftime('%w'))
  iyear     = int(datetm.strftime('%Y'))

  ## need to replace the dates
  options = [ i.replace('yyyy', ('%04i' %iyear)).replace('wwwwd', ('%04i%01i' %(week, dow))).replace('wwww', ('%04i' %week)) for slst in options for i in slst ]
  options = [ options[x:x+3] for x in xrange(0, len(options), 3) ]

  if __DEBUG_MODE__ == True:
    print 'Delta days is : %+04.1f' %dt
    for i in options:
      print 'will try: ', i

  ## the successeful triple is ..
  ret_list = []
  nr_tries = 0

  ##  for every possible sp3 file, see if we can download it. we stop at the
  ##+ first successeful download.
  for triple in options:
    nr_tries += 1
    try:
      if out_dir: 
        saveas = os.path.join(out_dir, triple[0])
      else:
        saveas = triple[0]
      info = bernutils.webutils.grabFtpFile(triple[1], triple[2], triple[0], saveas)
      ret_list = [saveas, '%s%s%s' %(triple[1], triple[2], triple[0])]
      break
    except:
      pass

  if len(ret_list) == 0:
    raise RuntimeError('Failed to download sp3 file (0/%1i)' %len(options))

  if __DEBUG_MODE__ == True:
    print 'Tries: %1i/%1i Downloaded %s to %s' %(nr_tries, len(options), ret_list[1], ret_list[0])

  return ret_list

def getOrb(datetm, ac='cod', out_dir=None, use_repro_13=False, use_one_day_sol=False, igs_repro2=False):
  ''' This function is responsible for downloading an optimal, valid sp3/brdc file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the orbit information,
                              as a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param ac:             (Optional) Choose the Analysis Center; default is
                              ``'cod'``. The valid string for this option are:

                              * ``'cod'`` is CODE analysis center
                              * ``'igs'`` is IGS

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :param use_repro_13:    (Optional) Use (or not) REPRO_2013 products (only 
                              an option for final sp3 when the ac is CODE).

      :param use_one_day_sol: (Optional) Use the clean, one-day-solution (only 
                              an option for final sp3 when the ac is CODE).

      :param igs_repro2:      (Optional) Use IGS 2nd reprocessing campaign 
                              product files.

      :returns:               A list containing saved file and the remote file.

      .. note::

        #. Parameters ``use_repro_13``, ``use_one_day_sol`` and ``igs_repro2``
           are only relevant to final products (else they'll be ignored).
        #. Final, one-day-solutions and igs repro2 erp's are only available at
           the CDDIS ftp host.

  '''

  ## Do nothing :) just pass arguments to the ac-specific function
  if ac == 'cod':
    return getCodSp3(datetm, out_dir, use_repro_13, use_one_day_sol, igs_repro2)
  elif ac == 'igs':
    return getIgsSp3(datetm, out_dir, igs_repro2)
  else:
    raise RuntimeError('Invalid Analysis Center: %s.' %ac)

def getNav(datetm, sat_sys='G', out_dir=None, station=None, hour=None):
  ''' This function will download a broadcast orbit file, either an accumulated one
      (i.e. a brdc file) or a station-specific one. The url to download navigation
      files is cddis, so the station-specific nav files available only match
      igs stations (or any other distributed by cddis). For station-specific
      nav files, it is also possible to download hourly broadcst files.

      :param datetm: The date(time) for wich we want the orbit information,
                     as a Python ``datetime.datetime`` or ``dadtetime.date``
                     instance.

      :param sat_sys: The satellite system for which we want the nav file for.
                      Can be any of:

                      * ``'G'`` for gps,
                      * ``'R'`` for glonass
                      * ``'S'`` for sbas

                      .. warning:: The options here, must match the ones in the
                        :data:`bernutils.products.pysp3.SAT_SYS_TO_NAV_DICT`
                        dictionary.

      :param out_dir: (Optional) Directory where the downloaded file is
                      to be saved.

      :param station: If we want a station specific bradcast file, then this
                      parameter shall hold the 4-char id of the station. Note
                      that the station must be ditributed by cddis (or else
                      the file won't be available).

      :param hour:    If we want a station-specific, hourly broadcast file, then
                      this parameter shall hold the hour of day. The hour should
                      be an integer or float/double in the range [0, 23). Hourly
                      navigation files are only available for station-specific
                      navigation files.

  '''

  try:
    nchar = bernutils.products.prodgen.SAT_SYS_TO_NAV_DICT[sat_sys]
  except:
    raise RuntimeError('Invalid Satellite System identifier: [%s]' %sat_sys)

  if hour and not station:
    raise RuntimeError('Hourly navigation files only available for igs stations')

  if hour and sat_sys != 'G':
    raise RuntimeError('Hourly navigation files only available gps')

  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getNav' %out_dir)

  ## compute the needed date formats
  iyear = int(datetm.strftime('%Y'))
  yy    = int(datetm.strftime('%y'))
  doy   = int(datetm.strftime('%j'))

  HOST = IGS_HOST

  DIR  = '/gnss/data/daily/%04i/%03i' %(iyear, doy)

  if hour:
    ihour   = int(hour)
    session = bernutils.products.prodgen.SES_IDENTIFIERS_INT[ihour]
    DIR     = DIR.replace('daily', 'hourly')
    DIR     = DIR + ( '/%02i/' %ihour )
  else:
    session = '0'
    DIR     = DIR + ( '/%02i%s/' %(yy, nchar) )

  if not station: station = 'brdc'

  NAVFILE = '%s%03i%1s.%02i%1s.Z' %(station, doy, session, yy, nchar)
  saveas  = NAVFILE
  if out_dir:
    saveas = os.path.join(out_dir, saveas)

  try:
    info = bernutils.webutils.grabFtpFile(HOST, DIR, NAVFILE, saveas)
    return info
  except:
    raise RuntimeError('Failed to fetch navigation file: %s' %(HOST+DIR+NAVFILE))