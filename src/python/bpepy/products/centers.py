#! /usr/bin/python

""" @package centers
  Various functions to manipulate gnss analysis and data centers

  Created         : Sep 2014
  Last Update     : Oct 2014

  List of Changes :

  National Technical University of Athens
  Dionysos Satellite Observatory
  Higher Geodesy Laboratory
"""

## Name of Analysis Centers
AC_CENTER  = ['CODE','IGS']

## 3digit identifier of Analysis Centers
AC_ID      = ['cod','igs']

## Description of Analysis Centers
AC_DESCRIPTION = ['Center for Orbit Determination in Europe','International GNSS Service']

## IGS data centers (ftps)
IGS_HOSTS    = ['cddis.gsfc.nasa.gov','igs.ensg.ign.fr']

## Gps product area for IGS data centers
PRODUCT_AREA = ['pub/gps/products/','pub/igs/products/']

## Glonass product area for IGS data centers
GLONASS_PRODUCT_AREA = ['pub/glonass/products/','pub/igs/products/']

def acinfo (id):
  """ Decribe an Analysis Center.

    This function will search through the AC_ID list for a given AC and
    return a list with its details.

    @param id     3-digit string describing the AC id
    @retval list  [Exit_Status,AC_CENTER,AC_ID,AC_DESCRIPTION]

    Exit Codes:
        :  0 all ok
        :  1 error
  """
  try:
    i = AC_ID.index (id)
    status = 0
  except:
    status = 1
  if status == 1:
    return [1,'','','']
  else:
    return [0,AC_CENTER[i],AC_ID[i],AC_DESCRIPTION[i]]
