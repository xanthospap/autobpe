import os
import datetime
import ftplib
import json

import bernutils.gpstime
import bernutils.webutils
import bernutils.products.prodgen

__DEBUG_MODE__ = False

COD_HOST      = bernutils.products.prodgen.COD_HOST
IGS_HOST      = bernutils.products.prodgen.IGS_HOST
COD_DIR       = bernutils.products.prodgen.COD_DIR
COD_DIR_2013  = bernutils.products.prodgen.COD_DIR_2013
IGS_DIR       = bernutils.products.prodgen.IGS_DIR
IGS_DIR_REP2  = bernutils.products.prodgen.IGS_DIR_REP2

''' json product class
{
    "info"             : "Orbit Information",
    "format"           : "sp3",
    "satsys"           : "gps",
    "ac"               : "cod",
    "type"             : "final",
    "host"             : "cddis",
    "filename"         : "igs18753.sp3.Z"
}
'''
JSON_INFO = "Ionospheric correction file."
JSON_FORMAT = "ION"
JSON_SATSYS = ""
JSON_AC = "COD"
JSON_HOST = COD_HOST

def __cod_ion_all_final__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid final code-generated ion file. 
      These information can be later used to download the file.

      :returns:               A valid sp3 FILENAME, a HOST and a DIRectory (in 
                              the HOST where the file FILENAME is to be found)
                              for each possible, valid, ion file. Using these
                              information, one can download the file. Every possible
                              (triple) combination is returned as a list (so the
                              function returns a list of lists).

      .. note:: The options here should **exactly match** the ones described 
                in the  ``products.rst`` file.

  '''
  FILENAME = 'CODwwwwd.ION.Z'
  HOST     = COD_HOST
  DIR      = COD_DIR + '/yyyy/'

  return [[ FILENAME, HOST, DIR, 'final' ]]

def __cod_ion_all_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid rapid code-generated ion file.
      These information can be later used to download the file.

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
                the file FILENAME is to be found) list for every possible 
                final-rapid ion file. So, alist of lists.

      .. note:: The options here should **exactly match** the ones described in the
                ``products.rst`` file.

  '''
  ## final rapid (in root folder)
  FILENAME = 'CODwwwwd.ION_R'
  HOST     = COD_HOST
  DIR      = COD_DIR

  return  [[FILENAME, HOST, DIR, 'rapid']]

def __cod_ion_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid code-generated ion file.
      These information can be later used to download the file.

      :returns: A valid ion FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found). These are concatenated into a list.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  return [[ 'COD.ION_U', COD_HOST, COD_DIR, 'ultra-rapid' ]]

def __cod_ion_all_prediction__(str_id='P5'):
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid prediction code-generated ion file,
      based on the input parameters. These information can be later used to 
      download the file.

      :param str_id: The id of the solution type (as string). Can be any of:

        * ``'P5'``,
        * ``'P2'``
        * ``'P'``

      :returns: A valid erp FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found) for a CODE prediction ion file,
        depending on the ``str_id`` parameter.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  if str_id == 'P5':
    FILENAME = 'CODwwwwd.ION_P5'
  elif str_id == 'P2':
    FILENAME = 'CODwwwwd.ERP_P2'
  elif str_id == 'P':
    FILENAME = 'CODwwwwd.ERP_P'
  else:
    raise RuntimeError('Invalid ION prediction flag %s.', str_id)

  return [[ FILENAME, COD_HOST, COD_DIR, 'prediction (%s)'%str_id ]]

def getCodIon(datetm, out_dir=None, tojson=False):
  ''' This function is responsible for downloading an optimal, valid ion file
      for a given date.

      :param datetm:          The date(time) for wich we want the erp information, as
                              a Python ``datetime.datetime`` or ``dadtetime.date``
                              instance.

      :param out_dir:         (Optional) Directory where the downloaded file is
                              to be saved.

      :returns:               A list containing saved file and the remote file.

      .. note::
        #. The options here should **exactly match** the ones described in
           the ``products.rst`` file.
        #. This functions uses :func:`bernutils.products.pyion.__cod_ion_all_final__`,
           :func:`bernutils.products.pyion.__cod_ion_all_rapid__`,
           :func:`bernutils.products.pyion.__cod_ion_all_ultra_rapid__` and
           :func:`bernutils.products.pyion.__cod_ion_all_prediction__`.

  '''
  ## output dir must exist
  if out_dir and not os.path.isdir(out_dir):
    raise RuntimeError('Invalid directory: %s -> getCodIon.' %out_dir)

  ## transform date to datetime (if needed)
  if type(datetm) == datetime.date:
    datetm = datetime.datetime.combine(datetm, datetime.datetime.min.time())

  ## compute delta time (in days) from today
  dt = datetime.datetime.today() - datetm
  dt = dt.days + (dt.seconds // 3600) /24.0

  options = []

  ## depending on deltatime, get a list of optional erp files
  if dt >= 15:
    options =   __cod_ion_all_final__()
  elif dt >= 4:
    options  =  __cod_ion_all_final__()
    options +=  __cod_ion_all_rapid__()
  elif dt >= 1:
    options  = __cod_ion_all_rapid__()
    options += __cod_ion_all_ultra_rapid__()
  elif dt > -1:
    options  = __cod_ion_all_ultra_rapid__()
    options += __cod_ion_all_prediction__()
  elif dt > -3:
    options  = __cod_ion_all_prediction__()
  else:
    raise RuntimeError('DeltaTime two far in the future %+03.1f' %dt)

  ## compute the needed date formats
  week, sow = bernutils.gpstime.pydt2gps(datetm)
  dow       = int(datetm.strftime('%w'))
  iyear     = int(datetm.strftime('%Y'))

  ## need to replace the dates
  options = [ i.replace('yyyy', ('%04i' %iyear)).replace('wwwwd', ('%04i%01i' %(week, dow))) for slst in options for i in slst ]
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
    raise RuntimeError('Failed to download ion file (0/%1i)' %len(options))

  if __DEBUG_MODE__ == True:
    print 'Tries: %1i/%1i Downloaded %s to %s' %(nr_tries, len(options), ret_list[1], ret_list[0])

  if tojson:
    jdict = {
        'info'    : JSON_INFO,
        'format'  : JSON_FORMAT,
        'satsys'  : JSON_SATSYS,
        'ac'      : JSON_AC,
        'type'    : ret_list[2],
        'host'    : JSON_HOST,
        'filename': ret_list[1]
    }
    print(json.dumps(jdict))

  return ret_list
