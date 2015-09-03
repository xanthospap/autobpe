#! /usr/bin/python

import os
import bernutils.bamb

## EXAMPLE USAGE

x = bernutils.bamb.ambfile('FFU151000_GNSS.SUM')

#print x.collectMethodBsls('l12')
#print x.collectMethodBsls('cbnl')
#print x.collectMethodBsls('pbwl')
#print x.collectMethodBsls('qif')

#print x.collectBsls('l12','gps')
#print x.collectBsls('cbnl','glonass')
#print x.collectBsls('pbwl','gps')
#print x.collectBsls('qif')

x.toHtmlTable()