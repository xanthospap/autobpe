#! /usr/bin/python

## first download products to the datapool area.
## copy to campaign orb folder
## uncompress

import os, sys, datetime, traceback
import getopt, shutil
import bernutils.gpstime
import bernutils.products.pysp3
import bernutils.products.pyerp
import bernutils.products.pydcb
import bernutils.products.pyion

##  globals
YEAR     = None
DOY      = None
DATAPOOL = None
DEST_ORB = None
AC       = None
SAT_SYS  = 'GPS'
DWNL_ION = False

def isUnixCompressed(fn): return len(fn) > 2 and fn[-2:] == '.Z'

## Resolve command line arguments
def main(argv):

  try:
    opts, args = getopt.getopt(argv,'y:d:p:o:a:s:i',[
      'year=', 'doy=', 'datapool=', 'destination=', 'analysis-center=','satellite-system=', 'download-ion'])
  except getopt.GetoptError:
    print>>sys.stderr,"ERROR. Getopt error ",argv
    sys.exit(1)

  for opt, arg in opts:
    if opt in ('-y', '--year'):
      global YEAR
      YEAR = arg
    elif opt in ('-d', '--doy'):
      global DOY
      DOY = arg
    elif opt in ('-p', '--datapool'):
      global DATAPOOL
      DATAPOOL = arg
    elif opt in ('-o', '--destination'):
      global DEST_ORB
      DEST_ORB = arg
    elif opt in ('-a', '--analysis-center'):
      global AC
      AC = arg.upper()
    elif opt in ('-s', '--satellite-system'):
      global SAT_SYS
      SAT_SYS = arg
    elif opt in ('-i', '--download-ion'):
      global DWNL_ION
      DWNL_ION = True
    else:
      print >> sys.stderr, 'Invalid command line argument: %s'%opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

if not DATAPOOL or not os.path.isdir(DATAPOOL):
  print>>sys.stderr,"ERROR. Invalid datapool area."
  sys.exit(1)
if not DEST_ORB or not os.path.isdir(DEST_ORB):
  print>>sys.stderr,"Invalid campaign area."
  sys.exit(1)

try:
  py_date = datetime.datetime.strptime('%s-%s'%(YEAR, DOY), '%Y-%j').date()
except:
  print >>sys.stderr, 'ERROR. Failed to parse date!.'
  sys.exit(1)

ussr = True
if SAT_SYS == 'gps' or SAT_SYS == 'GPS':
  ussr = False

info_dict = {}

error_at = 0
try:
  info_dict['sp3'] = bernutils.products.pysp3.getOrb(date=py_date, \
    ac=AC, \
    out_dir=DATAPOOL, \
    use_glonass=ussr)
  error_at += 1

  info_dict['erp'] = bernutils.products.pyerp.getErp(date=py_date, \
    ac=AC, \
    out_dir=DATAPOOL)
  error_at += 1

  info_dict['dcb'] = bernutils.products.pydcb.getCodDcb(stype='c1_rnx', \
    datetm=py_date, \
    out_dir=DATAPOOL)
  error_at += 1

  if DWNL_ION:
    info_dict['ion'] = bernutils.products.pyion.getCodIon(py_date, DATAPOOL)

  ##  Alright! all products downloaded! now we need to make an easy list to
  ##+ pass to bash, to link the downloaded files from directory D to the /ORB
  ##+ directory.
  ##  Whatever the names of the downloaded files, the linked destination should
  ##+ use the standard name, e.g. if we downloaded the file igu18701_06.sp3.Z
  ##+ we should link to D/igs18701.sp3.Z

  dow, mnth, yr2 = py_date.strftime("%w-%m-%y").split('-')
  gpsw, sow = bernutils.gpstime.pydt2gps(py_date)

  sp3file = os.path.join(DEST_ORB,\
    ("%s%4i%1i.PRE"%(AC, gpsw, int(dow))))
  if isUnixCompressed(info_dict['sp3'][0]):
    sp3file += '.Z'
  info_dict['sp3'].append(sp3file)

  if AC.lower() == 'cod':
    erpfile = os.path.join(DEST_ORB,\
      "%s%4i%1i.ERP"%(AC, gpsw, int(dow)))
  else:
    erpfile = os.path.join(DEST_ORB,\
      "%s%4i%1i.IEP"%(AC, gpsw, int(dow)))
  if isUnixCompressed(info_dict['erp'][0]):
    erpfile += '.Z'
  info_dict['erp'].append(erpfile)

  dcbfile = os.path.join(DEST_ORB,\
    "P1C1%s%s.DCB"%(yr2, mnth))
  if isUnixCompressed(info_dict['dcb'][0]):
    dcbfile += '.Z'
  info_dict['dcb'].append(dcbfile)

  if DWNL_ION:
    ionfile = os.path.join(DEST_ORB.replace('/ORB', '/ATM'),\
        "COD%4i%1i.ION"%(gpsw, int(dow)))
    if isUnixCompressed(info_dict['ion'][0]):
      ionfile += '.Z'
    info_dict['ion'].append(ionfile)

  for i, j in info_dict.iteritems():
    shutil.copy(j[0], j[2])
    if isUnixCompressed(j[2]):
      bernutils.webutils.UnixUncompress(j[2])

except Exception, e:
  ## where was the exception thrown ?
  if error_at == 0:
    print >>sys.stderr, 'ERROR. Failed to download orbit information.'
  elif error_at == 1:
    print >>sys.stderr, 'ERROR. Failed to download erp information.'
  elif error_at == 2:
    print >>sys.stderr, 'ERROR. Failed to download dcb information.'
  else:
    print >>sys.stderr, 'WTF! Should have come been here!'
  ## log exception/stack call
  print >>sys.stderr,'*** Stack Rewind:'
  exc_type, exc_value, exc_traceback = sys.exc_info()
  traceback.print_exception(exc_type, exc_value, exc_traceback, \
    limit=10, file=sys.stderr)
  print >>sys.stderr,'*** End'
  ## exit with error
  sys.exit(1)

sys.exit(0)
