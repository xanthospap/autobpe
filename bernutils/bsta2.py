import os
import sys
import re
import fnmatch
import datetime

MIN_STA_DATE = datetime.datetime.min
MAX_STA_DATE = datetime.datetime.max

class Type001:
  ''' A class to hold type 001 station information records for a single station.
  '''
  def __init__(self, line):
    ''' Initialize a :py:class:`bernutils.bsta.type001` instance using a type 001
        information line. This will set the start and stop date and the 
        station name.
        
        An example of a .STA file type 001 info line follows::
        
          STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK
          ****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************
          AIRA 21742S001        001  1980 01 06 00 00 00  2099 12 31 00 00 00  AIRA*                 MGEX,aira_20120821.log
          ISBA 20308M001        003                                            ISBA                  EXTRA RENAMING

    '''
    self.__sta_name   = line[0:16].rstrip()
    self.__flag       = line[22:25].rstrip()
    self.__old_name   = line[69:89].rstrip()
    self.__remark     = line[91:].rstrip()

    ## resolve the start date (or set to min if empty)
    t_str = line[27:46].strip()
    if len(t_str) == 0:
      self.__start_date = MIN_STA_DATE
    else:
      try:
        self.__start_date = datetime.datetime.strptime(t_str.strip(), '%Y %m %d %H %M %S')
      except:
        raise RuntimeError('Invalid date format at line [%s]' %line.strip())
    
    ## resolve stop date (or set to now)
    t_str = line[48:67].strip()
    if len(t_str) == 0:
      self.__stop_date = MAX_STA_DATE ##datetime.datetime.now()
    else:
      try:
        self.__stop_date = datetime.datetime.strptime(t_str.strip(), '%Y %m %d %H %M %S')
      except:
        raise RuntimeError('Invalid date format at line [%s]' %line.strip())

  def flag(self):
    ''' Return the flag as integer; in case it is missing, return -1
    '''
    try: return int(self.__flag)
    except: return -1

  def __issue_renaming__warning__(self, station):
    ''' Issue a warning (to stderr) of a station renaming
    '''
    t1 = 'start of operation'
    if self.__start_date != MIN_STA_DATE:
      t1 = self.__start_date.strftime('%Y-%m-%d')
    
    t2 = 'today'
    if self.__stop_date != MAX_STA_DATE:
      t2 = self.__stop_date.strftime('%Y-%m-%d')

    sys.stderr.write('[WARNING] station %s seems to be renamed to %s, from  %s to %s'
      %(station, self.__sta_name, t1, t2))

  def start(self):
    ''' Return the start datetime (as ``datetime``). '''
    return self.__start_date

  def stop(self):
    ''' Return the stop datetime (as ``datetime``). '''
    return self.__stop_date

  def station_name(self):
    ''' Return the 'STATION NAME' column. '''
    return self.__sta_name

  def old_staname(self):
    ''' Return the 'OLD STATION NAME' column. '''
    return self.__old_name

class Type002:
  ''' A class to hold type 002 station information records for a single station.
  '''

  def __init__(self, line):
    ''' Initialize a :py:class:`bernutils.bsta.type002` instance using a type 002
        information line. This will set the start and stop date and the 
        station name.
        
        An example of a .STA file type 002 info line follows::
        
          STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK
          ****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************
          AFKB                  001                                            LEICA GRX1200GGPRO                          999999  LEIAT504GG      LEIS                        999999    0.0000    0.0000    0.0000  Kabul, AF               NEW
          AZGB 49541S001        001                       2004 07 20 23 59 59  TRIMBLE 4000SSE                             999999  TRM22020.00+GP  NONE                        999999    0.0000    0.0000    0.0000  Globe, US               NEW
          AZGB 49541S001        001  2004 07 21 00 00 00  2004 08 26 23 59 59  TRIMBLE 4700                                999999  TRM33429.00+GP  NONE                        999999    0.0000    0.0000    0.0000  Globe, US               NEW

    '''
    self.__sta_name    = line[0:16].rstrip()
    self.__flag        = line[22:25].rstrip()
    self.__receiver_t  = line[69:89].rstrip()
    self.__receiver_sn = line[91:111].rstrip()
    self.__receiver_nr = line[113:119].rstrip()
    self.__antenna_t   = line[121:141].rstrip()
    self.__antenna_sn  = line[143:163].rstrip()
    self.__antenna_nr  = line[165:171].rstrip()
    self.__north       = line[173:181].rstrip()
    self.__east        = line[183:191].rstrip()
    self.__up          = line[193:201].rstrip()
    self.__description = line[203:225].rstrip()
    self.__remark      = line[227:].rstrip()

    ## resolve the start date (or set to min if empty)
    t_str = line[27:46].strip()
    if len(t_str) == 0:
      self.__start_date = MIN_STA_DATE
    else:
      try:
        self.__start_date = datetime.datetime.strptime(t_str.strip(), '%Y %m %d %H %M %S')
      except:
        raise RuntimeError('Invalid date format at line [%s]' %line.strip())
    
    ## resolve stop date (or set to now)
    t_str = line[48:67].strip()
    if len(t_str) == 0:
      self.__start_date = datetime.datetime.now()
    else:
      try:
        self.__stop_date = datetime.datetime.strptime(t_str.strip(), '%Y %m %d %H %M %S')
      except:
        raise RuntimeError('Invalid date format at line [%s]' %line.strip())

class StaFile:
  ''' A class to represent a Bernese-format station information file (.STA)
  '''

  def __init__(self, filen):
    ''' Initialize a StaFile instance; set the filename, try to open the file
        and then search and mark all places (in the file) where a type starts
    '''
    if not os.path.isfile(filen):
      raise RuntimeError('Cannot find .STA file [%s]' %filen)
    fin = open(filen, 'r')
      
    ## search for the places in the file, where 'TYPE XXX' starts
    self.__type_pos = {}
    line = fin.readline()
    rgx  = re.compile("^TYPE 00[1-9]:")
    while line:
      if rgx.match(line):
        self.__type_pos[int(line[7])] = fin.tell()
      line = fin.readline()
    
    ## add a dummy mark at the end of the dictionary
    self.__type_pos[max(self.__type_pos.keys())+1] = fin.tell()

    ## return at the top
    fin.seek(0)

    ## we must at least have read the type 001 and type 002 lies
    if 1 not in self.__type_pos or 2 not in self.__type_pos:
      fin.close()
      raise RuntimeError('Invalid sta file. Type001 and/or Type002 not found')
      
    ## assign the filename
    self.__filename = filen
    self.__stream   = fin

  def __type_range__(self, int_type):
    ''' Return the range (i.e. the places in the file) where a specific type
        starts and ends.
    '''
    return [self.__type_pos[int_type], self.__type_pos[int_type+1]]

  def match_old_name(self, station):
    ''' given a station name, '''

    ## get the range in file to search for
    from_p, to_p = self.__type_range__(1)

    ## go to the begining of the file
    self.__stream.seek(from_p)
    
    ## there should be an extra 4 lines ...
    for i in range(0, 4): line = self.__stream.readline()

    ##  match the old_station_name in each line with the name given, using UNIX
    ##+ shell-style wildcards.
    line = self.__stream.readline()
    while line and  self.__stream.tell() < to_p:
      t1 = Type001(line)
      if fnmatch.fnmatch(station, t1.old_staname()):
        print 'found matching station [%s]' %line.strip()
        if t1.flag() == 3: t1.__issue_renaming__warning__(station)
        else: print 'flag was %02i' %t1.flag()
      line = self.__stream.readline()