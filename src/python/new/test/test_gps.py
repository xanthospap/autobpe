#! /usr/bin/python

import os
import bernutils.bgps

x = bernutils.bgps.gpsoutfile('GPSEST.L80')

lst1 = x.getHeaderInfo()
lst2 = x.getBaselineList()
lst3 = x.getCrdSolInfo()
print '--------------------------------------------------------------------------------------------'
print lst1
print '--------------------------------------------------------------------------------------------'
print lst2
print '--------------------------------------------------------------------------------------------'
print lst3
