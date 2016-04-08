#! /usr/bin/python

##
##  This script will get as input two json files and merge them. It is only
##+ meant to be a part of ddprocess.sh, do not use as standalone!
##
##  Arguments:
##      sys.argv1 -> The json file containing station information, as outputed
##                   from validate_ntwrnx.py script.
##      sys.argv2 -> The json file containing all info from a run of ddprocess
##
##  Ouput:
##      A new file, 'bar.json' containing all info from both json files.
##
##  Exit Status:
##      Anything other than 0 denotes an error.
##

import json
import sys

status = 0

def find_station_in_addneq(name, d):
    for i in d:
        if name == i["name"]:
            return i
    return None

def station_is_reference(name, d):
    for i in d:
        if name == i["name"]:
            return True if i["adj"] == "HELMR" else False
    return False

try:
    with open('validate_rnx.json') as data_file:
        data   = json.load(data_file)

    with open('epndens.json') as solution_file:
        solinf = json.load(solution_file)

    adnq_sum = solinf["addneq_summary"]
    sta_inf  = {}

    for st in data:
        sta_name = st["station"]
        processed = "Yes" if find_station_in_addneq(sta_name, adnq_sum) else "No"
        reference = "Yes" if station_is_reference(sta_name, adnq_sum) else "No"
        st["processed"] = processed
        st["used_as_reference"] = reference

    solinf.update({"stainf":data})

    with open("bar.json", "w") as new_json:
        json.dump(solinf, new_json, indent=4)
except:
    status = 1

sys.exit(status)
