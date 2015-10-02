#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : rnx_dnwl.py
version               : v-0.5
created               : JUN-2015

usage                 : 

exit code(s)          : 0 -> success
                      : 1 -> error

description           :

notes                 :

TODO                  :
bugs & fixes          :
last update           :

report any bugs to    :
                      : Xanthos Papanikolaou xanthos@mail.ntua.gr
                      : Demitris Anastasiou  danast@mail.ntua.gr
'''

## Import libraries
import sys
import datetime
import getopt
import glob
import MySQLdb
import traceback

## Debug Mode
DDEBUG_MODE = True

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## globals
campaign    = None
sat_sys     = 'GPS'
sol_type    = None
prod_type   = None
start_epoch = None
stop_epoch  = None
proc_at     = datetime.datetime.now()
host_ip     = None
host_dir    = None
filename    = None
software    = 'BERN52'

satsys_dict = {
    'GPS': 'GPS',
    'GPS+GLO': 'GPS+GLO'
}

soltype_dict = {
    '': ''
}

prodtype_dict = {
    'SINEX': 'SINEX',
    'IONEX': 'IONEX',
    'TRO_SNX': '',
}

software_dict = {
    'BERN52': 'BERN52'
}

def to_datetime(date_str):
  ##  valid formats: %Y-%j_%H:%M:%S, or
  ##                 %Y-%m-%d_%H:%M:%S
  date_fields = len(date_str.split('-'))

  if date_fiels != 2 and date_fields != 3:
    raise RuntimeError("Invalid input date [%s]"%date_str)

  try:
    if date_fields == 2:
      return datetime.datetime.strptime(date_str, "%Y-%j_%H:%M:%S")
    else:
      return datetime.datetime.strptime(date_str, "%Y-%m-%d_%H:%M:%S")
  except:
    raise RuntimeError("Invalid input date [%s]"%date_str)
    

## Resolve command line arguments
def main (argv):

  try:
    opts, args = getopt.getopt(argv,'h',[
      'help','campaign-name=','sattellite-system=','solution-type=','product-type=','start-epoch=',
      'end-epoch=','processed-at=','host-ip=','host-dir=','product-filename=', 'software='])

  except getopt.GetoptError:
    raise RuntimeError("ERROR. Cannot parse options!")
    sys.exit(1)

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      help(0)

    elif opt in ('--campaign-name'):
      global campaign
      campaign = arg

    elif opt in ('--satellite-system'):
      global sat_sys
      try: 
        sat_sys = satsys_dict[arg.upper()]
      except:
        raise RuntimeError("Invalid satellite system [%s]"%arg)

    elif opt in ('--solution-type'):
      global sol_type
      try:
        sol_type = soltype_dict[arg.upper()]
      except:
        raise RuntimeError("Invalid solution type [%s]"%arg)

    elif opt in ('--product-type'):
      global prod_type
      try:
        prod_type = prodtype_dict[arg.upper()]
      except:
        raise RuntimeError("Invalid product type [%s]"%arg)

    elif opt in ('--start-epoch'):
      global start_epoch
      try:
        start_epoch = to_datetime(arg)
      except:
        raise

    elif opt in ('--end-epoch'):
      global stop_epoch
      try:
        stop_epoch = to_datetime(arg)
      except:
        raise

    elif opt in ('--processed-at'):
      global proc_at
      try:
        proc_at = to_datetime(arg)
      except:
        raise

    elif opt in ('--host-ip'):
      global host_ip
      host_ip = arg

    elif opt in ('--host-dir'):
      global host_dir
      host_dir = arg

    elif opt in ('--product-filename'):
      global filename
      filename = arg

    elif opt in ('--software'):
      global software
      try:
        software = software_dict[arg]
      except:
        raise RuntimeError("Invalid software [%s]"%arg)

    else:
      print >> sys.stderr,'[WARNING] Invalid command line argument: %s'%opt

## Start main
if __name__ == "__main__":
  try:
    main( sys.argv[1:] )
  except:
    print >>sys.stderr,'*** Stack Rewind:'
    exc_type, exc_value, exc_traceback = sys.exc_info()
    traceback.print_exception(exc_type, exc_value, exc_traceback, \
            limit=10, file=sys.stderr)
    print >>sys.stderr,'*** End'
    sys.exit(1)

for entry in [campaign, sat_sys, sol_type, prod_type, start_epoch, stop_epoch, \
        proc_at, host_ip, host_dir, filename]:
  if not entry:
    print >>sys.stderr, 'ERROR. Missing command line argument!'
    sys.exit(1)

SQL_INSERT_CMD = "INSERT INTO product \
(\
  network_id, \
  software_id, \
  satsys_id, \
  soltype_id, \
  prodtype_id, \
  date_process, \
  dateobs_start, \
  dateobs_stop, \
  host_name, \
  pth2dir, \
  filename, \
  prcomment\
)
VALUES (\
  (SELECT network_id FROM network WHERE network_name=\"%s\"), \
  (SELECT software_id FROM software WHERE software_name=\"%s\"), \
  (SELECT satsys_id FROM satsys WHERE satsys_name=\"%s\"), \
  (SELECT soltype_id FROM soltype WHERE soltype_name=\"%s\"), \
  (SELECT prodtype_id FROM prodtype WHERE prodtype_name=\"%s\"), \
  \"%s\", \
  \"%s\", \
  \"%s\", \
  \"%s\", \
  \"%s\", \
  \"%s\", \
  \"%s\" \
  );"%(campaign, software, sat_sys, sol_type, prod_type, \
        proc_at.strftime("%Y-%m-%d %H:%M:%S"), \
        start_epoch.strftime("%Y-%m-%d %H:%M:%S"), \
        stop_epoch.strftime("%Y-%m-%d %H:%M:%S"), \
        host_ip, host_dir, filename)

print SQL_INSERT_CMD

exit_status = 0
## try connecting to the database server
try:
  db  = MySQLdb.connect(host=DB_HOST, user=DB_USER, passwd=DB_PASSWORD, db=DB_NAME)
  cur = db.cursor()
  cur.execute(SQL_INSERT_CMD)
  db.commit()
except:
  exit_status = 1
  print >>sys.stderr,'*** Stack Rewind:'
  exc_type, exc_value, exc_traceback = sys.exc_info()
  traceback.print_exception(exc_type, exc_value, exc_traceback, \
        limit=10, file=sys.stderr)
  print >>sys.stderr,'*** End'
  db.rollback()

db.close()

sys.exit(exit_status)
