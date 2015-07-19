#! /usr/bin/python

import datetime
import ftplib
import os
import bernutils.gpstime
import bernutils.webutils

'''
Products under the /CODE directory

source ftp://ftp.unibe.ch/aiub/CODE/0000_CODE.ACN

Files generated from three-day long-arc solutions:
CODwwwwn.EPH.Z  GNSS ephemeris/clock data in 7 daily
                files at 15-min intervals in SP3
                format, including accuracy codes
                computed from a long-arc analysis

Files generated from clean one-day solutions: 
COFwwwwn.EPH.Z  GNSS ephemeris/clock data in 7 daily
                files at 15-min intervals in SP3
                format, including accuracy codes
                computed from a clean one-day solution.

EPH: Orbit positions correspond to the estimates
for the middle day of a 3-day in case of a
long-arc analysis.

CODwwwwn.EPH_R  GNSS/GPS ephemeris/clock data in at
                15-min intervals in SP3 format,
                including accuracy codes computed
                from a long-arc analysis

EPH: Orbit positions correspond to the estimates
for the last day of a 3-day long-arc analysis.

COD.EPH_U       GNSS ephemeris/broadcast clock data
                in at 15-min intervals in SP3 format,
                including accuracy codes computed
                from a long-arc analysis.

EPH: Orbit positions correspond to the estimates
for the last 24 hours of a 3-day long-arc
analysis plus predictions for the following
24 hours.

CODwwwwn.EPH_Pi GNSS/GPS ephemeris/clock data at
                15-min intervals in SP3 format,
                including accuracy codes computed 
                from a long-arc analysis.

"P2" indicates 2-day predictions (24-48 hours);
"P" indicates 1-day predictions (0-24 hours).

Products under the /REPRO_2013 directory

source ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN

Files generated from three-day long-arc solutions:
CO2wwwwn.EPH.Z  GNSS ephemeris/clock data in 7 daily
                files at 15-min intervals in SP3 
                format, including accuracy codes
                computed from a long-arc analysis.

Files generated from clean one-day solutions:
CF2wwwwn.EPH.Z  GNSS ephemeris/clock data in 7 daily
                files at 15-min intervals in SP3
                format, including accuracy codes
                computed from a clean one-day solution.
'''

COD_HOST  = 'ftp.unibe.ch'
IGS_HOST = 'cddis.gsfc.nasa.gov'

COD_DIR       = '/aiub/CODE'
COD_DIR_2013  = '/aiub/REPRO_2013/CODE'
IGS_DIR       = '/gnss/products'
IGS_DIR_2013  = '/gnss/products/repro2'

sp3_type = {'d': 'CODwwwwn.EPH.Z',
        'f': 'cofwwwwn.eph.Z',
        'r': 'CODwwwwn.EPH_R',
        'u': 'COD.EPH_U',
        'p': 'CODwwwwn.EPH_Pi',
        '2d': 'CO2wwwwn.EPH.Z',
        '2f': 'cf2wwwwn.eph.Z'
        }

def getCodSp3(stype,datetm=None,out_dir=None,use_repro_13=False,prd=0):
    ''' Download CODE Sp3 file (i.e. CODwwwwn.EPH.Z). All sp3 (orbit)
        files are downloaded from CODE's ftp webserver (ftp.unibe.ch),
        except from final, clean one-day solution (i.e. cof) which are
        downloaded from CDDIS (cddis.gsfc.nasa.gov) and reprocessed
        final, clean one-day solution (i.e. cf2) which are
        downloaded from CDDIS (cddis.gsfc.nasa.gov) at repro2.

        :param stype: A char denoting the type of orbit to be
                     downloaded. Can be:

                     * 'd' final, 3-day solution,
                     * 'f' final, one-day solution
                     * 'r' rapid solution,
                     * 'u' ultra-rapid solution,
                     * 'p' prediction

        :param datetm: A Python ``datetime`` object; not needed
                       if downloading an ultra-rapid product.
        :param out_dir: Output directory.
        :param prd:    If the user wants the predicted orbit (i.e.
                       ``stype = 'p'``, then the prd denotes:

                       * ``prd = 0`` indicates 1-day predictions (0-24 hours)
                       * ``prd != 0`` indicates 2-day predictions (24-48 hours)

        :param use_repro_13: If set to ``True``, the orbit file downloaded
                       will be the one from the reprocessing campaign
                       **REPRO 2013**. For more info, see
                       ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN.
                       Only available when the parameter ``stype`` is ``'d'``
                       of ``'f'``.

        :returns: The name (including path) of the downloaded
                  file.

    '''


    ## output dir must exist
    if out_dir and not os.path.isdir(out_dir):
        raise RuntimeError('Invalid directory: '+out_dir+' -> getCodSp3.')

    ## if we are to use repro_2013, then the type must be
    ## either 'd' or 'f'; they are translated to '2d' or '2f'
    ## respectively.
    if use_repro_13 == True and stype != 'd' and stype != 'f':
        raise RuntimeError('Reprocessed orbits only available for type: final -> getCodSp3.')
    elif use_repro_13 == True and (stype == 'd' or stype == 'f'):
        stype = '2' + stype

    ## date must be specified, except for ultra-rapid
    if stype != 'u' and not datetm:
        raise RuntimeError('Must specify date -> getCodSp3.')
    
    ## generic sp3 file name (including e.g. 'wwww')
    try:
        generic_filen = sp3_type[stype]
    except:
        raise RuntimeError('Invalid sp3 type -> getCodSp3.')

    ## we need some dates ...
    if datetm:
        try:
            week, sow = bernutils.gpstime.pydt2gps(datetm)
            dow   = int(datetm.strftime('%w'))
            iyear = int(datetm.strftime('%Y'))
        except:
            raise

    ## --- Ftp Server --- ##
    if stype == 'f' or stype == '2f':
        HOST = IGS_HOST
    else:
        HOST = COD_HOST

    ## ---  Directory in ftp server --- ##
    if   stype == 'f':
        dirn   = IGS_DIR + '/%4i/'%week
    elif stype == '2f':
        dirn   = IGS_DIR_2013 + '/%4i/'%week
    elif stype == 'd':
        dirn = COD_DIR + '/%04i/' %int(iyear)
    elif stype == '2d':
        dirn = COD_DIR_2013 + '/%04i/' %int(iyear)
    else:
        dirn = COD_DIR + '/'

    ## --- Name of the file --- ##
    dfile = generic_filen
    ## all but the ultra-rapid files, contain date
    if stype != 'u':
        dfile = dfile.replace('wwww','%4i'%week)
        dfile = dfile.replace('n','%1i'%dow)
    ## in case of predicted orbit, we must replace the 'i'
    if stype == 'u':
        if prd == 0:
            dfile = dfile.replace('i','')
        else:
            dfile = dfile.replace('i','2')

    ## --- Name of the saved file --- ##
    saveas = dfile
    if out_dir:
        if out_dir[-1] != '/':
            out_dir += '/'
        saveas = out_dir + saveas
    
    ## --- Download --- ##
    try:
        localfile, webfile = bernutils.webutils.grabFtpFile(HOST,dirn,dfile,saveas)
    except:
        raise

    return localfile, webfile
