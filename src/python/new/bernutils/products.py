#! /usr/bin/python

import datetime
import ftplib
import os
import bernutils.gpstime
import bernutils.webutils

'''

'''

COD_HOST  = 'ftp.unibe.ch'
IGS_HOST = 'cddis.gsfc.nasa.gov'

COD_DIR       = '/aiub/CODE'
COD_DIR_2013  = '/aiub/REPRO_2013/CODE'
IGS_DIR       = '/gnss/products'
IGS_DIR_2013  = '/gnss/products/repro2'

erp_type = {'d': 'CODwwww7.ERP.Z',
        'f': 'cofwwww7.erp.Z',
        'r': 'CODwwwwn.ERP_R',
        'u': 'COD.ERP_U',
        'p': 'CODwwwwn.ERP_Pi',
        '2d': 'CO2wwww7.ERP.Z',
        '2f': 'cf2wwww7.erp.Z'
        }

sp3_type = {'d': 'CODwwwwn.EPH.Z',
        'f': 'cofwwwwn.eph.Z',
        'r': 'CODwwwwn.EPH_R',
        'u': 'COD.EPH_U',
        'p': 'CODwwwwn.EPH_Pi',
        '2d': 'CO2wwwwn.EPH.Z',
        '2f': 'cf2wwwwn.eph.Z'
        }

dcb_type = {'p2': 'P1P2yymm.DCB',
            'c1': 'P1C1yymm.DCB',
            'c1_rnx': 'P1C1yymm_RINEX.DCB',
            'c2_rnx': 'P2C2yymm_RINEX.DCB'
        }

def getRunningDcb(filename,saveas):
    HOST = COD_HOST
    dirn = COD_DIR
    try:
        localfile, webfile = bernutils.webutils.grabFtpFile(HOST,dirn,filename,saveas)
    except:
        raise

def getFinalDcb(year,filename,saveas):
    HOST = COD_HOST
    dirn = COD_DIR + ('/04i/'%year)
    try:
        localfile, webfile = bernutils.webutils.grabFtpFile(HOST,dirn,filename,saveas)
    except:
        raise

def getCodDcb(stype,datetm,out_dir=None):
    ''' Download .DCB file.

        .. note::
            Available Code Differential Bias files from CODE:

            * P1P2yymm.DCB
                            GNSS monthly P1-P2 code bias
                            solutions in Bernese DCB format
            * P1C1yymm.DCB/F
                            GPS monthly P1-C1 code bias solutions
                            in Bernese DCB format and in a format
                            specific to the CC2NONCC utility
            * P1C1yymm_RINEX.DCB/F
                            GNSS monthly P1-C1 code bias
                            values in Bernese DCB format and in
                            a format specific to the CC2NONCC
                            utility directly extracted from
                            RINEX observation files
            * P2C2yymm_RINEX.DCB
                            GNSS monthly P2-C2 code bias
                            values in Bernese DCB format directly
                            extracted from RINEX observation files

    '''
    ## output dir must exist
    if out_dir and not os.path.isdir(out_dir):
        raise RuntimeError('Invalid directory: '+out_dir+' -> getCodDcb.')
    
    try:
        generic_file = dcb_type[stype]
    except:
        raise RuntimeError('Invalid dcb type: '+stype)

    # if the current month is the same as the month requested, then
    # download the running average.
    today = datetime.datetime.now()
    dt    = today.date() - datetm.date()

    if today.year == datetm.year and today.month == datetm.month:
        filename = generic_file.replace('yymm','')
        try:
            localfile, webfile = getRunningDcb(filename,saveas)
        except:
            raise
    elif dt.days < 15:
    elif dt.days < 30:
        filename = generic_file.replace('yymm','')
        try:
            localfile, webfile = getRunningDcb(filename,saveas)
        except:
            raise

def erpTimeSpan(filen,as_mjd=True):
    ''' Given a ERP filename, this function will return the min
        and max dates for which the file has info. The function
        returns a tuple of ``[max_date, min_date]``. The format
        (type) of the dates in the tuple, is either MJD (if the
        input parameter ``as_mjd`` is ``True``) or Python ``datetime``
        objects (if ``as_mjd`` is ``False``).
    '''

    try:
        fin = open(filen, 'r')
    except:
        raise RuntimeError('Cannot open erp file: '+filen)

    for i in range(1,5):
        line = fin.readline()

    line = fin.readline()
    if line.split()[0] != 'MJD':
        fin.close()
        raise RuntimeError('Invalid erp format: '+filen)

    line     = fin.readline()
    mjd_list = []
    dummy_it = 0

    line = fin.readline()
    while (line and dummy_it < 1000):
        if as_mjd == True: ## append as MJD instances
            mjd_list.append(float(line.split()[0]))
        else: ## append as datetime.datetime instances
            mjd_list.append(bernutils.gpstime.mjd2pydt(float(line.split()[0])))
        dummy_it += 1
        line = fin.readline()

    fin.close()

    if dummy_it >= 1000:
        raise RuntimeError('Failed reading erp: '+filen)

    return max(mjd_list), min(mjd_list)


def getCodErp(stype,datetm=None,out_dir=None,use_repro_13=False,prd=0):
    ''' Download CODE Erp file (i.e. CODwwwwn.ERP.Z). All erp (earth orientation
        parameter) files are downloaded from CODE's ftp webserver (ftp.unibe.ch),
        except from final, clean one-day solution (i.e. cof) which are
        downloaded from CDDIS (cddis.gsfc.nasa.gov) and reprocessed
        final, clean one-day solution (i.e. cf2) which are
        downloaded from CDDIS (cddis.gsfc.nasa.gov) at repro2.

        :param stype: A char denoting the type of erp to be
                     downloaded. Can be:

                     * 'd' final, 3-day solution,
                     * 'f' final, one-day solution
                     * 'r' rapid solution,
                     * 'u' ultra-rapid solution,
                     * 'p' prediction

        :param datetm: A Python ``datetime`` object; not needed
                       if downloading an ultra-rapid product.
        :param out_dir: Output directory.
        :param prd:    If the user wants the predicted erp (i.e.
                       ``stype = 'p'``, then the prd denotes:

                       * ``prd = 0`` indicates 1-day predictions (0-24 hours)
                       * ``prd != 0`` indicates 2-day predictions (24-48 hours)

        :param use_repro_13: If set to ``True``, the erp file downloaded
                       will be the one from the reprocessing campaign
                       **REPRO 2013**. For more info, see
                       ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN.
                       Only available when the parameter ``stype`` is ``'d'``
                       of ``'f'``.

        :returns: In sucess, a tuple is returned; first element is the
                  name of the saved file, the second element is the name
                  of the file on web.

        .. note::
            This function is very similar to products.getCodSp3(...)

    '''
    ## output dir must exist
    if out_dir and not os.path.isdir(out_dir):
        raise RuntimeError('Invalid directory: '+out_dir+' -> getCodErp.')

    ## if we are to use repro_2013, then the type must be
    ## either 'd' or 'f'; they are translated to '2d' or '2f'
    ## respectively.
    if use_repro_13 == True and stype != 'd' and stype != 'f':
        raise RuntimeError('Reprocessed erp only available for type: final -> getCodErp.')
    elif use_repro_13 == True and (stype == 'd' or stype == 'f'):
        stype = '2' + stype

    ## date must be specified, except for ultra-rapid
    if stype != 'u' and not datetm:
        raise RuntimeError('Must specify date -> getCodErp.')
    
    ## generic erp file name (including e.g. 'wwww')
    try:
        generic_filen = erp_type[stype]
    except:
        raise RuntimeError('Invalid erp type -> getCodErp.')

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
        # dow only set if rapid or prediction
        if stype == 'r' or stype == 'p':
            dfile = dfile.replace('n','%1i'%dow)
    ## in case of predicted erp, we must replace the 'i'
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

        :returns: In sucess, a tuple is returned; first element is the
                  name of the saved file, the second element is the name
                  of the file on web.

        .. note::
            A short list of orbit products under the /CODE directory:
            source ftp://ftp.unibe.ch/aiub/CODE/0000_CODE.ACN

                * CODwwwwn.EPH.Z
                                GNSS ephemeris/clock data in 7 daily
                                files at 15-min intervals in SP3
                                format, including accuracy codes
                                computed from a long-arc analysis
                                Files generated from three-day long-arc solutions.

                * COFwwwwn.EPH.Z
                                GNSS ephemeris/clock data in 7 daily
                                files at 15-min intervals in SP3
                                format, including accuracy codes
                                computed from a clean one-day solution.
                                Files generated from clean one-day solutions.

                *Orbit positions correspond to the estimates
                for the middle day of a 3-day in case of a
                long-arc analysis.*

                * CODwwwwn.EPH_R
                                GNSS/GPS ephemeris/clock data in at
                                15-min intervals in SP3 format,
                                including accuracy codes computed
                                from a long-arc analysis

                *Orbit positions correspond to the estimates
                for the last day of a 3-day long-arc analysis.*

                * COD.EPH_U
                                GNSS ephemeris/broadcast clock data
                                in at 15-min intervals in SP3 format,
                                including accuracy codes computed
                                from a long-arc analysis.

                Orbit positions correspond to the estimates
                for the last 24 hours of a 3-day long-arc
                analysis plus predictions for the following
                24 hours.

                * CODwwwwn.EPH_Pi 
                                GNSS/GPS ephemeris/clock data at
                                15-min intervals in SP3 format,
                                including accuracy codes computed 
                                from a long-arc analysis.

                "P2" indicates 2-day predictions (24-48 hours);
                "P" indicates 1-day predictions (0-24 hours).

            Products under the /REPRO_2013 directory
            source ftp://ftp.unibe.ch/aiub/REPRO_2013/CODE_REPRO_2013.ACN

                * CO2wwwwn.EPH.Z
                                GNSS ephemeris/clock data in 7 daily
                                files at 15-min intervals in SP3 
                                format, including accuracy codes
                                computed from a long-arc analysis.
                                Files generated from three-day long-arc solutions.

                * CF2wwwwn.EPH.Z
                                GNSS ephemeris/clock data in 7 daily
                                files at 15-min intervals in SP3
                                format, including accuracy codes
                                computed from a clean one-day solution.
                                Files generated from clean one-day solutions.
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
