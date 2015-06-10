#! /usr/bin/python

import sys
import os.path
import getopt ## Fuck yeah! C-style

''' Default Values for various variables
'''
PATH_TO_STA='/media/Seagate/solutions/stations'
C_FINAL_CTS_EXT='.c.cts'
C_RAPID_CTS_EXT='.c.ctsR'
G_FINAL_CTS_EXT='.g.cts'
G_RAPID_CTS_EXT='.g.ctsR'
valid_ts_version=['50','52']
CTS_VERSION='50'
stations=[]
COORDINATES='CARTESIAN'

def help():
    print 'query_time_span is a utility program to search and print basic'
    print 'information regarding the raw time-series of a station.'
    print ''
    print 'Switches: '
    print '        -s --station= Specify the station. You can specify more'
    print '                      than one stations, using a comma-seperated'
    print '                      list; e.g. -s station1,station2,station3'
    print '        -g --geodetic Use the geodetic time-series file (i.e. .g.cts)'
    print '                      instead of the cartesian'
    print '        -c --cts_version= Specify the .cts version; can be 50 or 52'
    print '        -h --help Show this help message and exit.'
    print ''
    return

def read_c_file_50(final,rapid):
    try:
        fin = open(final)
    except:
        raise NameError('fuck')
    _line_ = 0
    collected_dates = []
    min_date = 5000
    max_date = -500
    avg_x    = .0e0
    avg_y    = .0e0
    avg_z    = .0e0
    data_pts = 0
    unique_data_points = 0
    for line in fin.readlines():
        try:
            if line[0] != '#':
                tdate = float(line.split()[5])
                if tdate < min_date:
                    min_date = tdate
                elif tdate > max_date:
                    max_date = tdate;
                avg_x = (float(line.split()[6] ) + data_pts * avg_x) / (float(data_pts+1))
                avg_y = (float(line.split()[8] ) + data_pts * avg_x) / (float(data_pts+1))
                avg_z = (float(line.split()[10]) + data_pts * avg_x) / (float(data_pts+1))
                data_pts += 1
                try:
                    dts = "%9.4f" % tdate
                    collected_dates.index(dts) ## (tdate)
                    ## print 'already have',line[5],' for date',tdate,'[',dts,']'
                except:
                    collected_dates.append(dts) ##(tdate)
                    ## print 'added ',line[5]
                    unique_data_points += 1
        except:
            fin.close()
            sys.stderr.write('\nError reading file '+final+' at line '+str(_line_))
            raise NameError('fuck')
        _line_ += 1
        fin.close()

    ## Now do the same for the rapid file (do not update average)
    _line_ = 0
    try:
        fin = open(rapid)
        for line in fin.readlines():
            try:
                if line[0] != '#':
                    tdate = float(line.split()[5])
                    if tdate < min_date:
                        min_date = tdate
                    elif tdate > max_date:
                        max_date = tdate;
                    # avg_x = (float(line.split()[6] ) + data_pts * avg_x) / (float(data_pts+1))
                    # avg_y = (float(line.split()[8] ) + data_pts * avg_x) / (float(data_pts+1))
                    # avg_z = (float(line.split()[10]) + data_pts * avg_x) / (float(data_pts+1))
                    # data_pts += 1
                    try:
                        dts = "%9.4f" % tdate
                        collected_dates.index(dts) ## (tdate)
                        ## print 'already have',line[5],' for date',tdate,'[',dts,']'
                    except:
                        collected_dates.append(dts) ##(tdate)
                        ## print 'added ',line[5]
                        unique_data_points += 1
            except:
                fin.close()
                sys.stderr.write('\nError reading file '+rapid+' at line '+str(_line_)+'\n')
                raise NameError('fuck')
            _line_ += 1
        fin.close()
    except:
        sys.stderr.write('\nNo ultra-rapid file found'+rapid+'; skiping ...\n')
        pass

    ## return in list
    return min_date, max_date, avg_x, avg_y, avg_z, data_pts, unique_data_points

def main(argv):

    ## let getopt read in the argvs...
    try:
        opts, args = getopt.getopt(argv,"hs:", ["help", "station="])
    except getopt.GetoptError:
        sys.stderr.write('\nInvalid command line arguments!. Exiting ...\n')
        sys.exit(1)

    ## now get the options
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif opt in ('-s', '--station'):
            stations = arg.split(',')
        elif opt in ('-c', '--cts_version'):
            try:
                valid_ts_version.index(arg)
            except:
                sys.stderr.write('\nInvalid cts version! Can be 50 or 52. Exiting...\n')
                sys.exit(0)
            if arg=='52':
                print "Sorry can't handle version 52 yet ..."
                sys.exit(1)
            CTS_VERSION = arg
        elif opt in ('-g', '--geodetic'):
            global COORDINATES 
            COORDINATES = 'GEODETIC'
        else:
            sys.stderr.write('\nInvalid command line argument; skipping ...')

    ## what extensions are we looking for ?
    f_ext = C_FINAL_CTS_EXT if (COORDINATES=='CARTESIAN') else G_FINAL_CTS_EXT
    r_ext = C_RAPID_CTS_EXT if (COORDINATES=='CARTESIAN') else G_RAPID_CTS_EXT

    ## for every station in list
    for station in stations:
        ## Compile the file we are searching for
        f_ts_file = PATH_TO_STA + '/' + station + '/' + station + f_ext
        r_ts_file = PATH_TO_STA + '/' + station + '/' + station + r_ext
        ## Check that the file exists
        if not os.path.isfile(f_ts_file):
            sys.stderr.write('\nCannot find file: '+f_ts_file+'. Exiting ...\n')
            sys.exit(1)
        ## get the values we want ...
        try:
            min_date, max_date, avg_x, avg_y, avg_z, data_pts, unique_pts = read_c_file_50(f_ts_file,r_ts_file)
        except NameError:
            sys.stderr.write('\nError reading file '+f_ts_file+'. Exiting ...\n');
            sys.exit(1)
        ## print the results
        print "%4s %10.5f %10.5f %012.4f %012.4f %012.4f %05i %05i" %(station, min_date, max_date, avg_x, avg_y, avg_z, data_pts, unique_pts)

    if not len(stations):
        print 'Empty station list! Nothing to do ...'
        sys.exit(0)

if __name__ == "__main__":
    main(sys.argv[1:])

''' NOTES
the output file can be awk'ed to
$ cat koko | awk '{if($3>0){print $3-$2}}' > v3206.t
and ploted as histogram
$ gmt pshistogram v3206.t -Bxa1f0.5+l"Time Span in Years" \
        -Bya10f5+l"(Relative) Frequency"+u" %" -BWSne+t"Histogram"+glightblue \
        -W1 -Gorange -JX10.0i/5.0i -Z1 -L1p > koko.ps
'''
