#! /usr/bin/python

import os
import datetime
import re

class stafile:
    ''' A station information class, to represent Bernese v5.2 format .STA 
        files.
    '''
    __filename  = '' #: The filename
    ##: a dictionary to map a type to a header
    __type_names = ['RENAMING OF STATIONS',
            'STATION INFORMATION',
            'HANDLING OF STATION PROBLEMS', 
            'STATION COORDINATES AND VELOCITIES (ADDNEQ)',
            'HANDLING STATION TYPES']

    def __init__(self,filename):
        ''' Initialize a sta object given its filename;
            try locating the file
        '''
        if not os.path.isfile(filename):
            raise IOError('No such file '+filename)
        self.__filename = filename

    def findTypeStart(self,stream,type,max_lines=1000):
        ''' Given a (sta) input file stream, go to the line where a specific
            type starts. E.g. if the type specified is *'1'*, then this function
            will search for the line: *'TYPE 001: RENAMING OF STATIONS'*.
            The line to search for, is compiled using the ``type`` and the 
            ``__type_names`` dictionary. If the line is not found after 
            ``max_lines`` are read, then an exception is thrown.
            In case of sucess, the (header) line is returned, and the stream
            buffer is placed at the end of the header line.
            Note that the ``type`` parameter must be a positive integer in the
            range ``[1, len(___type_names)]``.

            :param stream:    The input stream for this istance.
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

    def findStationType01(self,station,epoch=None):
        ''' This function will search for the station information (concerning
            a specific station) included in the *'TYPE 01'* block.
            Given a station name (e.g. 'ANKR' or 'ANKR 20805M002'), it will
            try to match the information line provided in the *'TYPE 01'* block,
            with a flag of *'001'* and **NOT** *'003'*. The station matching is **NOT**
            performed with the column *'STATION NAME'*, but with *'OLD STATION NAME'*
            In some cases, it might be necessary to also suply the epoch for
            which the info is needed (some times the stations are renamed and
            different names are adopted previous before and after a certain
            epoch).

            :param station: The name of the station to match.
            :param epoch:   A ``datetime`` object, epoch for which the info is
                            wanted.

            :returns:       The *'TYPE 01'* block record for this station (for
                            this epoch).

            *TODO* : If a renaming line (flag 003) is encountered it is skipped.
                   What should i do with this line ??
        '''

        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        try:
            self.findTypeStart(fin,1,max_lines=100)
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

        ## WDC1 40451S005        003                       2006 07 16 23 59 59  S071 40451S005        NGA RENAMING
        ## WDC3 40451S008        003  2006 07 17 00 00 00                       S071 40451S005        NGA RENAMING
        ## WDC1 40451S005        001                       2006 07 16 23 59 59  S071*                 NGA
        ## WDC3 40451S008        001  2006 07 17 00 00 00                       S071*                 NGA
        station_found = False
        line          = fin.readline()
        while (True):
            if len(line) < 5:
                fin.close()
                raise RuntimeError('Cannot find station')

            generic_name = line[69:89].strip()
            ## Remove the trailing '*' cause then e.g. 'DYNG*' would match 'DYN'
            if generic_name[-1] == '*': generic_name = generic_name[:-1]
            ## Make a regex out of the old station name
            regex_name = re.compile(generic_name)

            ## Match with column 'OLD STATION NAME' and 001 flag
            if regex_name.match(station) and int(line[22:25]) == 1:
                start_date = line[27:48]
                stop__date = line[48:69]
                low_pass   = False
                high_pass  = False

                if start_date.strip() == '':
                    low_pass   = True
                    # start_date = datetime.datetime(1800,01,01,0,0,0)
                else:
                    start_date = datetime.datetime.strptime(start_date.strip(),'%Y %m %d %H %M %S')
                    if epoch == None:
                        fin.close()
                        raise RuntimeError('Need to specify epoch for this station ['+line.strip()+']')
                    if epoch >= start_date:
                        low_pass = True
                    else:
                        low_pass = False

                if stop__date.strip() == '':
                    high_pass  = True
                    # stop__date = datetime.datetime(2100,01,01,0,0,0)
                else:
                    stop__date = datetime.datetime.strptime(stop__date.strip(),'%Y %m %d %H %M %S')
                    if epoch == None:
                        fin.close()
                        raise RuntimeError('Need to specify epoch for this station ['+line.strip()+']')
                    if epoch <= stop__date:
                        high_pass = True
                    else:
                        high_pass = False

                if low_pass and high_pass:
                    station_found = True
                    break
                #else:
                #    print 'Skiping line -> ['+line.strip()+']'

            line = fin.readline()

        fin.close()

        if station_found:
            return line
        else:
            return []

    def findStationType02(self,station,epoch=None):
        ''' This function will search for station info recorded in *'TYPE 002'*
            and return it.
            The station name provided, will be resolved using the *'TYPE 001'*
            block using the function ``findStationType01``. Hence, the name used to
            match info in the *'TYPE 002'* block will be the column *'STATION NAME'*
            E.g., given station name 'ANKR' and using the CODE.STA file, we
            will get the name 'ANKR 20805M002' and we will search the block
            'TYPE 002' for this name. Note that in case of renaming, a specific
            date may be needed (see ``findStationType01``).
            If no date is provided, all entried for the station will be matched
            and returned; else, only the one withing the specified interval
            will be returned.

            :param station: The name of the station to match.
            :param epoch:   A ``datetime`` object, epoch for which the info is
                            wanted.

            :returns:       A list of *'TYPE 02'* block records for this station
                            (for this epoch).

        '''

        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        try:
            type1 = self.findStationType01(station,epoch)
        except:
            fin.close()
            raise RuntimeError('Cannot find type 001 station info')

        station_name = type1[0:20].strip()

        try:
            self.findTypeStart(fin,2,max_lines=10000)
        except:
            fin.close()
            raise RuntimeError('Cannot find station')

        fin.readline()
        fin.readline()

        line = fin.readline()
        if line.strip() != 'STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK':
            fin.close()
            raise RuntimeError('Invalid line:['+line.strip()+']')

        station_info_lines = []
        station_found      = False

        line = fin.readline()
        while (True):
            if len(line) < 5:
                fin.close()
                break
            if line[0:20].strip() == station_name :
                start_date = line[27:48]
                stop__date = line[48:69]
                low_pass   = False
                high_pass  = False

                if start_date.strip() == '' or epoch == None:
                    low_pass   = True
                else:
                    start_date = datetime.datetime.strptime(start_date.strip(),'%Y %m %d %H %M %S')
                    if epoch == None:
                        fin.close()
                        raise RuntimeError('Need to specify epoch for this station ['+line.strip()+']')
                    if epoch >= start_date:
                        low_pass = True
                    else:
                        low_pass = False

                if stop__date.strip() == '' or epoch == None:
                    high_pass  = True
                else:
                    stop__date = datetime.datetime.strptime(stop__date.strip(),'%Y %m %d %H %M %S')
                    if epoch == None:
                        fin.close()
                        raise RuntimeError('Need to specify epoch for this station ['+line.strip()+']')
                    if epoch <= stop__date:
                        high_pass = True
                    else:
                        high_pass = False

                if low_pass and high_pass:
                    station_found = True
                    station_info_lines.append(line)

            line = fin.readline()

        fin.close()
        return station_info_lines

    def getStationName(self,station,epoch=None):
        ''' Find and return the station name, as recorded in the *'TYPE 001'*
            block
        '''
        try:
            return self.findStationType01(station,epoch)[0:20].strip()
        except:
            raise RuntimeError('Cannot find type 001 station info')

    def getStationAntenna(self,station,epoch=None):
        ''' Find and return the antenna type, as recorded in the *'TYPE 002'*
            block
        '''
        try:
            info_list = self.findStationType02(station,epoch)
            if len(info_list) > 1:
                raise RuntimeError('More than one entries!')
            return info_list[0][121:141].strip()
        except:
            raise RuntimeError('Cannot find type 002 station info')

    def getStationReceiver(self,station,epoch=None):
        ''' Find and return the receiver type, as recorded in the *'TYPE 002'*
            block
        '''
        try:
            info_list = self.findStationType02(station,epoch)
            if len(info_list) > 1:
                raise RuntimeError('More than one entries!')
            return info_list[0][69:89].strip()
        except:
            raise RuntimeError('Cannot find type 002 station info')
