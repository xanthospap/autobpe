#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : 
version               : v-0.5
created               : SEP-2015

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

import os
import sys
import getopt
import bernutils.badnq

## ------------ DEBUGING FLAGS
DDEBUG = True
import traceback

## Global variables
adnq_filen    = None
table_entries = 'latcor,loncor,hgtcor,dn,de,du'
warnings_msg  = None

## help function
def help (i):
  print ""
  print ""
  sys.exit(i)

## Resolve command line arguments
def main(argv):

  if len(argv) < 1:
    help(1)

  try:
    opts, args = getopt.getopt(argv,'hf:t:w:',['help','addneq-file=','table-entries=','warnings-str='])
  except getopt.GetoptError:
    help(1)

  for opt, arg in opts:
    if opt in ('-h', 'help'):
      help(0)
    elif opt in ('-f', '--addneq-file'):
      global adnq_filen
      adnq_filen = arg
    elif opt in ('-t', '--table-entries'):
      global table_entries
      table_entries = arg
    elif opt in ('-w', '--warnings-str'):
      global warnings_msg
      warnings_msg = arg
    else:
      print >> sys.stderr, 'Invalid command line argument: %s' %opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

if not adnq_filen:
  print >>sys.stderr, 'Must specify at least an input file!'
  sys.exit(1)
if not os.path.isfile(adnq_filen):
  print >>sys.stderr, 'Cannot find input file %s' %adnq_filen
  sys.exit(1)

try:

  ## create an AddnqFile instance
  adnq = bernutils.badnq.AddneqFile(adnq_filen)

  ## get and write a-priori info
  print '<p>Addneq Filename: %s</p>' %adnq.filename()
  print '<p>Campaign       : %s</p>' %adnq.campaign()
  print '<p>Date           : %s, Session: %s</p>' %(adnq.date(), adnq.session())
  print '<p>Run at: %s, by: %s</p>' %(adnq.run_at(), adnq.run_by())
  inf = adnq.apriori_info()
  print '<p>A-Priori Sigma of Unit Weight: %.4f</p>' %inf[0]
  print '<p>Reference Frame              : %s</p>' %inf[1]
  print '<p>Network Constraints          :</p>'
  print '<ul style="list-style-type:none">'
  for i in inf[2]: print '<li>%s -> %s (%s)</li>' %(i[0], i[1], i[2])
  print '</ul>'

  ## write the table & warnings
  adnq.toHtml(table_entries, warnings_msg)

except Exception, e:
  print >>sys.stderr, str(e)
  print >>sys.stderr,'Error in ADDNEQ to Html translation! Giving up.'
  if DDEBUG == True: traceback.print_exc(file=sys.stderr)
  sys.exit(1)
