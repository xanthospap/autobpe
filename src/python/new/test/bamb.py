#! /usr/bin/python

import os

class ambline:
    __line = ''

    def __init__(self,line):
        self.__line = line

class ambfile:
    ''' A class to hold a Bernese ambiguity summary file (.SUM)
    '''
    __filename   = '' #: The filename

    ''' Ambiguity resolution methods and their id-codes '''
    __amb_method = {'Code-Based Widelane': '#AR_WL',
            'Code-Based Narrowlane': '#AR_NL',
            'Phase-Based Widelane': '#AR_L5',
            'Phase-Based Narrowlane': '#AR_L3',
            'Quasi-Ionosphere-Free': '#AR_QIF',
            'Direct L1/L2': '#AR_L12'
            }

    ''' Ambiguity resolution method short names '''
    __amb_keys   = {'cbwl': 'Code-Based Widelane',
            'cbnl': 'Code-Based Narrowlane',
            'pbwl': 'Phase-Based Widelane',
            'pbnl': 'Phase-Based Narrowlane',
            'qif': 'Quasi-Ionosphere-Free',
            'l12': 'Direct L1/L2'
            }

    ''' Satellite System id-names '''
    __satsys     = {'GPS': 'G', 'GLONASS': 'R', 'MIXED': 'GR'}

    ''' Number of LC's for every method (i.e. columns of type: Max/RMS L5' '''
    __amb_lcs   = {'cbwl': 1, 'cbnl': 1, 'pbwl': 1, 'pbnl': 1, 'qif': 2,
            'l12': 1}


    def __init__(self,filename):
        ''' Initialize a sta object given its filename;
            try locating the file
        '''
        if not os.path.isfile(filename):
            raise IOError('No such file '+filename)
        self.__filename = filename

    def collectMethodBsls(self,method):

        fin = open(self.__filename)

        try:
            self.goToMethod(fin,method)
        except:
            raise

        ## skip 5 lines
        for i in range(1,6): line = fin.readline()

        # read next line; if it is full of '=' no baselines to follow
        line = fin.readline()
        if not line:
            fin.close()
            raise RuntimeError('Cannot collect baselines for resolution method '+method)
        elif line[0:3] == '===':
            return

        smeth1 = self.__amb_keys[method]
        smeth2 = self.__amb_method[smeth1]

        bsl_info = []

        while (line):
            if line.rstrip()[-7:] != smeth2:
                break
            if len(line) < 5:
                fin.close()
                raise RuntimeError('Error collecting baselines for resolution method '+method)
            elif line[0:3] == '---': ## normal termination
                break
            else:
                bsl_info.append(line)
            line = fin.readline()
            print line.strip()

        fin.close()
        return bsl_info

    def goToMethod(self,istream,method,max_lines=1000):
        ''' Position the input stream ``istream`` at the start of results
            for method ``method`` (actualy at the end of the header line).

            :note: The file will be searched starting from the current
            position of the stream, and **NOT** from the begining of the
            file.

            :param istream:   The input stream (of an ambiguity summary file).
            :param method:    The method to search for; This must be a valid
                              string denoting a resolution method, as represented
                              in the ``__amb_keys`` dictionary.
            :param max_lines: Maximum number of lines to read before quiting.
        '''

        try:
            smeth1 = self.__amb_keys[method]
            smeth2 = self.__amb_method[smeth1]
        except:
            raise RuntimeError('Invalid resolution method '+method)

        if smeth2 == '#AR_L12':
            str = ' %s Ambiguity Resolution (<' %(smeth1)
        else:
            str   = ' %s (%s) Ambiguity Resolution (<' %(smeth1,smeth2.replace('#AR_',''))

        length = len(str)

        line = istream.readline()
        i    = 0
        line_found = False

        while (line and i < max_lines):
            if len(line) > length:
                if line[0:length] == str:
                    line_found = True
                    break
            line = istream.readline()
            i += 1

        if line_found:
            return line
        else:
            raise RuntimeError('Failed to find entry for method '+smeth1)

## EXAMPLE USAGE
x = ambfile('FFU151000_GNSS.SUM')
fin = open('FFU151000_GNSS.SUM','r')
print x.goToMethod(fin,'l12')
fin.seek(0)
print x.goToMethod(fin,'cbnl')
fin.seek(0)
print x.goToMethod(fin,'pbwl')
fin.seek(0)
print x.goToMethod(fin,'qif')
#print x.goToMethod(fin,'lol')

print x.collectMethodBsls('l12')
print x.collectMethodBsls('cbnl')
print x.collectMethodBsls('pbwl')
print x.collectMethodBsls('qif')
