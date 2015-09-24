#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : rnx_dnwl.py
version               : v-0.5
created               : JUN-2015

usage                 : Python routine to help the downloading of RINEX files.
                        This routine will connect to a database and return all
                        information needed to download a RINEX file

exit code(s)          : 0 -> success
                      : 1 -> error

description           :

notes                 :

TODO                  :
bugs & fixes          :
last update           :

report any bugs to    :
                      : Xanthos Papanikolaou xanthos@mail.ntua.gr
                      : Demitris Anastasiou  danast@mail.ntua.gr
'''

## Import libraries
import sys
import os
import getopt
import datetime
import MySQLdb
import traceback
import re

## Global variables / default values
HOST_NAME     = '147.102.110.73'
USER_NAME     = 'bpe2'
PASSWORD      = 'webadmin'
DB_NAME       = 'procsta'
NETWORK       = ''
YEAR          = 0
DOY           = 0
FIX_FILE      = '/home/bpe2/tables/fix/IGb08.FIX'
PTH2RNX       = '/home/bpe2/data/DATAPOOL'
SESSION       = '0'
USE_MARKER_NR = True

def help():
  print "THIS SHOULD BE validate_rnx's help message"
  return

## Resolve command line arguments
def main (argv):

  ## print 'all my arguments are: ', argv[:]

  if len(argv) < 1:
    print >>sys.stderr, 'ERROR. Cannot run with zero arguments!'
    help()
    sys.exit(1)

  try:
    opts, args = getopt.getopt(argv,'hn:y:d:f:p:s:',[
      'help', 'network=', 'year=','doy=','fix-file=', 'rinex-path=', 'session=', 'no-marker-numbers'])

  except getopt.GetoptError:
    help()
    print >>sys.stderr, 'ERROR. Getopt failed; check argv/argc!'
    sys.exit(1)

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      help()
      sys.exit(0)
    elif opt in ('-n', '--network'):
      global NETWORK
      NETWORK = arg
    elif opt in ('-y', '--year'):
      global YEAR
      YEAR = arg
    elif opt in ('-d', '--doy'):
      global DOY
      DOY = arg
    elif opt in ('-f', '--fix-file'):
      global FIX_FILE
      FIX_FILE = arg
    elif opt in ('-p', '--rinex-path'):
      global PTH2RNX
      PTH2RNX = arg
    elif opt in ('-s', '--session'):
      global SESSION
      SESSION = arg
    elif opt in ('--no-marker-numbers'):
      global USE_MARKER_NR
      USE_MARKER_NR = False
    else:
      print >>sys.stderr, 'ERROR. Invalid command line argument: %s'%opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

  ## validate cmd arguments
  if not os.path.isfile(FIX_FILE):
    print >>sys.stderr, 'Invalid Reference fix file: %s'%(FIX_FILE)
    sys.exit(1)
  if not os.path.isdir(PTH2RNX):
    print >>sys.stderr, 'Invalid path to RINEX: %s'%(PTH2RNX)
    sys.exit(1)
  if len(SESSION) != 1:
    print >>sys.stderr, 'Invalid session identifier: %s'%(SESSION)
    sys.exit(1)

  ## read all lines from the .FIX file
  with open(FIX_FILE, 'r') as f:
    lines = f.readlines()

  ## Resolve the input date
  try:
    dt = datetime.datetime.strptime('%s-%s'%(int(YEAR),int(DOY)),'%Y-%j')
  except:
    print >>sys.stderr, 'Invalid date: year = %s doy = %s'%(YEAR, DOY)
    sys.exit(1)

  ## Month as 3-char, e.g. Jan (sMon)
  ## Month as 2-char, e.g. 01 (iMon)
  ## Day of month as 2-char, e.g. 05 (DoM)
  ## Day of year a 3-char, e.g. 157 (DoY)
  Year, Cent, sMon, iMon, DoM, DoY = dt.strftime('%Y-%y-%b-%m-%d-%j').split('-')

  ## try connecting to the database server
  try:
    db  = MySQLdb.connect(host=HOST_NAME, user=USER_NAME, passwd=PASSWORD, db=DB_NAME)
    cur = db.cursor()

    QUERY='SELECT stacode.mark_name_DSO, stacode.mark_name_OFF, stacode.mark_numb_OFF, stacode.station_name FROM stacode JOIN station ON stacode.stacode_id=station.stacode_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE network.network_name="%s";'%(NETWORK)

    cur.execute(QUERY)
    SENTENCE = cur.fetchall()
    '''
    the answer should be a list of tuples, where each station of the network
    reports its name(DSO), name(official), number(official) full_name(?), e.g.
    ('pdel', 'pdel', '31906M004', '')
    '''
    print '%-15s %-16s %-9s %-9s'%("RINEX", "MARKER NAME", "AVAILABLE", "REFERENCE")
    for tpl in SENTENCE:
      rnx_file      = os.path.join(PTH2RNX, tpl[0] + ('%s%s.%sd.Z'%(DoY, SESSION, Cent)) )
      marker_name   = tpl[1]
      marker_number = tpl[2]
      rnx_exists    = 'No'
      rnx_is_ref    = 'No'

      if USE_MARKER_NR:
        used_name = '%s %s' %(marker_name, marker_number)
      else:
        used_name = '%s' %(marker_name)
      if len(marker_name) != 4:
        print >> sys.stderr, 'ERROR ! Invalid marker number %s for station %s'%(marker_name, tpl[0])
        raise RuntimeError('')
      if os.path.isfile(rnx_file): rnx_exists = 'Yes'
      if filter(lambda x: re.search(r'^%s\s+'%(used_name.upper()), x), lines):
        rnx_is_ref = 'Yes'
      print '%-15s %-16s %-9s %-9s'%(os.path.basename(rnx_file), used_name.upper(), rnx_exists, rnx_is_ref)

  except:
    try: db.close()
    except: pass
    print >> sys.stderr, '***ERROR ! Cannot connect/query database server.'
    sys.exit(1)

  sys.exit(0)
