import os, sys, re
import fnmatch
import datetime

__DEBUG_MODE__ = False

def _resolve_str_datetime_(strdt):
    ''' Resolve a datetime in the format "YYYY MM DD HH MM SS" to a Python
        datetime.datetime instance. The string passed as argument should follow
        the format: '%Y %m %d %H %M %S'. If it doesn't an exception will be
        thrown, except in the case when the input string is just empty of
        only consists of (white)spaces. In this last case, None is returned.
    '''
    dt_str = strdt.strip()
    if not len(dt_str): return None
    try:
        return datetime.datetime.strptime(dt_str, '%Y %m %d %H %M %S')
    except:
        raise RuntimeError( 'Invalid date format: [%s]' %strdt.strip() )

class StaRecord_001:
    ''' A class to hold type 001 station information records for a single station.
      An example of a .STA file type 001 info line follows::

          STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK
          ****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************
          AIRA 21742S001        001  1980 01 06 00 00 00  2099 12 31 00 00 00  AIRA*                 MGEX,aira_20120821.log
          ISBA 20308M001        003                                            ISBA                  EXTRA RENAMING
    '''

    def __init__(self, sta_line=None, station_name=None, flag=None, old_station_name=None, remark=None, start=None, stop=None):
        ''' Initialize a StaRecord_001 instance using a type 001 information line
            and/or individual information.
            :param sta_line: A Type 001 record line. If this parameter is None, then
            at least the parameter station_name should be set. If
            not None, then this line must follow the format of
            Type 001 lines. All required fields are extracted from
            this line.
            :param station_name: The station name. If the parameter sta_line is
            provided, then this is not requiered; if both
            sta_line and station_name are provided, then the
            station name will be set to the station_name
            parameter.
        '''
        ## at least a whole line or a station name must be provided.
        if sta_line is None and station_name is None:
            raise RuntimeError('Invalid initialization of \'Type 001\' record.')

        ## A Type 001 line provided; assign all fields.
        if sta_line is not None:
            self.__sta_name   = sta_line[0:16].rstrip()
            self.__flag       = sta_line[22:25].rstrip()
            self.__old_name   = sta_line[69:89].rstrip()
            self.__remark     = sta_line[91:].rstrip()
            start_dt = _resolve_str_datetime_(sta_line[27:46])
            self.__start = start_dt if start_dt is not None else datetime.datetime.min
            stop_dt  = _resolve_str_datetime_(sta_line[48:67])
            self.__stop  = stop_dt if stop_dt is not None else datetime.datetime.max
        ## A Type 001 line is **not** provided; default initialize all fields.
        else:
            self.__flag = 3*' '
            self.__old_name = station_name
            self.__remark = ''
            self.__start = datetime.datetime.min
            self.__stop = datetime.datetime.max

        ## If any individual field is provided, then assign it
        if station_name is not None:
            self.__sta_name = station_name
        if flag is not None:
            self.__flag = flag
        if old_station_name is not None:
            self.__old_name = old_station_name
        if remark is not None:
            self.__remark = remark
        if start is not None:
            self.__start = start
        if stop is not None:
            self.__stop = stop
  
    def __str_format__(self):
        ''' Format the instance as a valid Type 001 record
        '''
        t_start = self.__start.strftime('%Y %m %d %H %M %S') if self.__start is not datetime.datetime.min else 20*' '
        t_stop  = self.__stop.strftime('%Y %m %d %H %M %S') if self.__stop is not datetime.datetime.max else 20*' '
        return '%-16s      %3s  %20s %20s %-20s  %-25s' \
            %(self.__sta_name, self.__flag, t_start, t_stop, self.__old_name, self.__remark)

    def __repr__(self):
        return self.__str_format__()

    def __str__(self):
        return self.__str_format__()

    def __issue_renaming__warning__(self, station):
        ''' Issue a warning (to stderr) of a station renaming
        '''
        t1 = 'start of operation'
        if self.__start_date != datetime.datetime.min:
            t1 = self.__start_date.strftime('%Y-%m-%d')

        t2 = 'today'
        if self.__stop_date != datetime.datetime.max:
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
        ''' Return the flag
        '''
        return self.__flag

class StaRecord_002:
    ''' A class to hold type 002 station information records for a single station.
      An example of a .STA file type 002 info line follows::

          STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK
          ****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************
          AFKB                  001                                            LEICA GRX1200GGPRO                          999999  LEIAT504GG      LEIS                        999999    0.0000    0.0000    0.0000  Kabul, AF               NEW
          AZGB 49541S001        001                       2004 07 20 23 59 59  TRIMBLE 4000SSE                             999999  TRM22020.00+GP  NONE                        999999    0.0000    0.0000    0.0000  Globe, US               NEW
          AZGB 49541S001        001  2004 07 21 00 00 00  2004 08 26 23 59 59  TRIMBLE 4700                                999999  TRM33429.00+GP  NONE                        999999    0.0000    0.0000    0.0000  Globe, US               NEW

    '''

    def __init__(self, sta_line=None, station_name=None, flag=None,
            receiver_type=None, receiver_serial=None, receiver_number=None,
            antenna_type=None, antenna_serial=None, antenna_number=None,
            dnorth=None, deast=None, dup=None, description=None, remark=None,
            start=None, stop=None):
        ''' Initialize a :py:class:`bernutils.bsta.type002` instance using a type 002
            information line. This will set the start and stop date and the 
            station name.

        '''
        ## at least a whole line or a station name must be provided.
        if sta_line is None and station_name is None:
            raise RuntimeError('Invalid initialization of \'Type 002\' record.')
        
        self.__dict = {}

        if sta_line is not None:
            self.__dict['sta_name']    = sta_line[0:16].rstrip()
            self.__dict['flag']        = sta_line[22:25].rstrip()
            self.__dict['receiver_t']  = sta_line[69:89].rstrip()
            self.__dict['receiver_sn'] = sta_line[91:111].rstrip()
            self.__dict['receiver_nr'] = sta_line[113:119].rstrip()
            self.__dict['antenna_t']   = sta_line[121:141].rstrip()
            self.__dict['antenna_sn']  = sta_line[143:163].rstrip()
            self.__dict['antenna_nr']  = sta_line[165:171].rstrip()
            self.__dict['north']       = float(sta_line[173:181].rstrip())
            self.__dict['east']        = float(sta_line[183:191].rstrip())
            self.__dict['up']          = float(sta_line[193:201].rstrip())
            self.__dict['description'] = sta_line[203:225].rstrip()
            self.__dict['remark']      = sta_line[227:].rstrip()
            tmp_date = _resolve_str_datetime_(sta_line[27:46])
            self.__dict['start']     = datetime.datetime.min if tmp_date is None else tmp_date
            tmp_date = _resolve_str_datetime_(sta_line[48:67])
            self.__dict['stop']     = datetime.datetime.max if tmp_date is None else tmp_date
        else:
            self.__dict['sta_name']    = station_name if station_name is not None else ''
            self.__dict['flag']        = flag if flag is not None else ''
            self.__dict['receiver_t']  = receiver_type if receiver_type is not None else ''
            self.__dict['receiver_sn'] = receiver_serial if receiver_serial is not None else ''
            self.__dict['receiver_nr'] = receiver_number if receiver_number is not None else ''
            self.__dict['antenna_t']   = antenna_type if antenna_type is not None else ''
            self.__dict['antenna_sn']  = antenna_serial if antenna_serial is not None else ''
            self.__dict['antenna_nr']  = antenna_number if antenna_number is not None else ''
            self.__dict['north']       = float(dnorth) if dnorth is not None else ''
            self.__dict['east']        = float(deast) if deast is not None else .0e0
            self.__dict['up']          = float(dup) if dup is not None else .0e0
            self.__dict['description'] = description if description is not None else ''
            self.__dict['remark']      = remark if remark is not None else ''
            self.__dict['start']       = datetime.datetime.min if start is None else start
            self.__dict['stop']        = datetime.datetime.max if stop is None else stop

    def __str_format__(self):
        ''' Format the instance as a valid Type 002 record
        '''
        t_start = ' '
        t_stop  = ' '
        if self.__dict['start'] != datetime.datetime.min:
            t_start = self.__dict['start'].strftime('%Y %m %d %H %M %S')
        if self.__dict['stop'] != datetime.datetime.max:
            t_stop = self.__dict['stop'].strftime('%Y %m %d %H %M %S')
        return '{0:<16s}      {1:>3s}  {2:<19s}  {3:<19s}  {4:<20s}  {5:<20s}  {6:<6s}  {7:<20s}  {8:<20s}  {9:<6s}  {10:8.4f}  {11:8.4f}  {12:8.4f}  {13:<22s}  {14:<25s}' \
      .format(self.__dict['sta_name'], self.__dict['flag'], t_start, t_stop, \
        self.__dict['receiver_t'], self.__dict['receiver_sn'], self.__dict['receiver_nr'], \
        self.__dict['antenna_t'], self.__dict['antenna_sn'], self.__dict['antenna_nr'], \
        self.__dict['north'], self.__dict['east'], self.__dict['up'], \
        self.__dict['description'], self.__dict['remark'])

    def __repr__(self):
        return self.__str_format__()

    def __str__(self):
        return self.__str_format__()

    def station_name(self):
        return self.__dict['sta_name']

class BernSta:
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
        while line and self.__stream.tell() < end_of_block:
            t1 = StaRecord_001(line)
            if t1.flag() == "003":
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
        while line and self.__stream.tell() < to_p:
            t1 = StaRecord_001(line)
            for sta in stations:
                if fnmatch.fnmatch(sta, t1.old_staname()):
                    if t1.flag() == '003':
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

            :param no_marker_number: If set to true, then the comparisson for name
              equality is performed using only the first 4 chars of the station name
              (i.e. the station id).

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

        sta_tp1 = dictnr
        ## walk through all entries of type 002
        line = self.__stream.readline()
        while line and len(line)>10 and self.__stream.tell() < to_p:
            try:
                t2 = StaRecord_002(line)
                if t2.station_name() in sta_tp1:
                    if t2.station_name() in sta_tp2:
                        sta_tp2[t2.station_name()].append(t2)
                    else:
                        sta_tp2[t2.station_name()] = [t2]
            except:
                print >> sys.stderr, '[WARNING] Type 002 Line seems invalid:'
                print >> sys.stderr, '          ['+line.rstrip()+']'
            line = self.__stream.readline()

        return sta_tp2
