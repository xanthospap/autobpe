#! /usr/bin/python

'''
 
 |===========================================|
 |** Higher Geodesy Laboratory             **|
 |** Dionysos Satellite Observatory        **| 
 |** National Tecnical University of Athens**|
 |===========================================|

 filename              : make_GNSS_data_file.py
 version               : v-1.3
 created               : FEB-2014

 usage                 : Python routine to create a MySQL batch file for populating the table
                         gnss_data_file for a prototype GSAC MySQL database.

 exit code(s)          : 0 -> success
                       : 1 -> error (command line arguments)
                       : 2 -> database server error
                       : 3 -> root directory not found

 description           : Python routine to create a MySQL batch file for populating the table gnss_data_file
                       : for a prototype GSAC MySQL database.
                       : Given a root directory, it will search through all its subforlders named as YEAR/DOY
                       : between given dates and print MySQL commands for inserting the resolved values.
                       : E.g. if you run as: $ make_GNSS_data_file -d /foo/bar/ -t 1980-01-01 -s 2014-01-01
                       : the routine will search all subfolders named as:
                       : /foo/bar/1980/001, /foo/bar/1980/002, [...], /foo/bar/2013/365, /foo/bar/2014/001
                       : and write an insert command for all files found therein. The type of files the
                       : script will search for, are descibed at (or near line 144), e.g.
                       : obsrin  = "????" + doy + "0." + year2 + "d.Z"; file_list.append (obsrin); file_types.append ("RINEX observation file");
                       : User can easily add a new type, using UNIX-like wildcards, by copying the this line. For
                       : an sql to be written, the file type must exist in the column file_type.file_type_name
                       : (as is "RINEX observation file"). User must also change the MySQL connection options
                       : (at or near line 124) db = MySQLdb.connect(host="147.102.110.73",user="bpe",passwd="koko",db="gsac_ntua");
                       : to correspond to a valid sql server/database.
                       : The SQL command formed, has values for the fields:
                       : station_id,file_type_id,file_sample_interval,data_start_time,data_stop_time,data_year,data_day_of_year,published_date,
                       : file_size,file_MD5,file_url_protocol,file_url_ip_domain,file_url_folders,file_url_filename,access_permission_id

 notes                 : publish_date set to data_stop_time

 TODO                  :
 bugs & fixes          :
 last update           : May-2015

 report any bugs to    :
                       : Xanthos Papanikolaou xanthos@mail.ntua.gr
                       : Demitris Anastasiou  danast@mail.ntua.gr
 tested on             : Linux (OpenSUSE, Ubuntu, Debian)
                       : FreeBSD
'''

# import libraries
import sys
import os
import datetime
import subprocess
import getopt
import glob
import MySQLdb
import traceback

# help function
def help (i):
  print ""
  print "make_GNSS_data_file.py,  v-1.0"
  print ""
  print "Python routine to create a MySQL batch file for populating the table"
  print "gnss_data_file for a prototype GSAC MySQL database."
  print ""
  print "Command ine arguments: "
  print "  [-d --rootdir=] provide root directory for file checking. E.g. if"
  print "  -d /foo/bar/ or --rootdir=/foo/bar/ then the routine will search all subfolders"
  print "  named as /foo/bar/{4-digit-year}/{3-digit-day-of-year}"
  print "  [-t --startdate=] provide the start date for file searching, as YYYY-MM-DD or today"
  print "  e.g. -t 2013-3-25 or --startdate=2013-3-25 the routine will search all subfolders"
  print "  {rootdir}/{4-digit-year}/{3-digit-day-of-year} with dates larger that startdate."
  print "  [-s --stopdate=] provide the stop date for file searching, as YYYY-MM-DD or today"
  print "  [-p --access-permission-id=] provide the access permission id for the files searched for"
  print "  [-g --stations] provide a list of stations sepereated only by comma"
  print ""
  print "For more information see the description block at the begining of the file"
  print ""
  sys.exit (i);

# global variables / default values
rootdir = ""
startdate = datetime.date (1980, 1, 1);
stopdate  = datetime.datetime.now().date();
delta     = datetime.timedelta(days=1)
access_permission_id = 3
file_sample = 30.0
file_url_protocol = "ftp"
file_url_ip_domain = "147.102.110.69"
station_list = []

# a dictionary to hold start time (hours) for every session character
ses_identifiers = {
        'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4, 'f': 5, 'g': 6,
        'h': 7, 'i': 8, 'j': 9,'k': 10, 'l':11, 'm': 12, 'n': 13,
        'o': 14, 'p': 15, 'q': 16, 'r': 17, 's': 18, 't':19, 'u': 20, 
        'v': 21, 'w': 22,'x': 23
        }

# resolve command line variables
def main (argv):
  if len (argv) < 1:
    help (1)
  try:
    opts, args = getopt.getopt (argv,"hd:t:s:p:g:",["rootdir=","startdate=","stopdate=","access-permission-id","stations"])
  except getopt.GetoptError:
    help (1)
  for opt, arg in opts:
    if opt == '-h':
      help (0)
    elif opt in ("-d", "--rootdir"):
      global rootdir
      rootdir = arg
    elif opt in ("-t", "--startdate"):
      global startdate
      try:
        startdate = datetime.datetime.strptime (arg,"%Y-%m-%d")
        ## startdate = startdate.date ()
      except:
        try:
          if arg == "today":
            startdate = datetime.datetime.today ();
          else:
            print "***ERROR! Could not resolve date from string:",arg
            sys.exit (1)
        except:
          print "***ERROR! Could not resolve date from string:",arg
          sys.exit (1)
    elif opt in ("-s", "--stopdate"):
      global stopdate
      try:
        stopdate = datetime.datetime.strptime(arg,"%Y-%m-%d")
        stopdate = stopdate.date ()
      except:
        try:
          if arg == "today":
            stopdate = datetime.datetime.today ();
          else:
            print "***ERROR! Could not resolve date from string:",arg
            sys.exit (1)
        except:
          print "***ERROR! Could not resolve date from string:",arg
          sys.exit (1)
    elif opt in ("-p", "--access-permission-id"):
      global access_permission_id
      try:
        access_permission_id = int (arg)
      except:
        print "***ERROR! Access permission id must be an integer"
        sys.exit (1)
    elif opt in ("-g", "--stations"):
      global station_list
      try:
        station_list = arg.split (',')
      except:
        print "***ERROR! Could not extract sations from string :",arg
        sys.exit (1)
    else:
      print "Invalid command line argument:",opt

# start main
if __name__ == "__main__":
  main (sys.argv[1:])

# remove last "/" in rootdir (if any)
if rootdir[-1] == "/":
  rootdir = rootdir[:-1]

# try connecting to the database server
try:
  db = MySQLdb.connect(host="147.102.110.73",user="bpe2",passwd="webadmin",db="gsac15");
  cur = db.cursor ()
except:
  print "***ERROR ! Cannot connect to database server"
  sys.exit (2)

# make sure the root directory exists
if rootdir == ' ' or not os.path.isdir (rootdir) :
  print "ERROR (!!) Directory "+rootdir+" does not exist!"
  sys.exit (3);

# compare types of startdate and stopdate
# print type(startdate)
# print type(stopdate)
if not ( type(startdate) is type(stopdate) ):
    print "ERROR (!!) Start and stop variables are of different type"
    sys.exit(3)

# loop through all subdirs of the rootdir with names {rootdir}/{4-digit-year}/{3-digit-day-of-year}
# starting from startdate while date smaller or equal to stopdate
while True:
  doy    = startdate.strftime('%j')
  year4  = startdate.strftime('%Y')
  year2  = startdate.strftime('%y')
  # list of files to resolve and their respective file_type_name (as in table file_type)
  file_list = []
  file_types = []
  # NOTE: a wildcard at the end of an obsrin file will also allow rinex files compressed as ????DDDS.YRd.bz2. Comment this line out
  # to only allow RINEx files compressed as ????DDDS.YRd.Z
  obsrin    = "????" + doy + "?." + year2 + "d.*"; file_list.append (obsrin); file_types.append ("GNSS observation file");
  #obsrin    = "????" + doy + "0." + year2 + "d.Z"; file_list.append (obsrin); file_types.append ("RINEX observation file");
  navrin    = "????" + doy + "0." + year2 + "n.Z"; file_list.append (navrin); file_types.append ("GPS navigation file");
  metrin    = "????" + doy + "0." + year2 + "m.Z"; file_list.append (metrin); file_types.append ("GNSS meteorology file");
  gnavrin   = "????" + doy + "0." + year2 + "g.Z"; file_list.append (gnavrin); file_types.append ("GLONASS navigation file");
  # loop through all file types
  for (day_file,file_type) in zip (file_list,file_types):
    # compile the filename (with path), wildcards allowed
    file = rootdir + "/" + year4 + "/" + doy + "/" + day_file
    # get a list of all files matching the description
    c_file_list = glob.glob (file)
    # for every file matching the description
    for s_day_file in c_file_list:
      # basename is the filename (no path)
      basename = s_day_file[s_day_file.rfind("/")+1:len(s_day_file)]
      # station name is the 4 first chars of the basename
      station_name = basename[0:4];
      # session identifier
      session_identifier = basename[7]
      # whatch out for hourly rinex files !
      if session_identifier == "0" :
          start_HHMMSEC = "00:00:00"
          stop_HHMMSEC = "23:59:30"
          sampling_rate = 30
      elif session_identifier.isalpha() :
          if not session_identifier in ses_identifiers :
              print 'ERROR! Invalid session identifier ['+session_identifier+'] for file: '+s_day_file
              sys.exit (1)
          start_h = ses_identifiers[session_identifier]
          start_HHMMSEC = "%02i:00:00" %start_h
          stop_HHMMSEC = "%02i:59:59" %start_h
          sampling_rate = 1
      else :
          print 'ERROR! Invalid session identifier ['+session_identifier+'] for file: '+s_day_file
          sys.exit (1)
      try:
          f_start_date = datetime.datetime.strptime(year4+"-"+doy+"-"+start_HHMMSEC, "%Y-%j-%H:%M:%S")
          f_stop_date  = datetime.datetime.strptime(year4+"-"+doy+"-"+stop_HHMMSEC, "%Y-%j-%H:%M:%S")
      except:
          print 'ERROR! Cannot compile start/stop dates from strings: ['+year4+'-'+doy+'-'+start_HHMMSEC+'] or ['+year4+'-'+doy+'-'+stop_HHMMSEC+']'
          sys.exit(1)
      if len (station_list) == 0 or station_name in station_list:
	      # form the query (ask for id of station name)
	      query = 'SELECT station_id  FROM station where four_char_name = "%s" ;' % (station_name)
	      # ask the database for station_id matching the station name (code_4char_ID)
	      try:
	        cur.execute (query)
	        db_station_id = cur.fetchall()[0][0]
	        # database answered; form the query (ask for id of file_type_id)
	        try:
	          # ask the database for file_type_id matching the file_type
	          query = 'SELECT data_type_id  FROM data_type where data_type_name = "%s" ;' % (file_type)
	          cur.execute (query)
	          db_file_type_id = cur.fetchall()[0][0]
	          # database answered; get file information (size)
	          size = os.path.getsize (s_day_file);
	          # get file information (md5 checksum); system subprocess
	          process = subprocess.Popen(("md5sum %s" %s_day_file).split(), stdout=subprocess.PIPE)
	          md5s = process.communicate()[0];
                  # check if the file already exists
                  query = 'SELECT datafile_name FROM datafile WHERE datafile.station_id= "%s" and datafile.data_type_id = "%s" and datafile.datafile_start_time>="%s" and datafile.datafile_stop_time<="%s";'%(str(db_station_id),str(db_file_type_id),f_start_date.strftime('%Y-%m-%d %H:%M:%S'),f_stop_date.strftime('%Y-%m-%d %H:%M:%S'))
                  cur.execute (query)
                  try: existing_file = cur.fetchall()[0][0]
                  except: existing_file = ''
                  if existing_file == basename:
                    print '# File',existing_file,'already available; not updating'
                  else:
	            # print information in SQL syntax
	            print ( "insert into datafile (station_id,data_type_id,datafile_format_id,sample_interval,datafile_start_time,datafile_stop_time,year,day_of_year,datafile_published_date,size_bytes,MD5,URL_protocol,URL_domain,URL_path_dirs,datafile_name,URL_complete) values (" +
	             str(db_station_id) + "," +
	             str(db_file_type_id) + "," +
		     "1" + "," +
	             str(sampling_rate) + "," +
                 "\"" + f_start_date.strftime('%Y-%m-%d %H:%M:%S') + "\"," +
                 "\"" + f_stop_date.strftime('%Y-%m-%d %H:%M:%S') + "\"," +
	             year4 + "," +
	             doy + "," +
	             "\"" + startdate.strftime('%Y-%m-%d 23:59:30') + "\"," +
	             str(size) + "," +
	             "\"" + md5s.split()[0] + "\"," +
	             "\"" + file_url_protocol + "\"," +
	             "\"" + file_url_ip_domain + "\"," +
	             # "\"" + rootdir + "/" + year4 + "/" + doy + "/" + "\"," +
                     "\"/" + year4 + "/" + doy + "/" + "\"," +
	             "\"" + basename + "\"," +
		     "\"" + file_url_protocol + "://" + file_url_ip_domain + "/" + year4 + "/" + doy + "/" + basename + "\"" ");" )
	        except:
	          print "# File type: ["+file_type+"] not found in database"
	          #exc_type, exc_value, exc_traceback = sys.exc_info ()
	          #lines = traceback.format_exception (exc_type, exc_value, exc_traceback)
	          #print ''.join('!!#' + line for line in lines)
              except:
        	print "# Station ["+station_name+"] not found in database"
	        #exc_type, exc_value, exc_traceback = sys.exc_info ()
	        #lines = traceback.format_exception (exc_type, exc_value, exc_traceback)
	        #print ''.join('!!#' + line for line in lines)
      else:
        print "# rejected station:",station_name
  startdate += delta;
  if startdate > stopdate :
    break;
  # sys.exit (0)
	
sys.exit (0)
