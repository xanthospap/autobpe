#! /usr/bin/python

##
##  This script will prepare thee run of the perl/Bernese PCF
##+ file STAMRG.PCF. Given the right command line arguments,
##+ it will:
##+ a. perform validation test (i.e. existance of files)
##+ b. prepare the PCF file, i.e. set the right variables
##+ c. prepare a bash-shell script to run the perl module (i.e.
##+    ntua_a2p.pl found in the ${U}/SCRIPT dir and check the
##+    output.
##  prepare_stamrg.py -h will provide further info and usage details.
##
##  all the best,
##+ xanthos
##

import argparse
import re
import os, sys
import shutil
import subprocess
import datetime
import bernutils.bpcf

def vprint( message, min_verb_level, std_buf=None ):
    if std_buf is None : std_buf = sys.stdout
    if args.verbosity_level >= min_verb_level: print >> std_buf, message

def resolve_loadvar( gpsloadvar ):
#''' Given a Bernese LOADGPS.setvar file, this function will return all
#    exported variables in a dictionary; this dictionary will be returned.
#'''
    var_dict = {}
    with open( gpsloadvar ) as fin:
        for line in fin.readlines():
            ln_lst = line.split()
            if ln_lst and ln_lst[0] == 'export':
                ln2_lst = ln_lst[1].split('=')
                var_dict[ln2_lst[0]] = ln2_lst[1].strip('\"')
    return var_dict

def resolve_bern_var_dict( bern_dict ):
    bern_dict['HOME'] = os.environ['HOME'] ## add home variable
    del bern_dict['PATH']                  ## delete the PATH variable
    b_regex = re.compile('.*(\${.*}).*')
    for key, val in bern_dict.iteritems():
        mtch = b_regex.match( val )
        iteration=0
        while mtch:
            val = val.replace( mtch.group(1), 
                bern_dict[mtch.group(1).lstrip('${').rstrip('}')] )
            mtch = b_regex.match( val )
            iteration+=1
            if iteration > 10:
                print>>sys.stderr,'ERROR. Cannot resolce variable:',key, pair
                sys.exit(1)
        bern_dict[key] = val
    return bern_dict

##  globals                                     ##
## -------------------------------------------- ##
PCF_FILENAME = 'STAMRG.PCF'
PL_FILENAME  = 'ntua_stamrg.pl'

##  Set the cmd parser.
parser = argparse.ArgumentParser(
    description='Merge two .STA files.',
    epilog='For this script to work, the user must have access to a'
    'working Bernese v5.2 installation. Additionaly, it is expected that:'
    '\n\t1. a PCF file named \'STAMRG.PCF\' exists in the ${U}/PCF dir,'
    '\n\t2. a perl program named \'ntua_stamrg.pl\' exists in the ${U}/SCRIPT dir.'
    )

##  Master STA file
parser.add_argument('-m', '--master-sta',
    action='store',
    required=True,
    help='The master .sta file.',
    metavar='MASTER_STA',
    dest='master_sta'
    )

##  Secondary STA file
parser.add_argument('-s', '--secondary-sta',
    action='store',
    required=True,
    help='The secondary sta file.',
    metavar='STAFILE',
    dest='secondary_sta'
    )

##  Name of the campaign
parser.add_argument('-c', '--campaign',
    action='store',
    required=True,
    help='The name of the campaign (should reside in the ${P} dir)',
    metavar='CAMPAIGN',
    dest='campaign'
    )

##  Ouput STA file
parser.add_argument('-o', '--sta-out',
    action='store',
    required=True,
    help='The output sta file (no path, no extension)',
    metavar='OUTPUT_STA',
    dest='output_sta'
    )

##  The .FIX file 
parser.add_argument('-f', '--fix-file',
    action='store',
    required=False,
    help='An input .FIX file; if such a file is provided, only those stations'
    'recorded in this will will be written to the output.STA file.',
    default='',
    metavar='FIXFILE',
    dest='fix_file'
    )

## The year 
parser.add_argument('-y', '--year',
    action='store',
    required=False,
    type=int,
    help='The year',
    default=datetime.datetime.now().year,
    metavar='YEAR',
    dest='year'
    )

## The day of year 
parser.add_argument('-d', '--doy',
    action='store',
    required=False,
    type=int,
    help='The day of year',
    default=int(datetime.datetime.now().strftime('%j')),
    metavar='DOY',
    dest='doy'
    )

##  The LOADGPS.setvar file
parser.add_argument('-b', '--loadgps',
    action='store',
    required=True,
    help='The Bernese variables file, i.e. \'LOADGPS.setvar\'. This is usually'
    'located in the ${X}\EXE directory.',
    metavar='LOADGPS',
    dest='loadgps'
    )

##  create bash script or write to stdout
parser.add_argument('--shell-script',
    action='store',
    required=False,
    help='If this switch is specified, then a bash shell script will be created'
    'with the commands to actually run ATX2PCV.PCF. Else, it will be written'
    'to stdout.',
    metavar='SHELL_SCRIPT',
    dest='shell_script'
    )

##  Verbosity level
parser.add_argument('-v', '--verbose',
    action='store',
    type=int,
    default=0,
    required=False,
    help='Specify the verbosity level: \n\t0 output only vutal messages'
    '\n\t1 Output minimum info \n\t2 Output all info.',
    metavar='VERBOSITY',
    choices=[0, 1, 2],
    dest='verbosity_level'
    )

files_to_delete = []

##  Parse command line arguments
args = parser.parse_args()

##  get a dictionary with all Bernese variables.
bern_vars = resolve_loadvar( args.loadgps )

##  get a dictionary of the resolved bernese variables
##+ bernese variables should now be accessible via e.g.
##+ bv[P] for ${P}.
bv = resolve_bern_var_dict( bern_vars )

##  campaign:
##  check that campaign exists
campaign_dir = os.path.join( bv['P'], args.campaign )
if not os.path.isdir( campaign_dir ):
    print >> sys.stderr, 'ERROR. Invalid campaign (%s)'%campaign_dir
    sys.exit(1)

##  Resolve the date
dt      = datetime.datetime.strptime('%04i-%03i'%(args.year, args.doy), '%Y-%j')
year    = int( dt.strftime('%Y') )
doy     = int( dt.strftime('%j') )
session = 0

##  master sta file:
##+ check that it exists
##+ link to the campaigns STA dir
##+ mark for delete (if needed)
if not os.path.isfile( args.master_sta ):
    print >> sys.stderr, 'ERROR. Invalid sta file (\'%s\')'%args.master_sta
    sys.exit(1)
master_sta_filename = os.path.basename( args.master_sta )
master_sta_src_dir  = os.path.dirname( os.path.abspath( args.master_sta ) )
symlink_source = os.path.join(master_sta_src_dir, master_sta_filename)
symlink_target = os.path.join(campaign_dir, 'STA', master_sta_filename)
if symlink_source != symlink_target:
    ## if such file already exists, first move it
    if os.path.isfile( symlink_target ):
        vprint('[DEBUG] Moving old STA file \"%s\" to \"%s\"'%(symlink_target, symlink_target + '.bck'), 2, sys.stdout)
        shutil.move( symlink_target, symlink_target + '.bck' )
    vprint('[DEBUG] Creating link: \"%s\" -> \"%s\"'%(symlink_source, symlink_target), 2)
    os.symlink( symlink_source, symlink_target )
    files_to_delete.append( symlink_target )

##  secondary sta file:
##+ check that it exists
##+ link to the campaigns STA dir
##+ mark for delete (if needed)
if not os.path.isfile( args.secondary_sta ):
    print >> sys.stderr, 'ERROR. Invalid sta file (\'%s\')'%args.secondary_sta
    sys.exit(1)
secondary_sta_filename = os.path.basename( args.secondary_sta )
secondary_sta_src_dir  = os.path.dirname( os.path.abspath( args.secondary_sta ) )
symlink_source = os.path.join(secondary_sta_src_dir, secondary_sta_filename)
symlink_target = os.path.join(campaign_dir, 'STA', secondary_sta_filename)
if symlink_source != symlink_target:
    ## if such file already exists, first move it
    if os.path.isfile( symlink_target ):
        vprint('[DEBUG] Moving old STA file \"%s\" to \"%s\"'%(symlink_target, symlink_target + '.bck'), 2, sys.stdout)
        shutil.move( symlink_target, symlink_target + '.bck' )
    vprint('[DEBUG] Creating link: \"%s\" -> \"%s\"'%(symlink_source, symlink_target), 2)
    os.symlink( symlink_source, symlink_target )
    files_to_delete.append( symlink_target )

##  Input .fix file (if any)
##+ check that it exists
##+ if needed, link it to STA dir
if args.fix_file != '':
    if not os.path.isfile( args.fix_file ):
        print >> sys.stderr, 'ERROR. Invalid input fix file (%s)'%( args.fix_file )
        sys.exit(1)
    fix_filename = os.path.basename( args.fix_file )
    fix_dir      = os.path.dirname( os.path.abspath( args.fix_file ) )
    if fix_dir  != os.path.join(bv['P'], 'STA'):
        symlink_source = os.path.join( fix_dir, fix_filename )
        symlink_target = os.path.join(bv['P'], 'STA', fix_filename)
        vprint('[DEBUG] Creating link: \"%s\" -> \"%s\"'%(symlink_source, symlink_target), 2)
        os.symlink( symlink_source, symlink_target )
        files_to_delete.append( symlink_target )
else:
    fix_filename = ''

##  the output sta file should only be a filename
if args.output_sta != os.path.basename( args.output_sta ):
    print >> sys.stderr, \
    'ERROR. Only provide a filename for the resulting sta; no path (%s)'%args.output_sta
    sys.exit(1)
output_sta = re.sub('.STA', '', args.output_sta, flags=re.IGNORECASE)

##  set the variables in the PCF file
pcf_file = os.path.join( bv['U'], 'PCF', PCF_FILENAME )
if not os.path.isfile( pcf_file ):
    print >> sys.stderr, 'ERROR. Invalid pcf file (%s)'%pcf_file
    sys.exit(1)
pcf_inst = bernutils.bpcf.PcfFile( pcf_file )
pcf_inst.set_variable(var_name='MASSTA', val=re.sub('.STA', '', master_sta_filename, flags=re.IGNORECASE))
pcf_inst.set_variable(var_name='SECSTA', val=re.sub('.STA', '', secondary_sta_filename, flags=re.IGNORECASE))
pcf_inst.set_variable(var_name='OUTSTA', val=output_sta)
pcf_inst.set_variable(var_name='FIXINF', val=fix_filename)
pcf_inst.flush_variables()

##  ok, now call the perl script, that actually call stamrg ...
perl_script = os.path.join( bv['U'], 'SCRIPT', PL_FILENAME )
if not os.path.isfile( perl_script ):
    print >> sys.stderr, 'ERROR. Invalid pl file (%s)'%perl_script
    sys.exit(1)

sys_command_1 = 'source %s'%(args.loadgps)
sys_command_2 = '%s %04i %03i%01i %s'%(perl_script, year, doy, session, args.campaign)

if args.verbosity_level < 2: sys_command_2 += ' 1>/dev/null'
if args.verbosity_level < 1: sys_command_2 += ' 2>/dev/null'

if args.shell_script is not None:
    if year >= 2000 : yr2 = year - 2000
    else            : yr2 = year - 1900
    bpe_dir = os.path.join(campaign_dir, 'BPE')
    log_proc= os.path.join(bpe_dir, 'SM%02i%03i%01i_001_000.LOG'%(yr2, doy, session))
    sta_out = os.path.join(campaign_dir, 'STA',  output_sta + '.STA')
    with open( args.shell_script, 'w' ) as fout:
        print >> fout, '#! /bin/bash'
        print >> fout, '## script automatically generated by prepare_stamrg.py'
        print >> fout, '%s'%(sys_command_1)
        print >> fout, '%s'%(sys_command_2)
        print >> fout, 'if grep ERROR %s 1>/dev/null; then'%(os.path.join(bpe_dir, 'STAMRG.RUN'))
        print >> fout, '\techo \'[ERROR] Could not merge the sta files!\' 1>&2'
        print >> fout, '\techo \'        Check the log file \'%s\' for details\' 1>&2'%(log_proc)    
        print >> fout, '\techo \'[INFO] error found at file: %s\''%(os.path.join(bpe_dir, 'STAMRG.RUN'))
        print >> fout, '\tcat %s 1>&2'%(log_proc)
        print >> fout, '\texit 1'
        print >> fout, 'fi'
        print >> fout, '#if grep ERROR %s 1>/dev/null; then'%(os.path.join(bpe_dir, 'STAMRG.OUT'))
        print >> fout, '#\techo \'ERROR. Could not merge the sta files!\' 1>&2'
        print >> fout, '#\tcat %s 1>&2'%(log_proc)
        print >> fout, '#\texit 1'
        print >> fout, '#fi'
        print >> fout, 'if ! test -f %s ; then'%(sta_out)
        print >> fout, '\techo \'ERROR. Could not merge the sta files!\' 1>&2'
        print >> fout, '\techo \'       Check the log file \'%s\' for details\' 1>&2'%(log_proc)
        print >> fout, '\techo \'[INFO] produced file seems empty: %s\''%(sta_out)
        print >> fout, '\texit 1'
        print >> fout, 'else'
        if args.verbosity_level > 0:
            print >> fout, '\techo \'[DEBUG] STA file created as %s.\''%(sta_out)
        else:
            print >> fout, '\t:'
        print >> fout, 'fi'
        for rmf in files_to_delete: print >> fout, 'rm %s'%(rmf)
        if args.verbosity_level > 1:
            for rmf in files_to_delete: print >> fout, 'echo \"[DEBUG] Removed file %s\"'%(rmf)
        print >> fout, 'exit 0'

else:
    print sys_command_1
    print sys_command_2

sys.exit( 0 )
