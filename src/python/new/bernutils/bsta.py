#! /usr/bin/python

import os
import datetime
import re

def addToRecList1(stareclst, line):
    ''' Given a list of :py:class:`starec`s, i.e. ``stareclst`` and a line
        of type TYPE 001, this function will:
        * resolve the line into a :py:class:`starec.type001` instance,
        * append the instance into the ``stareclst`` list.
        
        If a :py:class:`starec` does not exist in the list for this station,
        then a new :py:class:`starec` will be created and appended to the
        ``stareclst`` list. Else (i.e. if a :py:class:`starec` does exist 
        in the list for this station), then the new :py:class:`starec.type001` instance
        will be added to this instance.
        
    '''
    print 'resolving line -> [',line.rstrip(),']'
    try:
        type1 = starec.type001(line)
    except:
        raise
    
    #print type(stareclst), len(stareclst)

    for idx, obj in enumerate(stareclst):
        if obj.type1List()[0].old_staname() == type1.old_staname():
            try:
                obj.appendtype1(type1)
            except:
                raise
            return
    
    newrec = starec(type1.old_staname())
    newrec.appendtype1(type1)
    stareclst.append(newrec)

class starec:
    ''' A class to hold station information records for a single station.
    '''

    min_date = datetime.datetime(1900,01,01) 
    ''' Minimum date (i.e. for records that do not have one)
    '''

    def __init__(self,name):
        self.__name = name     #: name as in 'OLD NAME' column
        self.__type1_recs = [] #: list of type 001 info (i.e. :py:class:`starec.type001`)
        self.__type2_recs = [] #: list of type 002 info (i.e. :py:class:`starec.type002`)

    def appendtype1(self,typ1,enable_debug=True):
        ''' Add a :py:class:`starec.type001` record; the new element is added
            in ascending chronological order.
        '''
        ## keep this list sorted !!
        if len(self.__type1_recs) == 0:
            self.__type1_recs.append(typ1)
            return
        else:
            if typ1.stop() <= self.__type1_recs[0].start():
                self.__type1_recs.insert(0,typ1)
                return
            else:
                for idx, obj in enumerate(self.__type1_recs[:-1]):
                    if typ1.start() >= obj.stop() and typ1.stop() <= self.__type1_recs[idx+1].start():
                        self.__type1_recs.insert(idx,typ1)
                        return
                if typ1.start() >= self.__type1_recs[len(self.__type1_recs)-1].stop():
                    self.__type1_recs.append(typ1)
                    return
        # should have never reached this point ...
        if enable_debug == True:
            print 'Debuging Message for appendtype1()'
            print '------------------------------------------------------------------------'
            print 'got record line -> ['+typ1.line()+']'
            print 'this record contains:'
            for i in self.__type1_recs:
                print '\t -> ['+i.line()+']'
        raise RuntimeError('Duplicate or erroneous record -> '+typ1.line())

    def appendtype2(self,typ2):
        ''' Add a :py:class:`starec.type002` record; the new element is added
            in ascending chronological order.
        '''
        ## keep this list sorted !!
        if len(self.__type2_recs) == 0:
            self.__type2_recs.append(typ2)
            return
        else:
            if typ2.stop() <= self.__type2_recs[0].start():
                self.__type2_recs.insert(0,typ2)
                return
            else:
                for idx, obj in enumerate(self.__type2_recs[:-1]):
                    if typ.start() >= obj.stop() and typ.stop() <= self.__type2_recs[idx+1].start():
                        self.__type2_recs.insert(idx,typ2)
                        return
                if typ2.start() >= self.__type2_recs[len(self.__type2_recs)-1].stop():
                    self.__type2_recs.append(typ2)
                    return
        # should have never reached this point ...
        raise RuntimeError('Duplicate or erroneous record')

    def type1List(self):
        ''' Return the list of type 001 information (i.e. the list of 
            :py:class:`starec.type001` instances).
        '''
        return self.__type1_recs

    def type2List(self):
        ''' Return the list of type 002 information (i.e. the list of 
            :py:class:`starec.type002` instances).
        '''
        return self.__type2_recs

    class type002:
        ''' A class to hold type 002 station information records for a single station.
        '''
        pass

        def start(self):
            ''' Return the start datetime (as ``datetime``). '''
            return self.__start

        def stop(self):
            ''' Return the stop datetime (as ``datetime``). '''
            return self.__stop

        def name(self):
            ''' Return the name. '''
            return self.__name

        def line(self):
            ''' Return the type 002 original, information record line. '''
            return self.__line

        def __init__(self,line):
            ''' Initialize a :py:class:`starec.type002` instance using a type 002
                information line. This will set the start and stop date and the 
                station name.
            '''
            self.__name = line[0:20].strip()
            if line[27:47].strip() == '':
                self.__start = starec.min_date
            else:
                try:
                    self.__start = datetime.datetime.strptime(line[27:47].strip(), '%Y %m %d %H %M %S')
                except:
                    raise RuntimeError('Invalid TYPE 002 datetime: ['+line.strip('\n')+']')
            if line[48:68].strip() == '':
                self.__stop = datetime.datetime.combine(datetime.date.today(), datetime.datetime.max.time())
            else:
                try:
                    self.__stop = datetime.datetime.strptime(line[48:68].strip(), '%Y %m %d %H %M %S')
                except:
                    raise RuntimeError('Invalid TYPE 002 datetime: ['+line.strip('\n')+']')
            if self.__start > self.__stop:
                raise RuntimeError('Invalid TYPE 002 datetime: ['+line.strip('\n')+']')
            self.__line = line.rstrip('\n')

    class type001:
        ''' A class to hold type 001 station information records for a single station.
        '''
        pass

        def start(self):
            ''' Return the start datetime (as ``datetime``). '''
            return self.__start

        def stop(self):
            ''' Return the stop datetime (as ``datetime``). '''
            return self.__stop

        def line(self):
            ''' Return the original information line. '''
            return self.__line

        def staname(self):
            ''' Return the 'STATION NAME' column. '''
            return self.__name

        def old_staname(self):
            ''' Return the 'OLD STATION NAME' column. '''
            return self.__line[69:90].strip(' ')

        def match(self,type2):
            ''' Match a type 002 record line with (this) instance.
                This will return ``True``, if the type 002 record (i.e. ``type2``)
                has the same name, as this instance and the duration of
                this info is within this instance's limits.

                :param type2: A :py:class:`starec.type002` instance.

            '''
            return ( self.__name == type2.name() and self.start() >= type2.start() and self.stop() >= type2.stop() )

        def __init__(self,line):
            ''' Initialize a :py:class:`starec.type001` instance using a type 001
                information line. This will set the start and stop date and the 
                station name.
            '''
            self.__name = line[0:20].strip()
            if line[27:47].strip() == '':
                self.__start = starec.min_date
            else:
                try:
                    self.__start = datetime.datetime.strptime(line[27:47].strip(), '%Y %m %d %H %M %S')
                except:
                    raise RuntimeError('Invalid TYPE 001 datetime: ['+line.strip('\n')+']')
            if line[48:68].strip() == '':
                self.__stop = datetime.datetime.combine(datetime.date.today(), datetime.datetime.max.time())
            else:
                try:
                    self.__stop = datetime.datetime.strptime(line[48:68].strip(), '%Y %m %d %H %M %S')
                except:
                    raise RuntimeError('Invalid TYPE 001 datetime: ['+line.strip('\n')+']')
            if self.__start > self.__stop:
                raise RuntimeError('Invalid TYPE 001 datetime: ['+line.strip('\n')+']')
            self.__line = line.rstrip('\n')

class stafile:
    ''' A station information file (.STA) class, to represent Bernese v5.2 format .STA
        files.
    '''
    __type_names = ['RENAMING OF STATIONS',
            'STATION INFORMATION',
            'HANDLING OF STATION PROBLEMS', 
            'STATION COORDINATES AND VELOCITIES (ADDNEQ)',
            'HANDLING STATION TYPES']
    ''' A dictionary to map a type to a header (e.g. 'TYPE 001' is 
        'RENAMING OF STATIONS'). This list is shared among all
        instances.
    '''

    def __init__(self,filename):
        ''' Initialize a sta object given its filename;
            try locating the file
            TODO add header resolution to make sure this a valid .STA file
        '''
        self.__filename = filename
        if not os.path.isfile(self.__filename):
            raise IOError('No such file '+filename)

    def __findTypeStart(self,stream,type,max_lines=1000):
        ''' Given a (sta) input file stream, go to the line where a specific
            type starts. E.g. if the type specified is '1' (i.e. ``type=1``), then this function
            will search for the line: *'TYPE 001: RENAMING OF STATIONS'*.
            The line to search for, is compiled using the parameter ``type`` and the
            :py:attr:`__type_names` dictionary. If the line is not found after 
            ``max_lines`` are read, then an exception is thrown.
            In case of sucess, the (header) line is returned, and the stream
            buffer is placed at the end of the header line.
            Note that the ``type`` parameter must be a positive integer in the
            range ``[1, len(___type_names)]``.

            :param stream:    Thif not line or len(line) < 5:e input stream for this istance.
            :param type:      The number of type to search for.
            :param max_lines: Max lines to read before quiting.

            :returns:         On sucess, the matched line; the input stream is 
                              left at the end of the matched line.
        '''
        try:
            itype = int(type)
            if itype > len(self.__type_names) + 1:
                raise RuntimeError('Invalid TYPE to search for : ['+ type + ']')
        except:
            raise RuntimeError('Invalid TYPE to search for.')

        line_str = 'TYPE %03i: %s' %(itype,self.__type_names[itype-1])

        dummy_it = 0
        line = stream.readline()

        while (True):
            if not line:
                raise RuntimeError('EOF encountered.')
            if line.strip() == line_str:
                return line;
            line = stream.readline()
            dummy_it += 1
            if dummy_it > max_lines:
                raise RuntimeError('MAX_LINES encountered.')

    def fillStaRec2(self,station,starecs):
        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        if len(starecs.type2List()) != 0:
            starecs.__type2_recs = []

        if len(starecs.type1List()) == 0:
            return []

        try:
            self.__findTypeStart(fin,2,max_lines=10000)
        except:
            fin.close()
            raise RuntimeError('Cannot find station')

        fin.readline()
        fin.readline()

        line = fin.readline()
        if line.strip() != 'STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK':
            fin.close()
            raise RuntimeError('Invalid line:['+line.strip()+']')

        station_found      = False

        line = fin.readline()
        line = fin.readline()
        while (True):
            if len(line) < 5:
                fin.close()
                break

            type2 = starec.type002(line)
            for i in starecs.type1List():
                if i.match(type2):
                    starecs.appendtype2(type2)
                    station_found = True
            line = fin.readline()

        fin.close()

        return starecs, len(starecs.type2List())

    def loadAll(self):
        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        try:
            self.__findTypeStart(fin,1,max_lines=100)
        except:
            fin.close()
            raise RuntimeError('Cannot find station')

        ## two unimportant lines ...
        fin.readline()
        fin.readline()
        ## header line ...
        line = fin.readline()
        if line.strip() != 'STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK':
            fin.close()
            raise RuntimeError('Cannot find station')
        ## line [***...]
        fin.readline()

        line          = fin.readline()
        rec_list      = []

        while (True):
            if not line or len(line) < 5:
                fin.close()
                break
            try:
                addToRecList1(rec_list, line)
            except:
                fin.close()
                raise

            line = fin.readline()

        fin.close()

        return rec_list


    def fillStaRec1(self,station):
        ''' Given a station name, this function will create and return a
            py:class:`starec` instance, and fill all type 001 information
            (i.e. the instance's :py:attr:`starec.__type1_recs` list). The
            input ``station`` parameter is matched using the 'OLD NAME'
            column and **NOT** the 'STATION NAME' column.
        '''
        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        try:
            self.__findTypeStart(fin,1,max_lines=100)
        except:
            fin.close()
            raise RuntimeError('Cannot find station')

        ## two unimportant lines ...
        fin.readline()
        fin.readline()
        ## header line ...
        line = fin.readline()
        if line.strip() != 'STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK':
            fin.close()
            raise RuntimeError('Cannot find station')
        ## line [***...]
        fin.readline()

        station_found = False
        line          = fin.readline()
        records       = starec(station)

        while (True):
            if not line or len(line) < 5:
                fin.close()
                break

            generic_name = line[69:89].strip()
            ## Remove the trailing '*' cause then e.g. 'DYNG*' would match 'DYN'
            if generic_name[-1] == '*': generic_name = generic_name[:-1]
            ## Make a regex out of the old station name
            regex_name = re.compile(generic_name)

            ## Match with column 'OLD STATION NAME'
            if regex_name.match(station): ## and int(line[22:25]) == 1:
                try:
                    rectmp1 = starec.type001(line)
                except:
                    fin.close()
                    raise
                records.appendtype1(rectmp1)
                station_found = True

            line = fin.readline()

        fin.close()

        return records, len(records.type1List())
