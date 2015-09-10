import os
import datetime
import ftplib

import bernutils.gpstime
import bernutils.webutils
import bernutils.products.prodgen

COD_HOST      = bernutils.products.prodgen.COD_HOST
COD_DIR       = bernutils.products.prodgen.COD_DIR
COD_DIR_2013  = bernutils.products.prodgen.COD_DIR_2013

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

      .. note:: This functions uses :func:`bernutils.products.pydcb._getFinalDcb_`
        and :func:`bernutils.products.pydcb._getRunningDcb_`

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