import os
import sys
import re
import fnmatch
import datetime

__DEBUG_MODE__ = False

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
      t_start = self.__start_date.strftime('%Y %m %d %H %M %S')
    if self.__stop_date != MAX_STA_DATE:
      t_stop = self.__stop_date.strftime('%Y %m %d %H %M %S')
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

  def station_name(self):
    return self.__sta_name
  def flag(self):
    return self.__flag
  def receiver_type(self):
    return self.__receiver_t
  def receiver_serial_nr(self):
    return self.__receiver_sn
  def receiver_nr(self):
    return self.__receiver_nr
  def antenna_type(self):
    return self.__antenna_t
  def antenna_serial_nr(self):
    return self.__antenna_sn
  def antenna_nr(self):
    return self.__antenna_nr
  def north(self):
    return self.__north
  def east(self):
    return self.__east
  def up(self):
    return self.__up

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

  def __del__(self):
    if not self.__stream.closed:
      if __DEBUG_MODE__ == True:
        print '[DEBUG] Destructor closed the file.'
      self.__stream.close()

  def __type_range__(self, int_type):
    ''' Return the range (i.e. the places in the file) where a specific type
        starts and ends.
    '''
    return [self.__type_pos[int_type], self.__type_pos[int_type+1]]

  def __match_type_001__help__(self, end_of_block):
    ''' This is a help function, do not use as standalone! It will read the
        Type 001 block and populate a dictionary where the key is the station name
        (actually the old station name) and the vaues are lists containing
        ype001 instances.
        
        :param end_of_block: The position (i the input file) where the Type 001
                             block ends.

        :returns:        A dictionary, where the key is the station name (actually
                         the old station name) and the vaues are lists containing
                         Type001 instances. If a station has more than one Type 001
                         records, then it's value will have multiple Type001 
                         instances, all appended to the same list.

        .. warning:: The input stream/buffer must be placed at the begining of
          the block. Any empty lines will cause an exception to be thrown.

    '''
    ##  a dcitionary; the key is the stations name (**NOT** old station name) and
    ##+ the values are a list (for each station) of type001 instances.
    tp01_dic = {}

    ## read all stations ...
    line = self.__stream.readline()
    while line and  self.__stream.tell() < end_of_block:
      t1 = Type001(line)
      if t1.flag() == 3:
        t1.__issue_renaming__warning__(t1.old_staname())
      else:
        station = t1.old_staname()
        if station in tp01_dic:
          tp01_dic[station].append(t1)
        else:
          tp01_dic[station] = [t1]
      line = self.__stream.readline()

    if __DEBUG_MODE__ == True:
      print '[DEBUG] Found %5i stations in .STA file %s' %(len(tp01_dic), self.__filename)

    return tp01_dic

  def __match_type_001__(self, stations=[]):
    ''' Given a list of stations, search in Type 001 to find them, and return
        the information.
        
        .. note:: The comparisson (i.e. if a certain station in the ``stations``
          list matches a given record), is performed using the ``OLD STATION NAME``
          column, using UNIX shell-type wildcards.
        
        :param stations: A list of stations to match (if possible) in the Type 001
                         block. If an empty list is passed instead, the function
                         will return information for all stations listed in
                         the Type 001 block.

        :returns:        A dictionary, where the key is the station name (actually
                         the old station name) and the vaues are lists containing
                         Type001 instances. If a station has more than one Type 001
                         records, then it's value will have multiple Type001 
                         instances, all appended to the same list.

        .. warning:: Note that Type001 records, with a flag = '003' are not used
          to extract information. They only triger a warning message.
    '''
    ## get the range in file to search for
    from_p, to_p = self.__type_range__(1)

    ## go to the begining of the block
    self.__stream.seek(from_p)
    
    ## there should be an extra 4 lines ...
    for i in range(0, 4): line = self.__stream.readline()

    ##  if we are going to read in all stations (i.e the stations list is empty)
    ##+ let the help function do the work ...
    if len(stations) == 0:
      return self.__match_type_001__help__(to_p)
    
    ## the dictionary to be returned
    ## for each station in the list, add an entry
    sta_tp1 = {}
    for sta in stations: sta_tp1[sta] = []
    
    ## read all stations ...
    line = self.__stream.readline()
    while line and  self.__stream.tell() < to_p:
      t1 = Type001(line)
      for sta in stations:
        if fnmatch.fnmatch(sta, t1.old_staname()):
          if t1.flag() == 3:
            t1.__issue_renaming__warning__(station)
          else:
            sta_tp1[sta].append(t1)
            break
      line = self.__stream.readline()

    if __DEBUG_MODE__ == True:
      print '[DEBUG] Found %5i stations in .STA file %s' %(len(sta_tp1), self.__filename)

    return sta_tp1

  def __match_type_002__(self, dictnr):
    ''' Given a dictionay with key (old) station names and values lists of Type001
        instances, this function will search through the block Type 002 and return
        a dictionary with the same keys as the original, but with values the 
        corresponding Type 002 entries.
        
        :param dictnr: A dictionary with key (old) station names and values 
          lists of Type001 instances, e.g. like the one returned from the function
          :func:`__match_type_001__`.
        
        :returns: A dictionary with the same keys as the original, but with values
          the corresponding Type 002 entries.

    '''
    ## find the entries in Type 002
    from_p, to_p = self.__type_range__(2)
    self.__stream.seek(from_p)
    for i in range(0, 4): line = self.__stream.readline()
    
    ## the dictionary to be returned
    ## for each station in the dictionary, add an entry
    sta_tp2 = {}
    for sta in dictnr: sta_tp2[sta] = []
    
    ## walk through all entries of type 002
    line = self.__stream.readline()
    while line and len(line)>10 and self.__stream.tell() < to_p:
      t2       = Type002(line)
      archived = False
      for sta in dictnr:
        if archived: break
        for tp1 in dictnr[sta]:
          if t2.__match_t1__(tp1):
            sta_tp2[sta].append(t2)
            archived = True
            break
      line = self.__stream.readline()
      
    return sta_tp2

  def match_old_name(self, stations):
    ''' given a station name, 
    
        .. warning:: Note that Type001 records, with a flag = '003' are not used
          to extract information. They only triger a warning message.
    '''

    ## we'll make some changes to station_list later on ..
    station_list = stations

    ## get the range in file to search for
    from_p, to_p = self.__type_range__(1)

    ## go to the begining of the block
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
            #print 'type2: [%s]' %t2
            sta_tp2[sta].append(t2)
      line = self.__stream.readline()

    if __DEBUG_MODE__ == True:
      for station in station_list:
        print '================================================================='
        print '[%s]' %station
        print '-----------------------------------------------------------------'
        print '\tType 001:'
        t1_lst = sta_tp1[station]
        for t1 in t1_lst:
          print 'type 001-> [%s]' %t1
        print '-----------------------------------------------------------------'
        t2_lst = sta_tp2[station]
        for t2 in t2_lst:
          print 'type 002-> [%s]' %t2

def rearange_dictionary(dictnr):
  ''' Given a dictionary with key (old) station names and values lists of Type001
      instances (e.g. like the one returned from :func:`StaFile.__match_type_001__`,
      this function will re-arange the dictionary in the form where key is the
      station name (and **NOT** old station name) and the values are the corresponding
      lists of Type 001 instances.

      :param dictnr: A dictionary with key (old) station names and values 
        lists of Type001 instances, e.g. like the one returned from the function
        :func:`__match_type_001__`.

      :returns:  A dictionary with key station names and values lists of 
        Type001 instances for the corresponding stations.

  '''
  new_dict = {}
    
  for key, value in dictnr.iteritems():
    for t1 in value:
      station = t1.station_name()
      if station in new_dict:
        new_dict[station].append(t1)
      else:
        new_dict[station] = [t1]
  return new_dict

def loose_compare_type1(t1r, t1l):
  ''' Compare two Type 001 instances, ignoring the ``remark`` member
  '''
  return t1r.station_name() == t1l.station_name() \
    and t1r.flag() == t1l.flag() \
    and t1r.old_staname() == t1l.old_staname()

def loose_compare_type2(t2r, t2l):
  ''' Compare two Type 002 instances, ignoring the ``remark`` member
  '''
  str1 = '%s' %t2r
  str2 = '%s' %t2l
  return str1[0:50] == str2[0:50]