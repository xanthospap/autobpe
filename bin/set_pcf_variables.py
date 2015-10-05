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
import sys, os, traceback
import bernutils.bpcf

## Debug Mode
DDEBUG_MODE = True

## flush to html
HTML_OUT = False
JSON_OUT = True

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

def main(argv):

  PCF_FILE = argv[0]
  if not os.path.isfile(PCF_FILE):
    print >>sys.stderr, "ERROR. Invalid pcf file: %s"%PCF_FILE
    sys.exit(1)

  var_dict= {}
  for arg in argv[1:]:
    vr, vl = arg.split('=')
    var_dict[vr] = vl

  pcf = bernutils.bpcf.PcfFile(PCF_FILE)

  for vr, vl in var_dict.iteritems():
    pcf.set_variable(vr, val=vl)
    ## print "Setting PCF variable [%s] to [%s]"%(vr, vl)

  pcf.flush_variables()

  if HTML_OUT: pcf.dump_to_html()
  if JSON_OUT: pcf.dump_to_json()

## Start main
if __name__ == "__main__":

  if len(sys.argv) < 1:
    print "ERROR. Need to provide a valid pcf filename."
    sys.exit(1)
  elif len(sys.argv) < 1:
    print "WARNING: Nothing to do; no pcf variables specified!"
    sys.exit(0)

  try:
    main( sys.argv[1:] )
  except:
    print "ERROR. Cannot set variables in pcf file."
    ## log exception/stack call
    print >>sys.stderr,'*** Stack Rewind:'
    exc_type, exc_value, exc_traceback = sys.exc_info()
    traceback.print_exception(exc_type, exc_value, exc_traceback, \
          limit=10, file=sys.stderr)
    print >>sys.stderr,'*** End'
    sys.exit(1)

  sys.exit(0)
