#! /usr/bin/python

## first download products to the datapool area.
## copy to campaign orb folder
## uncompress

import os, sys, datetime, traceback
import getopt, shutil
import json

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
REPORT   = None
JSON_OUT = False
REPRO2   = False
REPRO13  = False

##  given an (input) filename, check to see if this file is UNIX-compressed,
##+ i.e. if it ends with '.Z'
def isUnixCompressed(fn): return len(fn) > 2 and fn[-2:] == '.Z'

## Resolve command line arguments
def main(argv):

  try:
    opts, args = getopt.getopt(argv,'y:d:p:o:a:s:ir:',[
      'year=', 'doy=', 'datapool=', 'destination=', 'analysis-center=','satellite-system=', 'download-ion','report=', 'use-repro2', 'use-repro13'])
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
    elif opt in ('--use-repro2'):
      global REPRO2
      REPRO2 = True
    elif opt in ('--use-repro13'):
      global REPRO13
      REPRO13 = True
    elif opt in ('-r', '--report'):
      global REPORT
      if arg == 'ascii':
        REPORT = arg
      elif arg == 'html':
        REPORT = arg
      elif arg == 'json':
        REPORT = arg
        global JSON_OUT
        JSON_OUT = True
      else:
        raise RuntimeError('Invalid report option; can use either ascii or html')
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
if SAT_SYS == 'gps' or SAT_SYS == 'GPS': ussr = False

info_dict = {}
json_dict = {}

error_at = 0
try:
  info_dict['sp3'] = bernutils.products.pysp3.getOrb(date=py_date, \
    ac=AC, \
    out_dir=DATAPOOL, \
    use_glonass=ussr, \
    igs_repro2=REPRO2, \
    use_repro_13=REPRO13, \
    tojson=JSON_OUT)
  error_at += 1
  if JSON_OUT:
    json_dict['sp3'] = info_dict['sp3'][-1]
    info_dict['sp3'] = map(list,info_dict['sp3'][0:-1])
  ##  print 'Sp3 info list:', info_dict['sp3']
  ##  would print something like:
  ##  [['/home/bpe2/data/GPSDATA/DATAPOOL/COD16770.EPH.Z', \
  ##    'ftp.unibe.ch/aiub/CODE/2012/COD16770.EPH.Z', \
  ##    'final']]

  info_dict['erp'] = bernutils.products.pyerp.getErp(date=py_date, \
    ac=AC, \
    out_dir=DATAPOOL, \
    igs_repro2=REPRO2, \
    use_repro_13=REPRO13, \
    tojson=JSON_OUT)
  error_at += 1
  if JSON_OUT:
    json_dict['erp'] = info_dict['erp'][-1]
    info_dict['erp'] = map(list,info_dict['erp'][0:-1])

  info_dict['dcb'] = bernutils.products.pydcb.getCodDcb(stype='c1_rnx', \
    datetm=py_date, \
    out_dir=DATAPOOL, \
    tojson=JSON_OUT)
  error_at += 1
  if JSON_OUT:
    json_dict['dcb'] = info_dict['dcb'][-1]
    info_dict['dcb'] = map(list,info_dict['dcb'][0:-1])

  if DWNL_ION:
    info_dict['ion'] = bernutils.products.pyion.getCodIon(py_date, DATAPOOL, tojson=JSON_OUT)
    if JSON_OUT:
      json_dict['ion'] = info_dict['ion'][-1]
      info_dict['ion'] = map(list,info_dict['ion'][0:-1])

  dow, mnth, yr2 = py_date.strftime("%w-%m-%y").split('-')
  gpsw, sow = bernutils.gpstime.pydt2gps(py_date)

  sp3file = os.path.join(DEST_ORB,\
    ("%s%4i%1i.PRE"%(AC, gpsw, int(dow))))
  if isUnixCompressed(info_dict['sp3'][0][0]):
    sp3file += '.Z'
  info_dict['sp3'].append(sp3file)

  if AC.lower() == 'cod':
    erpfile = os.path.join(DEST_ORB,\
      "%s%4i%1i.ERP"%(AC, gpsw, int(dow)))
  else:
    erpfile = os.path.join(DEST_ORB,\
      "%s%4i%1i.IEP"%(AC, gpsw, int(dow)))
  if isUnixCompressed(info_dict['erp'][0][0]):
    erpfile += '.Z'
  info_dict['erp'].append(erpfile)

  dcbfile = os.path.join(DEST_ORB,\
    "P1C1%s%s.DCB"%(yr2, mnth))
  if isUnixCompressed(info_dict['dcb'][0][0]):
    dcbfile += '.Z'
  info_dict['dcb'].append(dcbfile)

  if DWNL_ION:
    ionfile = os.path.join(DEST_ORB.replace('/ORB', '/ATM'),\
        "COD%4i%1i.ION"%(gpsw, int(dow)))
    if isUnixCompressed(info_dict['ion'][0][0]):
      ionfile += '.Z'
    info_dict['ion'].append(ionfile)

  for i, j in info_dict.iteritems():
    print>>sys.stderr, 'Moving %s to %s'%(j[0][0], j[1])
    shutil.copy(j[0][0], j[1])
    print "Checking if file is compressed:",j[1]
    if isUnixCompressed( j[1] ):
      j[1] = bernutils.webutils.UnixUncompress( j[1] )
      print 'file uncompressed; set to',j[1]
    dfiles_str = ( ', '.join(str(p) for p in [j[1]]) ).replace('[','').replace(']','')
    if REPORT == 'ascii':
      print '[PRODUCTS::%s] Downloaded file %s ; moved to %s'%(i, dfiles_str, j[2])
    elif REPORT == 'html':
      print '<p>Product type: <strong>%s</strong> : \
          downloaded file(s) <code>%s</code> ; \
          moved to <code>%s</code></p>'%(i, dfiles_str, j[1])
    #if isUnixCompressed(j[1]):
    #  print "[handle_products] Uncompressing %s"%j[1]
    #  bernutils.webutils.UnixUncompress(j[1])
    #else:
    #  print "file %s is not compressed"%j[1]

  for idx, val in enumerate(json_dict):
    if idx == len(json_dict) - 1:
      end = ""
    else:
      end = ","
    print "\"%s\":"%val, str(json_dict[val]).replace('\'', '\"'), end

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
