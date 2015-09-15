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

  return [[ FILENAME, HOST, DIR ]]

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

  return  [[FILENAME, HOST, DIR]]

def __cod_ion_all_ultra_rapid__():
  ''' Utility function; do not use as standalone. This function will return the
      filename, host, and hostdir of a valid ultra-rapid code-generated ion file.
      These information can be later used to download the file.

      :returns: A valid ion FILENAME, a HOST and a DIRectory (in the HOST where 
        the file FILENAME is to be found). These are concatenated into a list.

      .. note:: The options here should **exactly match** the ones described in 
        the ``products.rst`` file.

  '''
  return [[ 'COD.ION_U', COD_HOST, COD_DIR ]]

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

  return [[ FILENAME, COD_HOST, COD_DIR ]]