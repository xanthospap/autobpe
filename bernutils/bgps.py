#! /usr/bin/python

import os

class gpsoutfile:
    ''' A class to hold a Bernese v5.2 GPSEST output file '''

    def __init__(self,filename):
        ''' Constructor; check for file existance '''
        self.__filename  = filename  #: The filename of the output file
        self.__program   = ''  #: The program that created (this) file
        self.__campaign  = ''  #: Name of the campaign
        self.__doy       = ''  #: Day Of Year (processed)
        self.__ses       = ''  #: Session (processed)
        self.__yr        = ''  #: Year (processed)
        self.__stations  = []  #: List of stations included in the processing/output file
        if not os.path.isfile(self.__filename):
            raise IOError('No such file '+filename)

    def findFirstLine(self,stream,line,eof_line='>>>',max_lines=1000):
        ''' Given a GPSEST output file, try to match the line passed as
            ``line``, until ``eof_line`` is not matched and no more than
            ``max_lines`` are read.
            If the line is found, the stream input position, will be returned
            at the end of the matched line.

            :param stream:    The (calling) instance's input stream.
            :param line:      The prototype line to match.
            :param eof_line:  EOF record.
            :param max_lines: Max lines to be read befor quiting.

            :returns:         On success, the matched line; input buffer is set
                              at the end of the matched line.
            
            :warning: Note that the search will start from the current get 
                      position of the stream and *NOT* from the begining of 
                      the file.
        '''

        try:
            ln = stream.readline()
        except:
            raise IOError('Stream closed')

        stop = len(eof_line)
        dummy_it = 0
        while (dummy_it < max_lines):
            if ln.strip() == line:
                return ln
            elif ln.strip()[0:stop] == eof_line:
                raise RuntimeError('Cannot find line :'+line)
            dummy_it += 1
            ln = stream.readline()

    def getHeaderInfo(self):
        ''' Given a GPSEST output file, try to read the header
            information and return in in a list as:
            campaign_name, doy, session, year, date_run, username, # of stations
        '''

        try:
            fin = open(self.__filename,'r')
        except:
            fin.close()
            raise IOError('No such file '+self.__filename)

        ## first line is empty
        line = fin.readline()

        ## second line ->
        ## =====================
        line = fin.readline()

        ## Third line ->
        ##  Bernese GNSS Software, Version 5.2
        line = fin.readline().strip()
        if line != 'Bernese GNSS Software, Version 5.2':
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 3')

        ## Forth line ->
        ## ------------------
        line = fin.readline()

        ## WARNING -> This is different in GPSEST and ADNEQ2
        ## Fifth line ->
        ## Program        : GPSEST
        line = fin.readline().split()
        if not (len(line) == 3 and line[2] == 'GPSEST'):
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 5')
        self.__program = line[2]

        ## Sixth line
        ## Purpose        : Parameter estimation
        line = fin.readline()

        ## Seventh line
        ## -------------------
        line = fin.readline()

        ## Eighth line
        ## Campaign       : ${P}/LAVMO
        line = fin.readline().split()
        if not len(line) == 3:
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 8')
        self.__campaign = line[2].split('/')[-1]

        ## Ninth line
        ## Default session: 1190 year 2015
        line = fin.readline().split()
        if not len(line) == 5:
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 9')
        self.__doy = line[2][0:-1]
        self.__ses = line[2][-1]
        self.__yr  = line[4]

        ## Tenth line
        ## Date           : 15-Jun-2015 15:16:49
        line = fin.readline().split()
        if not len(line) == 4:
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 10')
        dtrun = line[2] + ' ' + line[3]

        ## Eleventh line
        ## User name      : xanthos
        line = fin.readline().split()
        if not len(line) == 4:
            fin.close()
            raise RuntimeError('Invalid GPSEST format: line 11')
        user = line[3]

        ## go to the second occurance of '4. STATIONS'
        self.__stations = []
        lstr = '4. STATIONS'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('Station list not found until EOF!')
        self.__stations = []
        lstr = '4. STATIONS'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('Station list not found until EOF!')

        for i in range(0,17): line = fin.readline()

        if line.strip() != 'num  Station name     obs e/f/h        X (m)           Y (m)           Z (m)        Latitude       Longitude    Height (m)':
            fin.close()
            raise RuntimeError('Error matching station list!')
        line = fin.readline()

        line = fin.readline()
        while (True):
            if len(line) < 5:
                break;
            try:
                self.__stations.append(line[6:21].strip())
                feh = line[27:34].strip()
                x = float(line[34:50])
                y = float(line[50:66])
                z = float(line[66:83])
            except:
                raise RuntimeError('Error matching station list!')
            line = fin.readline()

        fin.close()

        return self.__campaign, self.__doy, self.__ses, self.__yr, dtrun, user

    def getBaselineList(self):
        ''' This function will try to read all baselines processed in the run, 
            and report their information. The baselines are read from the 
            section:
            *2. OBSERVATION FILES, MAIN CHARACTERISTICS*
            Two tables are read, namely:
            [FILE  OBSERVATION FILE HEADER          OBSERVATION FILE                  SESS     RECEIVER 1            RECEIVER 2]
            and
            [FILE TYP FREQ.  STATION 1        STATION 2        SESS  FIRST OBSERV.TIME  #EPO  DT #EF #CLK ARC #SAT  W 12    #AMB  L1  L2  L5  RM]
            and the concatenated list is returned, i.e.:
            [aa, baseline_name, type, frequency, station1, station2, first_observation, # of epochs]
        '''

        try:
            fin = open(self.__filename,'r')
        except:
            raise IOError('No such file '+self.__filename)

        num_of_bsl = 0
        dummy_it   = 0

        ## skip everything until 'INPUT AND OUTPUT FILENAMES' line
        lstr = 'INPUT AND OUTPUT FILENAMES'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('Baseline list not found until EOF!')

        lstr = '2. OBSERVATION FILES'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('"2. OBSERVATION FILES" list not found until EOF!')

        ## skip next 10 lines
        for i in range(0,10):
            line = fin.readline()

        ## next line should be:
        ## FILE  OBSERVATION FILE HEADER          OBSERVATION FILE                  SESS     RECEIVER 1            RECEIVER 2
        if line.strip() != 'FILE  OBSERVATION FILE HEADER          OBSERVATION FILE                  SESS     RECEIVER 1            RECEIVER 2':
            fin.close()
            raise RuntimeError('Unexpected line wile searching for baselines [1]!')

        ## skip next 2 lines
        for i in range(0,2):
            line = fin.readline()

        dummy_it = 0
        bsl_lst_1 = []
        ## read baselines
        line = fin.readline()
        while len(line) > 5:
            l = line.split()
            try:
                _aa   = l[0]
                _head = l[1]
                _obs  = l[2]
                _ses  = l[3]
                _rec1 = line[83:106].strip()
                _rec2 = line[106:].strip()
                bsl_lst_1.append( [_aa,os.path.basename(_head)[0:-3]] )
                ## print 'added list element ->',[_aa,os.path.basename(_head)[0:-3]]
                num_of_bsl += 1
            except:
                fin.close()
                raise RuntimeError('Failed reading baselines!')
            if _ses != self.__doy + self.__ses:
                fin.close()
                raise RuntimeError('Failed reading baselines! Invalid session')
            line = fin.readline()
            dummy_it += 1
            if dummy_it > 200:
                fin.close()
                raise RuntimeError('Failed reading baselines!')

        line = fin.readline()
        line = fin.readline()
        if line.strip() != 'FILE TYP FREQ.  STATION 1        STATION 2        SESS  FIRST OBSERV.TIME  #EPO  DT #EF #CLK ARC #SAT  W 12    #AMB  L1  L2  L5  RM':
            fin.close()
            raise RuntimeError('Unexpected line wile searching for baselines [2]!')

        ## skip next 2 lines
        for i in range(0,2):
            line = fin.readline()

        ## read baselines
        bsl_lst_2   = []
        dummy_it    = 0
        num_of_bsl2 = 0
        line = fin.readline()
        while len(line) > 5:
            if (num_of_bsl2 > num_of_bsl):
                fin.close()
                raise RuntimeError('Failed reading baselines!')
            l = line.split()
            try:
                _aa   = l[0]
                _type = l[1]
                _freq = l[2]
                _sta1 = line[17:32].strip()
                _sta2 = line[34:49].strip()
                _first_obs = line[57:75].strip()
                _epochs = int(line[77:81])
                num_of_bsl2 += 1
                bsl_lst_2.append( [_aa,_type,_freq,_sta1,_sta2,_first_obs,_epochs] )
                ## print 'added list element ->',[_aa,_type,_freq,_sta1,_sta2,_first_obs,_epochs]
            except:
                fin.close()
                raise RuntimeError('Failed reading baselines!')
            if _ses != self.__doy + self.__ses:
                fin.close()
                raise RuntimeError('Failed reading baselines! Invalid session')
            line = fin.readline()

        fin.close()

        baseline_list = []
        for i, j in zip(bsl_lst_1,bsl_lst_2):
            if i[0] != j[0]:
                raise RuntimeError('Inconsistent baselines')
            l = i + j[1:]
            baseline_list.append(l)

        ## return list: [aa, baseline_name, type, frequency, station1, station2, first_observation, # of epochs]
        return baseline_list

    def getCrdSolInfo(self):
        ''' Given a GPSEST output file, this function will try to read information regarding the
            (solution) coordinate results. The information is collected from the table:
            'NUM  STATION NAME     PARAMETER    A PRIORI VALUE       NEW VALUE     NEW- A PRIORI  RMS ERROR   3-D ELLIPSOID       2-D ELLIPSE'
            for every stations already mentioned in the instances station list. So make sure,
            the instances station list is already filled. The return list, contains
            a list for every station, in the following format:
            [name,3x(a-priori,estimated,new-old,rms),3x(new-old,rms)]
            for   X, Y, Z                            HGT, LAT, LON
            TODO A same block of information maybe available in the section 'RESULTS PART 2'. Try reading that
            before reading the blok from 'RESULTS PART 1'.
        '''

        try:
            fin = open(self.__filename,'r')
        except:
            raise IOError('No such file '+self.__filename)

        ## skip everything until '13. RESULTS (PART 1)' line
        lstr = '13. RESULTS (PART 1)'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('Coordinate list not found until EOF!')

        ## skip everything until
        lstr = 'NUM  STATION NAME     PARAMETER    A PRIORI VALUE       NEW VALUE     NEW- A PRIORI  RMS ERROR   3-D ELLIPSOID       2-D ELLIPSE'
        try:
            self.findFirstLine(fin,lstr)
        except:
            fin.close()
            raise RuntimeError('Coordinate list not found until EOF!')

        line = fin.readline()
        line = fin.readline()

        station_info = []
        it = 0
        while (it < len(self.__stations)):
            tmp_info = []
            for i in range(0,3):
                line = fin.readline()
                try:
                    if i == 0:
                        station_ = line[6:21]
                        tmp_info.append(station_)
                    cflag = line[23:25].strip()
                    if (i == 0 and cflag != 'X') or (i == 1 and cflag != 'Y') or (i == 2 and cflag != 'Z'):
                        fin.close()
                        raise RuntimeError('Error reading parameter' + str(i))
                    a_priori  = float(line[36:51])
                    estimated = float(line[55:70])
                    new_old   = float(line[71:82])
                    rms       = float(line[85:].strip())
                    tmp_info += [a_priori,estimated,new_old,rms]
                except:
                    fin.close()
                    raise RuntimeError('Error reading cartesian parameters' + str(i))

            line = fin.readline()
            for i in range(0,3):
                line = fin.readline()
                try:
                    new_old   = float(line[71:82])
                    rms       = float(line[85:95])
                    tmp_info += [new_old,rms]
                except:
                    fin.close()
                    raise RuntimeError('Error reading geodetic parameters' + str(i))

            station_info.append( tmp_info )
            ##print tmp_info
            it += 1
            line = fin.readline()

        if it != len(self.__stations):
            fin.close()
            raise RuntimeError('Error collecting station parameters')

        fin.close()
        return station_info
