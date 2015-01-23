#!/usr/bin/python

""" @package bsltranslate

  @brief Translate baseline names
  
  @details this routines reads baselines (station pairs)
           from a given bsl file, and translates it, according
           to a given abbreviation file. For example, the .ABB file
           may contain :
           
           Station name             4-ID    2-ID    Remark                                 
           ****************         ****     **     ***************************************
           ANKR XXXXXXXXXX          ANKR     AN
           DYNG XXXXXXXXXX          DYNG     DY
           
           The .BSL file may contain:
           ANKR XXXXXXXXX   DYNG XXXXXXXXXX
           
           

  Created         : Sep 2014
  Last Update     : Dec 2014

  List of Changes :

  National Technical University of Athens
  Dionysos Satellite Observatory
  Higher Geodesy Laboratory
"""

""" Import Libraries
"""
import sys
import os
import re

""" HELP FUNCTION
"""
def help():
  print "/******************************************************************************************/"
  print " Program Name : bsltranslate.py"
  print " Version : v-1.0"
  print " Purpose : translate baseline names to station pairs"
  print " Usage   : bsltranslate <bsl_file> <abb_file> [<output_file>]"
  print "           Note that the given output file will be overwritten"
  print " Exit Status: 0 := sucess"
  print " Exit Status: 1 := failure"
  print " Returns : nothing"
  print "/******************************************************************************************/"
  sys.exit(1)

""" CHECK COMMAND LINE ARGUMENTS; BSL AND ABB FILES MUST BE GIVEN
"""
if (len(sys.argv)==1):
  help()
  
if (len(sys.argv)<3):
  print "***ERROR! incorect number of command line arguments"
  print "usage: bsltranslate <bsl_file> <abb_file> [<output_file> <--translate>]"
  sys.exit(1)

if (not os.path.isfile(sys.argv[1])):
  print "***ERROR! file ", sys.argv[1], "does not exist!"
  sys.exit(1)

if (not os.path.isfile(sys.argv[2])):
  print "***ERROR! file ", sys.argv[2], "does not exist!"
  sys.exit(1)

""" EMPTY LISTS TO STORE 2,4 STATION AND BSELINE NAMES
"""
_4digit_station_list=[]
_2digit_station_list=[]
_4digit_baseline_list=[]
_2digit_baseline_list=[]


""" READ IN ABB FILE AND ASSIGN 2 AND 4-DIGIT STATION NAMES
    example .ABB file:
    
    PPP_022360                                                       22-NOV-10 16:32
    --------------------------------------------------------------------------------

    Station name             4-ID    2-ID    Remark                                 
    ****************         ****     **     ***************************************
    AUT1 12619M002           AUT1     AU     Added by SR updabb                     
    COST 11407M001           COST     CO     Added by SR updabb                     
    DUB2 11901M002           DUB2     DU     Added by SR updabb                     
    DUTH 12621M001           DUTH     DT     Added by SR updabb                     
    LAMP 12706M002           LAMP     LA     Added by SR updabb      
    AKYR                     AKYR     AK     Added by SR updabb                     
"""
inf = open (sys.argv[2], 'r')

for i in range(0, 5):
  inf.readline()

line=inf.readline()
while (True):
  try:
    _4digit_station_list.append(line[25:29])
    _2digit_station_list.append(line[34:36])
  except:
    break
  line=inf.readline()
  if len(line) < 5: break;

inf.close()

if len (_4digit_station_list) == 0:
  print 'No station found in the .ABB file:',sys.argv[2]
  sys.exit (1)
  
if len (_4digit_station_list) != len (_2digit_station_list):
  print 'Error reading .ABB file',sys.argv[2],'; list elements do not match'
  sys.exit (1)

""" READ IN BSL FILE AND ASSIGN 2 AND 4-DIGIT BASELINE NAMES
    example .BSL file:
    PAT0             PATR            
    LARI             LARM            
    DUTH             XANT            
    AUT1             THES            
    AUT1 12619M002   LARM 12610M002  
    DUB2 11901M002   SRJV 11801S001  
    LARM 12610M002   PAT0 12622M001  

"""
inf= open (sys.argv[1], 'r')

line=inf.readline()
while (True):
  try:
    sta1 = line[0:4]
    sta2 = line[17:21]
    _4digit_baseline_list.append(sta1+"-"+sta2)                   ## e.g. 'AUT1-LARM'
    try: 
      str1=_2digit_station_list[_4digit_station_list.index(sta1)] ## e.g. 'AU'
    except:
      print 'Error! Cannot match baseline',line
      inf.close();
      sys.exit(1)
    try:
      str2=_2digit_station_list[_4digit_station_list.index(sta2)] ## e.g. 'LA'
    except:
      print 'Error! Cannot match baseline',line
      inf.close()
      sys.exit(1)
    _2digit_baseline_list.append(str1+str2)                       ## e.g. 'AULA' 
  except:
    break
  line = inf.readline ()
  if len(line) < 5 : break;

inf.close()

if len (_4digit_baseline_list) == 0:
  print 'No baselines found in the .BSL file:',sys.argv[1]
  sys.exit (1)
  
if len (_4digit_baseline_list) != len (_2digit_baseline_list):
  print 'Error reading .BSL file',sys.argv[1],'; list elements do not match'
  sys.exit (1)

""" READ IN FILE AND TRANSLATE
"""
if (len(sys.argv)==4):
  iterator=0
  try:
    fin=open(sys.argv[3], 'r')
    ## ouf=open(sys.argv[3]+".scratch", 'w')
    while (True):
      iterator+=1
      if (iterator>10000):
        print "possibly corrupted summary file!"
        print "no EOF found"
        sys.exit(1);
      line=fin.readline()
      l=line.split()
      try:
        if l[0]=="EOF": break;
      except: pass
      if len(l)>5:
        for i in range (0, len(l)):
          try:
            index=_2digit_baseline_list.index(l[i].strip())
            new_str=_4digit_baseline_list[index]
            line.replace(l[i], new_str)
          except:
            pass
          """
            try:
              index=_2digit_baseline_list.index(l[i][0:4])
              new_str=_4digit_baseline_list[index]
              line=line.replace(l[i], new_str)
            except:
              pass
          """
      print line,
  except:
    print "***ERROR! error while trying to replace ..."
    inf.close()
    sys.exit(1)
    
  inf.close()
  ## os.remove(sys.argv[3])
  ## os.rename(sys.argv[3]+".scratch", sys.argv[3])
else:
  for i in range(0, len(_2digit_baseline_list)):
    print _4digit_baseline_list[i],"->",  _2digit_baseline_list[i]
    
sys.exit(0)
