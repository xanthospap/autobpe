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

usage                 : 

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
import datetime
import subprocess
import getopt
import glob
import MySQLdb
import traceback

## Debug Mode
DDEBUG_MODE = True

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## globals
campaign    = None
sat_sys     = 'GPS'
sol_type    = None
prod_type   = None
start_epoch = None
stop_epoch  = None
proc_at     = datetime.datetime.now()
host_ip     = None
host_dir    = None
filename    = None

## Resolve command line arguments
def main (argv):

  if len(argv) < 1: help(1)

  try:
    opts, args = getopt.getopt(argv,'h',[
      'help','campaign-name=','sattellite-system=','solution-type=','product-type=','start-epoch=',
      'end-epoch=','processed-at=','host-ip=','host-dir=','product-name='])

  except getopt.GetoptError: help(1)

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      help(0)
    elif opt in ('--campaign-name'):
      global campaign
      campaign = arg
    elif opt in ('--satellite-system'):
      global sat_sys
      sat_sys = arg
    elif opt in ('--solution-type'):
      global sol_type
      sol_type = arg
    elif opt in ('--product-type'):
      global prod_type
      prod_type = arg
    elif opt in ('--Rear'):
      global year
      year = arg
    elif opt in ('-d', '--doy'):
      global doy
      doy = arg
    elif opt in ('-u', '--uppercase'):
      global touppercase
      touppercase = True
    elif opt in ('-p', '--path'):
      global outputdir
      outputdir = arg
      if not os.path.exists(outputdir):
        print >> sys.stderr, 'ERROR. Directory does not exist: %s'%arg
        sys.exit(2)
    elif opt in ('-z', '--uncompress'):
      global uncompressZ
      uncompressZ = True
    else:
      print >> sys.stderr, 'Invalid command line argument: %s'%opt
