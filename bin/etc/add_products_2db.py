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
import sys, os
import datetime
import getopt
import glob
import MySQLdb
import traceback
import argparse

## globals
dtnow = datetime.datetime.now().strftime('%Y-%m-%d_%H:%M:%S')

satsys_dict = {
  'GPS'     : 'GPS',
  'GLO'     : 'GLONASS',
  'GPS+GLO' : 'GPS+GLO'
}

soltype_dict = {
  'DDFINAL'  : 'DDFINAL',
  'DDRAPID'  : 'DDRAPID',
  'DDURAPID' : 'DDURAPID',
  'PPP'      : 'PPP'
}

prodtype_dict = {
  'SINEX'    : 'SINEX',
  'NQ'       : 'NQ',
  'IONEX'    : 'IONEX',
  'ION'      : 'ION',
  'TRP_SNX'  : 'TRP_SINEX',
  'TRO_SNX'  : 'TRO_SINEX',
  'CRD_FILE' : 'CRD_FILE'
}

software_dict = {
  'BERN50' : 'BERN50',
  'BERN52' : 'BERN52',
  'GAMIT'  : 'GAMIT',
  'GIPSY'  : 'GIPSY',
  'NTUA'   : 'NTUA'
}

def to_datetime(date_str):
  ##  valid formats: %Y-%j_%H:%M:%S, or
  ##                 %Y-%m-%d_%H:%M:%S
  date_fields = len(date_str.split('-'))

  if date_fields != 2 and date_fields != 3:
    raise RuntimeError("Invalid input date [%s]"%date_str)

  try:
    if date_fields == 2:
      return datetime.datetime.strptime(date_str, "%Y-%j_%H:%M:%S")
    else:
      return datetime.datetime.strptime(date_str, "%Y-%m-%d_%H:%M:%S")
  except:
    raise RuntimeError("Invalid input date [%s]"%date_str)


##  set the cmd parser
parser = argparse.ArgumentParser(
    description='Update/Insert records in a given database concerning GNSS'
    'products',
    epilog ='Ntua - 2015'
    )

##  Name of the processed campaign
parser.add_argument('-c', '--campaign',
    action   = 'store',
    required = True,
    help     = 'The name of the processed campaign.',
    metavar  = 'CAMPAIGN',
    dest     = 'campaign'
    )

##  The satellite system of the product
parser.add_argument('-s', '--satellite-system',
    action   = 'store',
    required = True,
    help     = 'The satellite system of the product.',
    metavar  = 'SAT_SYS',
    choices  = list(satsys_dict.keys()),
    dest     = 'sat_sys'
    )

##  The solution type
parser.add_argument('-t', '--solution-type',
    action   = 'store',
    required = True,
    help     = 'The type of the solution.',
    metavar  = 'SOL_TYPE',
    choices  = list(soltype_dict.keys()),
    dest     = 'solution_type'
    )

##  The starting epoch in product
parser.add_argument('-f', '--start-epoch',
    action   = 'store',
    required = True,
    help     = 'The starting epoch (i.e. datetime) of the product. Date format'
    'is \'%Y-%j_%H:%M:%S\' or \'%Y-%j %H:%M:%S\',',
    metavar  = 'START_EPOCH',
    dest     = 'start_epoch'
    )

##  The last epoch in the product file
parser.add_argument('-l', '--stop-epoch',
    action   = 'store',
    required = True,
    help     = 'The last epoch (i.e. datetime) of the product. Date format'
    'is \'%Y-%j_%H:%M:%S\' or \'%Y-%j %H:%M:%S\',',
    metavar  = 'STOP_EPOCH',
    dest     = 'stop_epoch'
    )

##  The epoch the product file was produced
parser.add_argument('-a', '--produced-at',
    action   = 'store',
    required = False,
    help     = 'The epoch the product file was produced. Date format'
    'is \'%Y-%j_%H:%M:%S\' or \'%Y-%j %H:%M:%S\',',
    metavar  = 'PROC_EPOCH',
    dest     = 'proc_epoch',
    default  = dtnow
    )

##  The products filename
parser.add_argument('-n', '--filename',
    action   = 'store',
    required = True,
    help     = 'The product\'s filename.',
    metavar  = 'FILENAME',
    dest     = 'proc_filename'
    )

##  The product type
parser.add_argument('-p', '--product-type',
    action   = 'store',
    required = True,
    help     = 'The type of the product.',
    metavar  = 'PROD_TYPE',
    choices  = list(prodtype_dict.keys()),
    dest     = 'product_type'
    )

##  The  software used
parser.add_argument('-w', '--software',
    action   = 'store',
    required = True,
    help     = 'The software used.',
    metavar  = 'SOFTWARE',
    choices  = list(software_dict.keys()),
    dest     = 'software'
    )

##  The hostname where the product file will be saved
parser.add_argument('-o', '--save-host',
    action   = 'store',
    required = True,
    help     = 'The hostname where the product file will be saved.',
    metavar  = 'SAVE_HOST',
    dest     = 'save_host'
    )

##  The path to the product file
parser.add_argument('-r', '--save-dir',
    action   = 'store',
    required = True,
    help     = 'The directory (path) of the saved product file.',
    metavar  = 'SAVE_DIR',
    dest     = 'save_dir'
    )

##  The database host
parser.add_argument('--db-host',
    action   = 'store',
    required = True,
    help     = 'The database host (ip).',
    metavar  = 'DB_HOST',
    dest     = 'db_host'
    )

##  The database username
parser.add_argument('--db-user',
    action   = 'store',
    required = True,
    help     = 'The database user.',
    metavar  = 'DB_USER',
    dest     = 'db_user'
    )

##  The database password
parser.add_argument('--db-pass',
    action   = 'store',
    required = True,
    help     = 'The database password.',
    metavar  = 'DB_PASSWORD',
    dest     = 'db_pass'
    )

##  The database name
parser.add_argument('--db-name',
    action   = 'store',
    required = True,
    help     = 'The database name.',
    metavar  = 'DB_NAME',
    dest     = 'db_name'
    )

##  Parse command line arguments
args = parser.parse_args()

## Resolve command line arguments
product_type  = prodtype_dict[args.product_type]
software      = software_dict[args.software]
sat_sys       = satsys_dict[args.sat_sys]
solution_type = soltype_dict[args.solution_type]
try:
    d = args.start_epoch; start_epoch = to_datetime( d )
    d = args.stop_epoch ; stop_epoch  = to_datetime( d )
    d = args.proc_epoch ; proc_epoch  = to_datetime( d )
except:
    print >> sys.stderr, '[ERROR] Failed to parse date: \"%s\"'%(d)
    sys.exit( 1 )

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
  filename \
) \
VALUES ( \
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
  \"%s\" \
  );"%(args.campaign, software, sat_sys, solution_type, product_type, \
        proc_epoch.strftime("%Y-%m-%d %H:%M:%S"), \
        start_epoch.strftime("%Y-%m-%d %H:%M:%S"), \
        stop_epoch.strftime("%Y-%m-%d %H:%M:%S"), \
        args.save_host, args.save_dir, args.proc_filename)

## try connecting to the database server
try:
  db  = MySQLdb.connect( host   = args.db_host,
                         user   = args.db_user, 
                         passwd = args.db_pass, 
                         db     = args.db_name)
  cur = db.cursor()
  cur.execute(SQL_INSERT_CMD)
  db.commit()
  exit_status = 0
except:
  exit_status = 1
  print >>sys.stderr,'*** Stack Rewind:'
  exc_type, exc_value, exc_traceback = sys.exc_info()
  traceback.print_exception(exc_type, exc_value, exc_traceback, \
        limit=10, file=sys.stderr)
  print >>sys.stderr,'*** End'
  db.rollback()
  ## print SQL_INSERT_CMD

try   : db.close()
except: pass

sys.exit( exit_status )
