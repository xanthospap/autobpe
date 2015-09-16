#! /usr/bin/python

import os
import bernutils.bpcf

PCF = "RNX2SNX.PCF"

x = bernutils.bpcf.PcfFile(PCF)

#v = x.load_variables()
#for i in v: print i

#V_RESULT Directory name for the RNX2SNX results   RNX2SNX
vv = x.set_variable('RESULT', descr='Changing this ... hopefully', val='foo/bar/')
#for i in vv: print i

x.flush_variables()

#V_BLQINF BLQ FILE NAME, CMC CORRECTIONS           EXAMPLE
vv = x.set_variable('BLQINF', descr='Changing this ... fuck yeah', val='KOKOs')
#V_SATSYS Select the GNSS (GPS, GPS/GLO)           GPS/GLO
vv = x.set_variable('BLQINF', val='LALALALA')

x.flush_variables()