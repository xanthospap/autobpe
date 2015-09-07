#! /usr/bin/python

import os
import bernutils.bamb2

## EXAMPLE USAGE

#x = bernutils.bamb.ambfile('FFU151000_GNSS.SUM')

#print x.collectMethodBsls('l12')
#print x.collectMethodBsls('cbnl')
#print x.collectMethodBsls('pbwl')
#print x.collectMethodBsls('qif')

#print x.collectBsls('l12','gps')
#print x.collectBsls('cbnl','glonass')
#print x.collectBsls('pbwl','gps')
#print x.collectBsls('qif')

#x.toHtmlTable('GPS')
#print x.collectMethodBsls('qif')
#print x.collectMethodStats('pbwl')


###############################
#fin = open('FFU151000_GNSS.SUM', 'r')

#method_str = '#AR_L3'
# lines = [ l for l in fin.readlines() if len(l)>10 ]
# print filter(lambda line: line.split()[len(line.split())-1] == method_str, lines)
#print [ l for l in fin.readlines() if len(l)>10 and l.split()[len(l.split())-1] == method_str ]

#print 'num of baselines =', str(len(al3))

#fin.close()
###############################

x = bernutils.bamb2.AmbFile('FFU151000_GNSS.SUM')
#lst = x.method_lines('qif', 'R')
#print lst
x.toHtml()