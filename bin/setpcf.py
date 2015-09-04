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

import os
import sys
import getopt

class PcfFile:
  """ Class to represent a Bernese 5.2 PCF file (extension .PCF)
  """
    
  def __init__(self,filename):
  """ Constructor; set the name, open the file and mark the start
      of the variables section.
  """
    self.name_   = filename
    try:
        fbuf = open(self.name_, 'r+')
    except:
        raise IOError('ERROR. Could not open PCF file: '+filename)
    for line in fbuf:
        "VARIABLE DESCRIPTION                              DEFAULT"

## help function
def help (i):
  print ""
  print ""
  sys.exit(i)
