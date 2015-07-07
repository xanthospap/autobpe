#! /usr/bin/python

import os
import datetime
import re

class StaFile:
    filename_ = ''
    type_names = ['RENAMING OF STATIONS',
            'STATION INFORMATION',
            'HANDLING OF STATION PROBLEMS', 
            'STATION COORDINATES AND VELOCITIES (ADDNEQ)',
            'HANDLING STATION TYPES']

    def __init__(self,filename):
        if not os.path.isfile(filename):
            raise IOError('No such file '+filename)
        self.filename_ = filename

    def findTypeStart(self,stream,type,max_lines=1000):
        '''
        '''
        try:
            itype = int(type)
            if itype > len(self.type_names) + 1:
                raise RuntimeError('Invalid TYPE to search for : ['+ type + ']')
        except:
            raise RuntimeError('Invalid TYPE to search for.')

        line_str = 'TYPE %03i: %s' %(itype,self.type_names[itype-1])

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

    ## TODO A station may be renamed for a specific time interval. In this
    ## case we need date as input parameter.
    def findStationType01(self,station):

        try:
            fin = open(self.filename_,'r')
        except:
            fin.close()
            raise IOError('No such file '+filename)

        try:
            self.findTypeStart(fin,1,max_lines=10)
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

        ## WARNING : The station name given might be an old station name, that
        ## is renamed, e.g.
        ## [WDC3 40451S008        003  2006 07 17 00 00 00                       S071 40451S005        NGA RENAMING]
        station_found = False
        line = fin.readline()
        while (True):
            if len(line) < 5:
                fin.close()
                raise RuntimeError('Cannot find station')

            generic_name = line[69:89].strip()
            ## Remove the trailing '*' cause then e.g. 'DYNG*' would match 'DYN'
            if generic_name[-1] == '*': generic_name = generic_name[:-1]
            ## Make a regex out of the old station name
            regex_name = re.compile(generic_name)

            ## Renaming line
            if regex_name.match(station) and int(line[22:25]) == 3:
                #start_date = line[27:48]
                #stop__date = line[48:69]
                if line[27:48].strip() != '' or line[48:69].strip() != '':
                    print 'Warning! Station',station,'renamed for specific time interval!'

            if regex_name.match(station) and int(line[22:25]) == 1:
                station_found = True
                # print 'Matched line: ['+line.strip()+'], matched-> ['+station+'] to ['+generic_name+']'
                break
            line = fin.readline()

        fin.close()

        if station_found:
            return line
        else:
            return []

    def findStationType02(self,station):
        
        try:
            fin = open(self.filename_,'r')
        except:
            fin.close()
            raise IOError('No such file '+filename)

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
                # raise RuntimeError('Cannot find station')
            if line[0:20].strip() == station:
                station_found = True
                station_info_lines.append(line)
            line = fin.readline()

        fin.close()
        return station_info_lines

x = StaFile('CODE.STA')
ln1 = x.findStationType01('WDC3 40451S008')
print ln1
ln1 = x.findStationType02('WDC3 40451S008')
print ln1
ln1 = x.findStationType01('U122 30310S001')
print ln1
ln1 = x.findStationType01('ANKR')
print ln1
ln1 = x.findStationType01('S071 40451S005')
print ln1
