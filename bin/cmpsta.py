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
                      : 2 -> station missing (from one or both .STA files)
                      : 3 -> found 1 or more discrepancies

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
split_output        = False
no_marker_numbers   = False
stations_diff       = [] ## see Note 1

'''
Note 1
-----------------------
Why do we need the ``stations_diff`` list? Say we compare a station STA. We find
differences in the Type 001 records, so we create a file ``STA.stadf`` and write
the Type001 diffs. Then we compare its Type002 records and we find (again) different
records. Now, if we re-open the file ``STA.stadf`` to report these Type002 diffs,
the (already written) Type001 diffs will disapear. So, before opening the file to
write any Type002 records, we first check if the station occurs in the ``stations_diff``;
if it does, then this means that we have already created a new file ``STA.stadf``
with Type001 records, and we need to append to that.
'''


## help function
def help (i):
  print ""
  print ""
  sys.exit(i)

def print_incosistency(itype, station, l1, fn1, l2, fn2):
  ''' Print discrepancies in some Type.

      :param itype:   The type for which to report the discrepancies (1, or 2)
      :param station: The name of the station
      :param l1:      The list cointaining the Type 00x records for this stations
        from the first file (i.e. ``fn1``)
      :param fn1:     The name of the first .STA file
      :param l2:      The list cointaining the Type 00x records for this stations
        from the second file (i.e. ``fn2``)
      :param fn2:     The name of the second .STA file

      .. warning:: If the global variable ``split_output`` is ``True``, then this
        function will report the discrepancies in a station-specific file, named
        ``station``.stadf; else all output is written to stdout

  '''
  if split_output == True:
    ## warning! do not use wildcards in station/file names
    fnn = station
    if station[-1] == '*': fnn = station[0:-1]+'__'
    if station[-1] == '?': fnn = station[0:-1]+'_'
    print 'Redirecting to %s.stadf' %fnn
    fn = '%s.stadf' %fnn
    temp = sys.stdout #store original stdout object for later
    if itype == 2 and station in stations_diff:
      sys.stdout = open(fn, 'a')
    else:
      sys.stdout = open(fn, 'w')

  print 'INCONSISTENCY FOR STATION %s TYPE %1i' %(station, itype)
  print 'File %s contains the Type %03i records:' %(fn1, itype)
  for i in l1:
    print '[%s]' %i
  print 'File %s contains the Type %03i records:' %(fn2, itype)
  for i in l2:
    print '[%s]' %i

  if split_output == True:
    sys.stdout.close()
    sys.stdout = temp #restore print commands to interactive prompt

## Resolve command line arguments
def main(argv):

  if len(argv) < 1:
    help(1)

  try:
    opts, args = getopt.getopt(argv,'hs:r:l:',['help', 'stations=', 'reference-sta=', 'local-sta=', 'splitout', 'no-marker-numbers'])
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
    elif opt in ('--splitout'):
      global split_output
      split_output = True
    elif opt in ('--no-marker-numbers'):
      global no_marker_numbers
      no_marker_numbers = True
    else:
      print >> sys.stderr, 'Invalid command line argument: %s' %opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

## check if local .STA file exists
if not os.path.isfile(local_sta):
   print >> sys.stderr, 'Error. Cannot find local .STA file : %s' %local_sta
   sys.exit(1)

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

## the exit status; always set it to the right value
EXIT_STATUS = 0

##  find missing stations; we only care if the station is missing from the local
##+ sta file **NOT** the remote one.
missing_from_d1 = [ x for x in ref_dict_01 if len(ref_dict_01[x]) == 0 ]
if len(missing_from_d1) > 0:
  for i in missing_from_d1:
    print '[WARNING] Station %s not found in reference sta file: %s; Station will not be compared.' %(i, reference_sta)
    del ref_dict_01[i]
    if i in loc_dict_01:
      del loc_dict_01[i]

## Note! All stations in ref_dict_01 must exist in ref_dict_02 even empty
for i in ref_dict_01:
  if not i in loc_dict_01:
    loc_dict_01[i] = []

## read Type002 info (as dictionary) from both .STA files
ref_dict_02 = refsta.__match_type_002__(ref_dict_01, no_marker_numbers)
loc_dict_02 = locsta.__match_type_002__(loc_dict_01, no_marker_numbers)

## do the comparisson; first match Type 001 records
for key1, val1 in ref_dict_01.iteritems():
  val2 = loc_dict_01[key1]
  __val1 = val1
  __val2 = val2
  if len(__val2) > len(__val1):
    __val1, __val2 = __val2, __val1
  for rc1 in __val1:
    if not any(bernutils.bsta.loose_compare_type1(rc1, rc2, no_marker_numbers) for rc2 in __val2):
      stations_diff.append(key1)
      print_incosistency(1, key1, val1, reference_sta, val2, local_sta)
      EXIT_STATUS = 3
      break

## do the comparisson; first match Type 002 records
for key1, val1 in ref_dict_02.iteritems():
  val2 = loc_dict_02[key1]
  __val1 = val1
  __val2 = val2
  if len(__val2) > len(__val1):
    __val1, __val2 = __val2, __val1
  for rc1 in __val1:
    if not any(bernutils.bsta.loose_compare_type2(rc1, rc2, no_marker_numbers) for rc2 in __val2):
      print_incosistency(2, key1, val1, reference_sta, val2, local_sta)
      EXIT_STATUS = 3
      break

## all done; exit
sys.exit(EXIT_STATUS)
