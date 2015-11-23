#! /usr/bin/python

##
##  This script will prepare thee run of the perl/Bernese PCF
##+ file ATX2PCV.PCF. Given the right command line arguments,
##+ it will:
##+ a. perform validation test (i.e. existance of files)
##+ b. prepare the PCF file, i.e. set the right variables
##+ c. prepare a bash-shell script to run the perl module (i.e.
##+    ntua_a2p.pl found in the ${U}/SCRIPT dir and check the
##+    output.
##  prepare_atx2pcv.py -h will provide further info and usage details.
##
##  all the best,
##+ xanthos
##

import argparse
import re
import os, sys
import shutil
import subprocess
import bernutils.bpcf

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
PCF_FILENAME = 'ATX2PCV.PCF'
PL_FILENAME  = 'ntua_a2p.pl'

##  Set the cmd parser.
parser = argparse.ArgumentParser(
    description='Convert an antex file to a Bernese-format .PCV file.',
    epilog='For this script to work, the user must have access to a'
    'working Bernese v5.2 installation. Additionaly, it is expected that:'
    '\n\t1. a PCF file named \'ATX2PCV.PCF\' exists in the ${U}/PCF dir,'
    '\n\t2. a perl program named \'ntua_a2p.pl\' exists in the ${U}/SCRIPT dir.'
    )

##  Input antex file
parser.add_argument('-a', '--antex',
    action='store',
    required=True,
    help='The input antex file (including path and extension)',
    metavar='ATXFILE',
    dest='antex_file'
    )

##  Input station information file
parser.add_argument('-s', '--sta',
    action='store',
    required=True,
    help='The input sta file (including path; extension is set to \'.STA\')',
    metavar='STAFILE',
    dest='sta_file'
    )

##  Name of the campaign
parser.add_argument('-c', '--campaign',
    action='store',
    required=True,
    help='The name of the campaign (should reside in the ${P} dir)',
    metavar='CAMPAIGN',
    dest='campaign'
    )

##  Input PCV file (optional)
parser.add_argument('-p', '--pcv',
    action='store',
    required=False,
    help='The input pcv file (including path and extension)',
    metavar='PCVFILE',
    dest='in_pcv_file'
    )

##  Ouput PCV file
parser.add_argument('-o', '--phg-out',
    action='store',
    required=True,
    help='The output pcv file (no path, no extension)',
    metavar='PHGFILE',
    dest='out_pcv_file'
    )

##  Satellite information file
parser.add_argument('-i', '--satinf',
    action='store',
    required=False,
    help='The satellite information file (no path, no extension)'
    'This file should be located in the ${X}/GEN directory. It\'s extension,'
    'is supplied via the -e/--ext argument (or set to the default value).'
    'Default value is \'SATELLIT\' .',
    default='SATELLIT',
    metavar='SATINFO',
    dest='sat_info_file'
    )

##  Calibration model
parser.add_argument('-m', '--calibration-type',
    action='store',
    required=False,
    help='The atx/pcv calibration model; used as the extension of the'
    'satellite information file (SATELLIT). Default value is \'I08\'',
    default='I08',
    choices=['I01', 'I08'],
    metavar='PCVEXT',
    dest='type_ext'
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

##  antex file:
##+ check that it exists
##+ link to the campaigns OUT dir
##+ mark for delete (if needed)
if not os.path.isfile( args.antex_file ):
    print >> sys.stderr, 'ERROR. Invalid antex file (%s)'%args.antex_file
    sys.exit(1)
antex_filename = os.path.basename( args.antex_file )
antex_src_dir  = os.path.dirname( os.path.abspath( args.antex_file ) )
symlink_source = os.path.join(antex_src_dir, antex_filename)
symlink_target = os.path.join(campaign_dir, 'OUT', antex_filename)
if symlink_source != symlink_target:
    ## if such file already exists, first move it
    if os.path.isfile( symlink_target ):
        shutil.move( symlink_target, symlink_target + '.bck' )
    os.symlink( symlink_source, symlink_target )
    files_to_delete.append( symlink_target )

##  .sta file:
##+ check that it exists
##+ link to the campaigns OUT dir (if neccesary)
##+ mark for delete (if needed)
if not os.path.isfile( args.sta_file + '.STA' ):
    print >> sys.stderr, 'ERROR. Invalid sta file (%s)'%( args.sta_file + '.STA' )
    sys.exit(1)
sta_filename   = os.path.basename( args.sta_file ) + '.STA'
sta_src_dir    = os.path.dirname( os.path.abspath( args.sta_file ) )
symlink_source = os.path.join(sta_src_dir, sta_filename )
symlink_target = os.path.join(campaign_dir, 'STA', sta_filename )
if symlink_source != symlink_target:
    ## if such file already exists, first move it
    if os.path.isfile( symlink_target ):
        shutil.move( symlink_target, symlink_target + '.bck' )
    os.symlink( symlink_source, symlink_target )
    files_to_delete.append( symlink_target )

##  input .pcv file (to be updated)
##+ check that it exists (default path is /GEN)
##+ if needed, link it to GEN dir
if args.in_pcv_file != None:
    if not os.path.isfile( args.in_pcv_file ):
        print >> sys.stderr, 'ERROR. Invalid input pcv file (%s)'%( args.in_pcv_file )
        sys.exit(1)
    in_pcv_filename = os.path.basename( args.in_pcv_file )
    in_pcv_dir      = os.path.dirname( os.path.abspath( args.in_pcv_file ) )
    if in_pcv_dir  != os.path.join(bv['X'], 'GEN'):
        symlink_source = os.path.join( in_pcv_dir, in_pcv_filename )
        symlink_target = os.path.join(bv['X'], 'GEN', in_pcv_filename)
        os.symlink( symlink_source, symlink_target )
        files_to_delete.append( symlink_target )
else:
    in_pcv_filename = ''

##  check that the satellite information file exists
satellite_info_file = os.path.join( bv['X'], 'GEN',
    args.sat_info_file + '.' + args.type_ext )
if not os.path.isfile( satellite_info_file ):
    print >> sys.stderr, 'ERROR. Invalid satellite info file (%s)'%satellite_info_file
    sys.exit(1)

##  the output pcv file should only be a filename
if args.out_pcv_file != os.path.basename( args.out_pcv_file ):
    print >> sys.stderr, \
    'ERROR. Only provide a filename for the resulting pcv; no path (%s)'%satellite_info_file
    sys.exit(1)

##  set the variables in the PCF file
pcf_file = os.path.join( bv['U'], 'PCF', PCF_FILENAME )
if not os.path.isfile( pcf_file ):
    print >> sys.stderr, 'ERROR. Invalid pcf file (%s)'%pcf_file
    sys.exit(1)
pcf_inst = bernutils.bpcf.PcfFile( pcf_file )
pcf_inst.set_variable(var_name='ATXINF', val=antex_filename)
## no extension in .sta !
sta_filename_noext = os.path.splitext( sta_filename )[0]
pcf_inst.set_variable(var_name='STAINF', val=sta_filename_noext)
pcf_inst.set_variable(var_name='SATINF', val=args.sat_info_file)
pcf_inst.set_variable(var_name='PCVINF', val=in_pcv_filename)
pcf_inst.set_variable(var_name='PCV',    val=args.type_ext)
pcf_inst.set_variable(var_name='PHGINF', val=args.out_pcv_file)
pcf_inst.flush_variables()

##  ok, now call the perl script, that actually call atx2pcv ...
perl_script = os.path.join( bv['U'], 'SCRIPT', PL_FILENAME )
if not os.path.isfile( perl_script ):
    print >> sys.stderr, 'ERROR. Invalid pl file (%s)'%perl_script
    sys.exit(1)

sys_command_1 = 'source %s'%(args.loadgps)
year          = 2015
doy           = 1
session       = 0
sys_command_2 = '%s %04i %03i%01i %s'%(perl_script, year, doy, session, args.campaign)

if args.verbosity_level < 2: sys_command_2 += ' 1>/dev/null'
if args.verbosity_level < 1: sys_command_2 += ' 2>/dev/null'

if args.shell_script is not None:
    if year >= 2000 : yr2 = year - 2000
    else            : yr2 = year - 1900
    bpe_dir = os.path.join(campaign_dir, 'BPE')
    log_proc= os.path.join(bpe_dir, 'BPE', 'AP%02i%03i%01i_001_000.LOG'%(yr2, doy, session))
    phg_out = os.path.join(campaign_dir, 'OUT', args.out_pcv_file + '.PHG')
    phg_gen = os.path.join(bv['X'], 'GEN', args.out_pcv_file + '.' + args.type_ext)
    with open( args.shell_script, 'w' ) as fout:
        print >> fout, '#! /bin/bash'
        print >> fout, '## script automatically generated by prepare_atx2pcv.py'
        print >> fout, '%s'%(sys_command_1)
        print >> fout, '%s'%(sys_command_2)
        print >> fout, 'if grep ERROR %s 1>/dev/null; then'%(os.path.join(bpe_dir, 'ATX2PCV.RUN'))
        print >> fout, '\techo \'[ERROR] Could not transform the atx file!\' 1>&2'
        print >> fout, '\techo \'        Check the log file \"%s\" for details.\' 1>&2'%(log_proc)
        print >> fout, '\techo \'[INFO] error found at file: %s\''%(os.path.join(bpe_dir, 'ATX2PCV.RUN'))
        print >> fout, '\tcat %s 1>&2'%(log_proc)
        print >> fout, '\texit 1'
        print >> fout, 'fi'
        print >> fout, '#if grep ERROR %s 1>/dev/null; then'%(os.path.join(bpe_dir, 'ATX2PCV.OUT'))
        print >> fout, '#\techo \'ERROR. Could not transform the atx file!\' 1>&2'
        print >> fout, '#\tcat %s 1>&2'%(log_proc)
        print >> fout, '#\texit 1'
        print >> fout, '#fi'
        print >> fout, 'if ! test -f %s ; then'%(phg_out)
        print >> fout, '\techo \'[ERROR] Could not transform the atx file!\' 1>&2'
        print >> fout, '\techo \'        Check the log file \"%s\" for details.\' 1>&2'%(log_proc)
        print >> fout, '\techo \'[INFO] produced file seems empty: %s\''%(phg_out)
        print >> fout, '\texit 1'
        print >> fout, 'else'
        print >> fout, '\tln -sf %s %s'%(phg_out, phg_gen)
        if args.verbosity_level > 0:
            print >> fout, '\techo \'[DEBUG] PCV file %s created as %s.\''%(args.out_pcv_file, phg_out)
            print >> fout, '\techo \'[DEBUG] PCV file linked to %s\''%(phg_gen)
        print >> fout, 'fi'
        for rmf in files_to_delete: print >> fout, 'rm %s'%(rmf)
        print >> fout, 'exit 0'

else:
    print sys_command_1
    print sys_command_2

sys.exit( 0 )
