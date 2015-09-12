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

  def __str_format__(self):
    ''' Format the instance as a valid Type 001 record
    '''
    t_start = '                   '
    t_stop  = '                   '
    if self.__start_date != MIN_STA_DATE:
      t_start = self.__stop_date.strftime('%Y %m %d %H %M %S')
    if self.__stop_date != MAX_STA_DATE:
      t_stop = self.__start_date.strftime('%Y %m %d %H %M %S')
    return '%-16s      %3s  %19s  %19s  %-20s  %-25s' \
      %(self.__sta_name, self.__flag, t_start, t_stop, self.__old_name, self.__remark)

  def __repr__(self):
    return self.__str_format__()

  def __str__(self):
    return self.__str_format__()

  def __issue_renaming__warning__(self, station):
    ''' Issue a warning (to stderr) of a station renaming
    '''
    t1 = 'start of operation'
    if self.__start_date != MIN_STA_DATE:
      t1 = self.__start_date.strftime('%Y-%m-%d')
    
    t2 = 'today'
    if self.__stop_date != MAX_STA_DATE:
      t2 = self.__stop_date.strftime('%Y-%m-%d')

    sys.stderr.write('[WARNING] station %s seems to be renamed to %s, from  %s to %s\n'
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

  def flag(self):
    ''' Return the flag as integer; in case it is missing, return -1
    '''
    try: return int(self.__flag)
    except: return -1

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
    # print 'NEU from [%s] [%s] [%s]' %(line[173:181], line[183:191], line[193:201])
    self.__north       = float(line[173:181].rstrip())
    self.__east        = float(line[183:191].rstrip())
    self.__up          = float(line[193:201].rstrip())
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
      self.__stop_date = MAX_STA_DATE
    else:
      try:
        self.__stop_date = datetime.datetime.strptime(t_str.strip(), '%Y %m %d %H %M %S')
      except:
        raise RuntimeError('Invalid date format at line [%s]' %line.strip())

  def __str_format__(self):
    ''' Format the instance as a valid Type 002 record
    '''
    t_start = '                   '
    t_stop  = '                   '
    if self.__start_date != MIN_STA_DATE:
      t_start = self.__start_date.strftime('%Y %m %d %H %M %S')
    if self.__stop_date != MAX_STA_DATE:
      t_stop = self.__stop_date.strftime('%Y %m %d %H %M %S')
    return '%-16s      %3s  %19s  %19s  %-20s  %-20s  %-6s  %-20s  %-20s  %-6s  %8.4f  %8.4f  %8.4f  %-22s  %-25s' \
      %(self.__sta_name, self.__flag, t_start, t_stop, self.__receiver_t, self.__receiver_sn, \
        self.__receiver_nr, self.__antenna_t, self.__antenna_sn, self.__antenna_nr, \
        self.__north, self.__east, self.__up, self.__description, self.__remark)

  def __repr__(self):
    return self.__str_format__()

  def __str__(self):
    return self.__str_format__()

  def __match_t1__(self, t1):
    ''' Check if (this) Type 002 entry matches a Type 001 entry. Will check the
        following:
        
        * self.__sta_name   =  t1.station_name
        * self.__start_date >= t1.start
        * self.__stop_date  <= t1.stop
        
        :param t1: A ``Type001`` instance.

    '''
    return self.__sta_name == t1.station_name() \
      and (self.__start_date >= t1.start() or  self.__start_date == MIN_STA_DATE) \
      and (self.__stop_date <= t1.stop() or self.__stop_date == MAX_STA_DATE)

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
    tp1_matches = []
    line = self.__stream.readline()
    while line and  self.__stream.tell() < to_p:
      t1 = Type001(line)
      if fnmatch.fnmatch(station, t1.old_staname()):
        if t1.flag() == 3:
          t1.__issue_renaming__warning__(station)
        else:
          tp1_matches.append(t1)
          print 'type1: [%s]' %t1
      line = self.__stream.readline()

    ## we must have at least found 1 entry ..
    if len(tp1_matches) == 0:
      raise RuntimeError('Unable to match station %s' %station)

    ## now find the entries in Type 002
    from_p, to_p = self.__type_range__(2)
    self.__stream.seek(from_p)
    for i in range(0, 4): line = self.__stream.readline()
    
    ## walk through all entries of type 002 and match the type 001 lines
    tp2_matches = []
    line = self.__stream.readline()
    while line and len(line)>10 and self.__stream.tell() < to_p:
      t2 = Type002(line)
      for t1 in tp1_matches:
        if t2.__match_t1__(t1):
          tp2_matches.append(t2)
          print 'type2: [%s]' %t2
      line = self.__stream.readline()

  def match_old_name2(self, stations):
    ''' given a station name, '''

    ## we'll make some changes to station_list later on ..
    station_list = stations

    ## get the range in file to search for
    from_p, to_p = self.__type_range__(1)

    ## go to the begining of the file
    self.__stream.seek(from_p)
    
    ## there should be an extra 4 lines ...
    for i in range(0, 4): line = self.__stream.readline()

    ##  We define two dictionaries:
    ##+ 1. sta_tp1 key-> [stations name] value->[a list of Type 001 instances]
    ##+ 2. sta_tp2 key-> [stations name] value->[a list of Type 002 instances]
    sta_tp1 = {}
    sta_tp2 = {}
    for s in station_list:
      sta_tp1[s] = []
      sta_tp2[s] = []

    ##  match the old_station_name in each line with the name given, using UNIX
    ##+ shell-style wildcards.
    line = self.__stream.readline()
    while line and  self.__stream.tell() < to_p:
      t1 = Type001(line)
      for sta in station_list:
        if fnmatch.fnmatch(sta, t1.old_staname()):
          if t1.flag() == 3:
            t1.__issue_renaming__warning__(station)
          else:
            sta_tp1[sta].append(t1)
          break
      line = self.__stream.readline()

    ## we must have at least found 1 entry ..
    at_least_one_found = False
    not_found_list     = []
    for sta in station_list:
      if len(sta_tp1[sta]) == 0:
        sys.stderr.write('[WARNING] Unable to match station %s\n' %sta)
        not_found_list.append(sta)
      else:
        at_least_one_found = True
    if not at_least_one_found:
      raise RuntimeError('Unable to match any station')
    
    ## remove any stations not found in type 001 from dictionaries & station_list
    for sta in not_found_list:
      del sta_tp1[sta]
      del sta_tp2[sta]
      station_list.remove(sta)

    ## now find the entries in Type 002
    from_p, to_p = self.__type_range__(2)
    self.__stream.seek(from_p)
    for i in range(0, 4): line = self.__stream.readline()
    
    ## walk through all entries of type 002 and match the type 001 lines
    line = self.__stream.readline()
    while line and len(line)>10 and self.__stream.tell() < to_p:
      t2 = Type002(line)
      for sta in station_list:
        for t1 in sta_tp1[sta]:
          if t2.__match_t1__(t1):
            print 'type2: [%s]' %t2
            sta_tp2[sta].append(t2)
      line = self.__stream.readline()