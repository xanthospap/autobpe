import os
import datetime
import ftplib
import json

import bernutils.gpstime
import bernutils.webutils
import bernutils.products.prodgen

__DEBUG_MODE__ = False

erp_type = {'d': 'CODwwww7.ERP.Z',
  'f': 'cofwwww7.erp.Z',
  'r': 'CODwwwwn.ERP_R',
  'u': 'COD.ERP_U',
  'p': 'CODwwwwn.ERP_Pi',
  '2d': 'CO2wwww7.ERP.Z',
  '2f': 'cf2wwww7.erp.Z'
}
''' A dictionary to hold pairs of erp file types and corresponding
    erp file names. **This dictionary is obsolete !**
'''

COD_HOST      = bernutils.products.prodgen.COD_HOST
IGS_HOST      = bernutils.products.prodgen.IGS_HOST
COD_DIR       = bernutils.products.prodgen.COD_DIR
COD_DIR_2013  = bernutils.products.prodgen.COD_DIR_2013
IGS_DIR       = bernutils.products.prodgen.IGS_DIR
IGS_DIR_REP2  = bernutils.products.prodgen.IGS_DIR_REP2

JSON_INFO     = 'Earth Rotation Parameters'
JSON_FORMAT   = 'erp'

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

def __igs_erp_all_final__(igs_repro2=False):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final igs-generated erp file, based
      on the input parameters. These information can be later used to download the
      file.

      :param igs_repro2: Use IGS repro2 (2nd reprocessing campaign) erp products.

  '''
  HOST     = IGS_HOST
  if igs_repro2 == True:
    FILENAME = 'ig2yyPwwww.erp.Z'
    DIR      = IGS_DIR_REP2 + '/wwww/'
    descr    = 'final (repro2)'
  else:
    FILENAME = 'igswwww7.erp.Z'
    DIR      = IGS_DIR + '/wwww/'
    descr    = 'final'

  return [[ FILENAME, HOST, DIR, descr ]]

def __igs_erp_all_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid rapid igs-generated erp file.These 
      information can be later used to download the file.

  '''
  return [[ 'igrwwwwd.erp.Z', IGS_HOST, IGS_DIR + '/wwww/', 'rapid' ]]

def __igs_erp_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid igs-generated erp file.
      These information can be later used to download the file.

  '''
  ret_list = []
  for i in xrange(0, 24, 6):
    ret_list.append(['iguwwwwd_%02i.erp.Z'%i, IGS_HOST, IGS_DIR+ '/wwww/', 'ultra-rapid'])
  return ret_list

def __igs_erp_all_prediction__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid prediction igs-generated erp file.
      These information can be later used to download the file.

  '''
  return [[ 'igu00p01.erp.Z', IGS_HOST, IGS_DIR, 'prediction' ]]

def __cod_erp_all_final__(use_repro_13=False, use_one_day_sol=False, igs_repro2=False):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final code-generated erp file, based
      on the input parameters. These information can be later used to download the
      file.

      param use_repro_13:     Use (or not) CODE's REPRO_2013 products (only 
                              available via CODE's ftp server).

      :param use_one_day_sol: Use the clean, one-day-solution (only available
                              via igs/cddis ftp sever).

      :param igs_repro2:      Use IGS repro2 (2nd reprocessing campaign) erp products.
                              (can be used in combination with ``use_one_day_sol``.

      :returns:               A valid erp FILENAME, a HOST and a DIRectory (in 
                              the HOST where the file FILENAME is to be found)
                              for each possible, valid, erp file. Using these
                              information, one can download the file. Every possible
                              (triple) combination is returned as a list (so the
                              function returns a list of lists).

      .. note::
        #. One-day-solutions are only available at the CDDIS ftp host.
        #. The options here should **exactly match** the ones described
           in the  ``products.rst`` file.

  '''
  # Manage repro2 igs campaign erp files.
  if igs_repro2 == True:
    HOST = IGS_HOST
    DIR  = IGS_DIR_REP2 + '/wwww/'
    ## One-day solution: (CDDIS)/repro2/wwww/cf2wwww7.erp.Z
    if use_one_day_sol == True:
      FILENAME = 'cf2wwww7.erp.Z'
      descr    = 'final (repro2/one-day solution)'
    ## Normal erp (3-day) (CDDIS)/repro2/wwww/co2wwww7.erp.Z
    else:
      FILENAME = 'co2wwww7.erp.Z'
      descr    = 'final (repro2)'

  else:
    ## One-day solution (CDDIS)/wwww/cofwwww7.erp.Z
    if use_one_day_sol == True:
      FILENAME = 'cofwwww7.erp.Z'
      HOST     = IGS_HOST
      DIR      = IGS_DIR + '/wwww/'
      descr    = 'final (one-day solution)'

    ## CODE's 2013 re-processing (CODE)/REPRO_2013/CODE/yyyy/CODwwwwd.ERP.Z
    elif use_repro_13 == True:
      FILENAME = 'CODwwwwd.ERP.Z'
      HOST     = COD_HOST
      DIR      = COD_DIR_2013 + '/yyyy/'
      descr    = 'final (2013 re-processing)'

    ## Normal, 3-day file (CODE)/CODE/yyyy/CODwwwwd.ERP.Z
    else:
      FILENAME = 'CODwwww7.ERP.Z'
      HOST     = COD_HOST
      DIR      = COD_DIR + '/yyyy/'
      descr    = 'final'

  return [[ FILENAME, HOST, DIR, descr ]]

def __cod_erp_all_final_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final-rapid code-generated erp file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
                the file FILENAME is to be found) list for every possible 
                final-rapid erp file. So, alist of lists.

      .. note:: The options here should **exactly match** the ones described in
         the ``products.rst`` file.

      .. note:: There are two possible fina-rapid erp files, stored in different
        product areas and in different formats (.Z or uncompressed). The function
        will thus return information for both.

  '''

  ## final rapid (in yyy_M folder)
  FILENAME_FR1 = 'CODwwwwd.ERP_M.Z'
  HOST_FR1     = COD_HOST
  DIR_FR1      = COD_DIR + '/yyyy_M/'

  ## final rapid (in root folder)
  FILENAME_FR2 = 'CODwwwwd.ERP_M'
  HOST_FR2     = COD_HOST
  DIR_FR2      = COD_DIR

  return  [[FILENAME_FR1, HOST_FR1, DIR_FR1, 'rapid (final)'], 
           [FILENAME_FR2, HOST_FR2, DIR_FR2, 'rapid (final)']]

def __cod_erp_all_early_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid early-rapid code-generated erp file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where
                the file FILENAME is to be found), for the early-rapid erp file.

      .. note:: The options here should **exactly match** the ones described in
        the ``products.rst`` file.

  '''
  return [[ 'CODwwwwd.ERP_R', COD_HOST, COD_DIR, 'rapid (early)' ]]

def __cod_erp_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid code-generated erp file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found). These are concatenated into a list.

      .. note::
        The options here should **exactly match** the ones described in the ``products.rst``
        file.

  '''
  return [[ 'COD.ERP_U', COD_HOST, COD_DIR, 'ultra-rapid' ]]

def __cod_erp_all_prediction__(str_id='5D'):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid prediction code-generated erp file,
      based on the input parameters. These information can be later used to 
      download the file.

      :param str_id: The id of the solution type (as string). Can be any of:

        * ``'5D'``,
        * ``'P2'``
        * ``'P'``

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found) for a CODE prediction erp file, 
        depending on the ``str_id`` parameter.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  if str_id == '5D':
    FILENAME = 'CODwwwwd.ERP_5D'
  elif str_id == 'P2':
    FILENAME = 'CODwwwwd.ERP_P2'
  elif str_id == 'P':
    FILENAME = 'CODwwwwd.ERP_P'
  else:
    raise RuntimeError('Invalid ERP prediction flag %s.', str_id)

  return [[ FILENAME, COD_HOST, COD_DIR, 'prediction (%s)'%str_id ]]

def getIgsErp(datetm, out_dir=None, igs_repro2=False, tojson=False):
  ''' This function is responsible for downloading an optimal, valid erp file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the erp information, as
                              a Python ``datetime.datetime`` or ``dadtetime.date``
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
        #. This functions uses :func:`bernutils.products.pyerp.__igs_erp_all_final__`,
           :func:`bernutils.products.pyerp.__igs_erp_all_rapid__`,
           :func:`bernutils.products.pyerp.__igs_erp_all_ultra_rapid__` and
           :func:`bernutils.products.pyerp.__igs_erp_all_prediction__`.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getIgsErp.' %out_dir)

  ## transform date to datetime (if needed)
  if type(datetm) == datetime.date:
    datetm = datetime.datetime.combine(datetm, datetime.datetime.min.time())

  ## compute delta time (in days) from today
  dt = datetime.datetime.today() - datetm
  dt = dt.days + (dt.seconds // 3600) /24.0

  options = []

  ## depending on deltatime, get a list of optional erp files
  if dt >= 17:
    options =  __igs_erp_all_final__(igs_repro2)
  elif dt >= 4:
    options  =  __igs_erp_all_final__(igs_repro2)
    options +=  __igs_erp_all_rapid__()
  elif dt >= 0:
    options  = __igs_erp_all_rapid__()
    options += __igs_erp_all_ultra_rapid__()
  elif dt > -1:
    options  = __igs_erp_all_ultra_rapid__()
    options += __igs_erp_all_prediction__()
  elif dt > -15:
    options  = __igs_erp_all_prediction__()
  else:
    raise RuntimeError('DeltaTime two far in the future %+03.1f' %dt)

  ## compute the needed date formats
  week, sow = bernutils.gpstime.pydt2gps(datetm)
  dow       = int(datetm.strftime('%w'))
  iyear     = int(datetm.strftime('%Y'))
  yy        = int(datetm.strftime('%y'))

  ## need to replace the dates
  options = [ i.replace('yyyy', ('%04i' %iyear)).replace('wwwwd', ('%04i%01i' %(week, dow))).replace('wwww', ('%04i' %week)).replace('yy', ('%02i' %yy)) for slst in options for i in slst ]
  options = [ options[x:x+4] for x in xrange(0, len(options), 4) ]

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
      ret_list = [saveas, '%s%s%s' %(triple[1], triple[2], triple[0]), triple[3]]
      break
    except:
      pass

  if len(ret_list) == 0:
    raise RuntimeError('Failed to download erp file (0/%1i)' %len(options))

  if __DEBUG_MODE__ == True:
    print 'Tries: %1i/%1i Downloaded %s to %s' %(nr_tries, len(options), ret_list[1], ret_list[0])

  if tojson:
    jdict = {
        'info'    : JSON_INFO,
        'format'  : JSON_FORMAT,
        'satsys'  : '',
        'ac'      : 'igs',
        'type'    : ret_list[2],
        'host'    : IGS_HOST,
        'filename': ret_list[1]
    }
    ##  print(json.dumps(jdict))
    return ret_list, jdict

  return ret_list

def getCodErp(datetm, out_dir=None, use_repro_13=False, use_one_day_sol=False, igs_repro2=False, tojson=False):
  ''' This function is responsible for downloading an optimal, valid erp file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the erp information, as
                              a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :param use_repro_13:    (Optional) Use (or not) CODE's REPRO_2013 products
                              (only an option for final erp.

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
        #. This functions uses :func:`bernutils.products.pyerp.__cod_erp_all_final__`,
           :func:`bernutils.products.pyerp.__cod_erp_all_final_rapid__`,
           :func:`bernutils.products.pyerp.__cod_erp_all_early_rapid__`,
           :func:`bernutils.products.pyerp.__cod_erp_all_ultra_rapid__` and
           :func:`bernutils.products.pyerp.__cod_erp_all_prediction__`.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodErp.' %out_dir)

  ## transform date to datetime (if needed)
  if type(datetm) == datetime.date:
    datetm = datetime.datetime.combine(datetm, datetime.datetime.min.time())

  ## check input parameters
  if use_repro_13 == True and (use_one_day_sol == True or igs_repro2 == True):
    raise RuntimeError('Invalid erp options! Cannot have both cod and erp hosts')

  ## compute delta time (in days) from today
  dt = datetime.datetime.today() - datetm
  dt = dt.days + (dt.seconds // 3600) /24.0

  options = []

  ## depending on deltatime, get a list of optional erp files
  if dt >= 15:
    options =   __cod_erp_all_final__(use_repro_13, use_one_day_sol, igs_repro2)
  elif dt >= 4:
    options  =  __cod_erp_all_final__(use_repro_13, use_one_day_sol, igs_repro2)
    options +=  __cod_erp_all_final_rapid__()
  elif dt >= 0:
    options  = __cod_erp_all_final_rapid__()
    options += __cod_erp_all_early_rapid__()
  elif dt > -1:
    options  = __cod_erp_all_early_rapid__()
    options += __cod_erp_all_ultra_rapid__()
  elif dt > -15:
    options  = __cod_erp_all_prediction__()
  else:
    raise RuntimeError('DeltaTime two far in the future %+03.1f' %dt)

  ## compute the needed date formats
  week, sow = bernutils.gpstime.pydt2gps(datetm)
  dow       = int(datetm.strftime('%w'))
  iyear     = int(datetm.strftime('%Y'))

  ## need to replace the dates
  options = [ i.replace('yyyy', ('%04i' %iyear)).replace('wwwwd', ('%04i%01i' %(week, dow))).replace('wwww', ('%04i' %week)) for slst in options for i in slst ]
  options = [ options[x:x+4] for x in xrange(0, len(options), 4) ]

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
      ret_list = [saveas, '%s%s%s' %(triple[1], triple[2], triple[0]), triple[3]]
      break
    except:
      pass

  if len(ret_list) == 0:
    raise RuntimeError('Failed to download erp file (0/%1i)' %len(options))

  if __DEBUG_MODE__ == True:
    print 'Tries: %1i/%1i Downloaded %s to %s' %(nr_tries, len(options), ret_list[1], ret_list[0])

  if tojson:
    jdict = {
        'info'    : JSON_INFO,
        'format'  : JSON_FORMAT,
        'satsys'  : '',
        'ac'      : 'cod',
        'type'    : ret_list[2],
        'host'    : COD_HOST,
        'filename': ret_list[1]
    }
    ##  print(json.dumps(jdict))
    return ret_list, jdict
  
  return ret_list

def getErp(**kwargs):
  ''' This function is responsible for downloading an optimal, valid erp file
      for a given date. The user-defined input variables can further narrow
      down the possible choices.

      :param datetm:          The date(time) for wich we want the erp information, as
                              a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param ac:             (Optional) Choose the Analysis Center; default is
                              ``'cod'``. The valid string for this option are:

                              * ``'cod'`` is CODE analysis center
                              * ``'igs'`` is IGS

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :param use_repro_13:    (Optional) Use (or not) REPRO_2013 products (only 
                              an option for final erp when the ac is CODE).

      :param use_one_day_sol: (Optional) Use the clean, one-day-solution (only 
                              an option for final erp when the ac is CODE).

      :param igs_repro2:      (Optional) Use IGS 2nd reprocessing campaign 
                              product files.

      :tojson:                Ouput a json list describing the product

      :returns:               A list containing saved file and the remote file.

      .. note::
        #. Parameters ``use_repro_13``, ``use_one_day_sol`` and ``igs_repro2``
           are only relevant to final products (else they'll be ignored).
        #. Final, one-day-solutions and igs repro2 erp's are only available
           at the CDDIS ftp host.

  '''

  _args = { 'ac': 'cod', 'out_dir': None, 'use_repro_13': False, 'use_one_day_sol': False, 'igs_repro2': False, 'tojson': False }
  _args.update(**kwargs)

  if 'date' in kwargs:
    datetm = kwargs['date']
  else:
    if 'year' not in kwargs or 'doy' not in kwargs:
      raise RuntimeError('Should provide YEAR and DoY.')
    else:
      datetm = datetime.datetime.strptime('%s-%s'%(kwargs['year'], kwargs['doy']), '%Y-%j').date()

  ## Do nothing :) just pass arguments to the ac-specific function
  if _args['ac'].lower() == 'cod':
    return getCodErp(datetm, _args['out_dir'], _args['use_repro_13'], _args['use_one_day_sol'], _args['igs_repro2'], _args['tojson'])
  elif _args['ac'].lower() == 'igs':
    return getIgsErp(datetm, _args['out_dir'], _args['igs_repro2'], _args['tojson'])
  else:
    raise RuntimeError('Invalid Analysis Center: %s.' %_args['ac'])
