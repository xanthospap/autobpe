#! /usr/bin/python

import bernutils.bcrd
import os, sys, shutil
import argparse

##  set the cmd parser
parser = argparse.ArgumentParser(
    description = 'Create a .CRD file using another (reference) .CRD file and'
                  'a .FIX file. Whichever station recorded in both the (reference) '
                  '.CRD file and the .FIX file is going to be printed in the '
                  'output .CRD file.',
    epilog      = 'Ntua, autobpe, 2016'
    )

parser.add_argument('-c', '--crd',
    action   = 'store',
    required = True,
    help     = 'The (reference) .CRD file.',
    metavar  = 'INPUT_CRD',
    dest     = 'crdin'
    )

parser.add_argument('-r', '--ref',
    action   = 'store',
    required = True,
    help     = 'The .FIX file.',
    metavar  = 'INPUT_FIX',
    dest     = 'fixin'
    )

parser.add_argument('-o', '--out',
    action   = 'store',
    required = True,
    help     = 'The output .CRD file.',
    metavar  = 'OUTPUT_CRD',
    dest     = 'crdout'
    )

##  Parse command line arguments
args = parser.parse_args()

##  Get the list of stations from the .FIX file
valid_stations = []

try:
    with open(args.fixin, 'r') as fixin:
        lines_after_5 = fixin.readlines()[5:]
        for line in lines_after_5:
            if len(line) >= 4:
                valid_stations.append(line[0:20].rstrip())

    shutil.copy(args.crdin, args.crdout)
    crdfile = bernutils.bcrd.CrdFile(args.crdout)
    crdfile.onlyKeep(valid_stations)
    crdfile.flush()
    exit_status = 0
except:
    exit_status = 1

sys.exit(exit_status)
