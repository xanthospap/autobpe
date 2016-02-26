#! /usr/bin/python

import sys
import datetime
import bernutils.bsta2 as bs

bern_sta_header="STATION NAME          FLG          FROM                   TO         RECEIVER TYPE         RECEIVER SERIAL NBR   REC #   ANTENNA TYPE          ANTENNA SERIAL NBR    ANT #    NORTH      EAST      UP      DESCRIPTION             REMARK\n****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ********************  ******  ********************  ********************  ******  ***.****  ***.****  ***.****  **********************  ************************"

with open('station.info', 'r') as fin:
    print bern_sta_header
    for line in fin.readlines():
        if line[0] is not '*':
            status       = 0
            station_id   = line[0:7].strip()
            full_name    = line[7:25].strip()
            sess_start   = line[25:44].strip()
            sess_stop    = line[44:63].strip()
            ant_hgt      = float(line[63:72])
            ant_htcod    = line[72:79]
            ant_north    = float(line[79:88])
            ant_east     = float(line[88:97])
            receiver_tp  = line[97:119].strip()
            receiver_vr  = line[119:141].strip()
            sw_vers      = line[141:148].strip()
            receiver_sn  = line[148:170].strip()
            antenna_tp   = "{0:<16s}{1:>4s}".format(line[170:187].strip(),line[187:194].strip())
            antenna_sn   = line[194:].strip()
            try:
            	sess_start   = datetime.datetime.strptime(sess_start, '%Y %j %H %M %S')
            except:
                if sess_start.split()[0] == '9999':
                    sess_start = datetime.datetime.min
                else:
                    print >> sys.stderr, '[ERROR] Invalid datetime: \'%s\''%(sess_start)
                    status = 1
            try:
                sess_stop   = datetime.datetime.strptime(sess_stop, '%Y %j %H %M %S')
            except:
                if sess_stop.split()[0] == '9999':
                    sess_stop = datetime.datetime.max
                else:
                    print >> sys.stderr, '[ERROR] Invalid datetime: \'%s\''%(sess_stop)
                    status = 1
            if status is not 0:
                print >> sys.stderr, '       Record not transformed:'
                print >> sys.stderr, '       ['+line.rstrip()+']'
            else:
                bern_rec = bs.StaRecord_002(station_name=station_id,\
                        receiver_type=receiver_tp, receiver_serial=receiver_sn, receiver_number=sw_vers, \
                        antenna_type=antenna_tp, antenna_serial=antenna_sn, antenna_number=None, \
                        dnorth=ant_north, deast=ant_east, dup=ant_hgt, \
                        description=full_name, remark="Converted from GAMIT station.info.", \
                        start=sess_start, stop=sess_stop)
		print bern_rec
