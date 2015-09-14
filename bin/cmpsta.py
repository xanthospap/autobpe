#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : 
version               : v-0.5
created               : JUN-2015

usage                 : Python routine to 

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
import bernutils.bsta
import bernutils.webutils
import bernutils.products.prodgen

## ------------ DEBUGING FLAGS
DDEBUG = True

## Global variables
stations            = []
reference_sta       = ''
local_sta           = ''

## help function
def help (i):
  print ""
  print ""
  sys.exit(i)

## Resolve command line arguments
def main (argv):

  if len(argv) < 1:
    help(1)

  try:
    opts, args = getopt.getopt(argv,'hs:r:l:',['help', 'stations=', 'reference-sta=', 'local-sta='])
  except getopt.GetoptError:
    help(1)

  for opt, arg in opts:
    if opt in ('-h', 'help'):
      help(0)
    elif opt in ('-s', '--stations'):
      station_list = arg.split(',')
      global stations
      stations += station_list
    elif opt in ('-r', '--reference-sta'):
      global reference_sta
      reference_sta = arg
    elif opt in ('-l', '--local-sta'):
      global local_sta
      local_sta = arg
    else:
      print >> sys.stderr, 'Invalid command line argument: %s' %opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

## check if local .STA file exists
if not os.path.isfile(local_sta):
   print >> sys.stderr, 'Error. Cannot find local .STA file : %s' %local_sta
   os.exit(1)

##  check for the reference .STA; if not present, try to download it from
##+ CODE's ftp
if not os.path.isfile(reference_sta):
  try:
    bernutils.webutils.grabFtpFile(bernutils.products.prodgen.COD_HOST, '/aiub/BSWUSER52/STA/', '%s'%reference_sta)
  except:
    print >> sys.stderr, 'Error. Cannot find or download reference .STA file : %s' %reference_sta
    sys.exit(1)

## create the two StaFile instances
refsta = bernutils.bsta.StaFile(reference_sta)
locsta = bernutils.bsta.StaFile(local_sta)

## read Type001 info (as dictionary) from both .STA files
ref_dict_01 = refsta.__match_type_001__(stations)
loc_dict_01 = locsta.__match_type_001__(stations)

## read Type002 info (as dictionary) from both .STA files
ref_dict_02 = refsta.__match_type_002__(ref_dict_01)
loc_dict_02 = locsta.__match_type_002__(loc_dict_01)

## do the comparisson; first match Type 001 records
for key1, val1 in ref_dict_01.iteritems():
  val2 = loc_dict_01[key1]
  __val1 = val1
  __val2 = val2
  if len(__val2) > len(__val1):
    __val1, __val2 = __val2, __val1
  for rc1 in __val1:
    if not any(bernutils.bsta.loose_compare_type1(rc1, rc2) for rc2 in __val2):
      print '!!Mismatch!! Station %s, Type 001, record: [%s]' %(key1, rc1)

## do the comparisson; first match Type 002 records
for key1, val1 in ref_dict_02.iteritems():
  val2 = loc_dict_02[key1]
  __val1 = val1
  __val2 = val2
  if len(__val2) > len(__val1):
    __val1, __val2 = __val2, __val1
  for rc1 in __val1:
    if not any(bernutils.bsta.loose_compare_type2(rc1, rc2) for rc2 in __val2):
      print '!!Mismatch!! Station %s.\n Type 002, record: [%s]' %(key1, rc1)

## all done; exit
sys.exit(0)