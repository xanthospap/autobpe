=============================
Module : bamb
=============================

This module contains the classes:

* AmbFile and
* AmbLine

**AmbFile** represents a Bernese v5.2 ambiguity resolution summary file. 

This kind of files, contain ambiguity resolution information for a list of baselines. For every
ambiguity resolution method used (within the processing), a block is created, where
each line corrsponds to a baseline and satellite-system pair (thus, a single baseline 
may have multiple lines in one single method, if more than one satellite systems 
are used). At the end of each block, summary lines follow, where the average values
and/or statistics are recorded for the given technique.

The default extension is .SUM (e.g. AMBYYDDDS.SUM). 

Ambiguity resolution summary file format format is very strict, and most of the 
functions/modules depend that this format is kept.

See the Examples section for an test ambiguity resolution summary file.

**AmbLine** is a class holding ambiguity resolution record lines. Such instances 
are normally used to accomodate the reading of **AmbFile** objects; they are not 
used as standalone.

For example, most member functions of the **AmbFile** class, read in the needed
records for a given resolution method (as raw strings) and then cast the individual
lines to instances of **AmbLine** to extract information.

-----------------------------
Documentation
-----------------------------

.. currentmodule:: bernutils.bamb

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class ambline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bamb.AmbLine
  :members:
  :undoc-members:

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class ambfile
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bamb.AmbFile
  :members:

-----------------------------
Examples
-----------------------------

.. code-block:: python

  ================================================================================
   Code-Based Widelane (WL) Ambiguity Resolution (<6000 km)
  ================================================================================

   ---------------------------------------------------------------------------------------------------------------------


  ================================================================================
   Code-Based Narrowlane (NL) Ambiguity Resolution (<6000 km)
  ================================================================================

   ---------------------------------------------------------------------------------------------------------------------


  ================================================================================
   Phase-Based Widelane (L5) Ambiguity Resolution (<200 km)
  ================================================================================

   File     Sta1 Sta2    Length     Before     After    Res  Sys  Max/RMS L5    Receiver 1           Receiver 2
                          (km)    #Amb (mm)  #Amb (mm)  (%)       (L5 Cycles)
   ----------------------------------------------------------------------------------------------------------------------
   AAAH1000 AIGI ATHI     31.879    47  2.5     0  2.7 100.0 G    0.087  0.028  TPS GB-1000          TPS NETG3             #AR_L5 
   AAAH1000 AIGI ATHI     31.879    47  2.5    11  2.7  76.6  R   0.116  0.045  TPS GB-1000          TPS NETG3             #AR_L5 
   AAAH1000 AIGI ATHI     31.879    94  2.5    11  2.7  88.3 GR   0.116  0.036  TPS GB-1000          TPS NETG3             #AR_L5 
   AGOO1000 AGNI OROP     21.017    43  1.7    11  2.1  74.4  R   0.098  0.049  TPS GB-1000          TPS NET-G3A           #AR_L5
   #[ .. More lines here ..]
   TPTO1000 TRIP TROP     43.520   123  2.8    19  3.4  84.6 GR   0.166  0.053  TPS NET-G3A          TPS NET-G3A           #AR_L5 
   ---------------------------------------------------------------------------------------------------------------------
   Tot:  65               52.914  3592  3.7   279  4.1  92.2 G    0.163  0.044                                             #AR_L5 
   Tot:  63               52.850  3146  3.7  1244  4.1  60.5  R   0.166  0.058                                             #AR_L5 
   Tot:  65               52.914  6738  3.7  1523  4.1  77.4 GR   0.166  0.050                                             #AR_L5 


  ================================================================================
   Phase-Based Narrowlane (L3) Ambiguity Resolution (<200 km)
  ================================================================================

   File     Sta1 Sta2    Length     Before     After    Res  Sys  Max/RMS L1    Receiver 1           Receiver 2
                          (km)    #Amb (mm)  #Amb (mm)  (%)       (L1 Cycles)
   ----------------------------------------------------------------------------------------------------------------------
   AAAH1000 AIGI ATHI     31.879    47  1.2     0  1.3 100.0 G    0.150  0.052  TPS GB-1000          TPS NETG3             #AR_L3 
   AAAH1000 AIGI ATHI     31.879    47  1.2    12  1.3  74.5  R   0.149  0.073  TPS GB-1000          TPS NETG3             #AR_L3 
   AAAH1000 AIGI ATHI     31.879    94  1.2    12  1.3  87.2 GR   0.150  0.062  TPS GB-1000          TPS NETG3             #AR_L3 
   ACAU1000 ASPR AUT1     48.504    58  0.8    22  0.8  62.1 G    0.148  0.051  TPS NET-G3A          LEICA GRX1200PRO      #AR_L3 
   AGOO1000 AGNI OROP     21.017    52  1.5     3  1.6  94.2 G    0.116  0.053  TPS GB-1000          TPS NET-G3A           #AR_L3 
   #[ .. More lines here ..]
   TPTO1000 TRIP TROP     43.520   123  1.6    52  1.7  57.7 GR   0.175  0.070  TPS NET-G3A          TPS NET-G3A           #AR_L3 
   ---------------------------------------------------------------------------------------------------------------------
   Tot:  65               52.914  3592  1.3   462  1.4  87.1 G    0.187  0.053                                             #AR_L3 
   Tot:  63               52.850  3146  1.3  1888  1.4  40.0  R   0.193  0.081                                             #AR_L3 
   Tot:  65               52.914  6738  1.3  2350  1.4  65.1 GR   0.193  0.063                                             #AR_L3 


  ================================================================================
   Quasi-Ionosphere-Free (QIF) Ambiguity Resolution (<2000 km)
  ================================================================================

   File     Sta1 Sta2    Length     Before     After    Res  Sys  Max/RMS L5    Max/RMS L3    Receiver 1           Receiver 2
                          (km)    #Amb (mm)  #Amb (mm)  (%)       (L5 Cycles)   (L3 Cycles)
   ------------------------------------------------------------------------------------------------------------------------------------
   ANNI1000 ANKR NICO    529.691    94  1.3    42  1.4  55.3 G    0.412  0.136  0.085  0.030  TPS E_GGD            LEICA GR25            #AR_QIF
   ANNI1000 ANKR NICO    529.691    92  1.3    46  1.4  50.0  R   0.469  0.171  0.100  0.047  TPS E_GGD            LEICA GR25            #AR_QIF
   ANNI1000 ANKR NICO    529.691   186  1.3    88  1.4  52.7 GR   0.469  0.154  0.100  0.039  TPS E_GGD            LEICA GR25            #AR_QIF
   ARMD1000 ARTU MDVJ   1317.228   130  1.2    24  1.3  81.5 G    0.492  0.211  0.096  0.029  ASHTECH Z-XII3       TPS NETG3             #AR_QIF
   #[ .. More lines here ..]
   YEZI1000 YEBE ZIMM   1102.463    88  1.4     6  1.4  93.2 G    0.483  0.143  0.095  0.023  TRIMBLE NETRS        TRIMBLE NETRS         #AR_QIF
   -----------------------------------------------------------------------------------------------------------------------------------
   Tot:  21              739.521  2406  1.3   838  1.3  65.2 G    0.498  0.165  0.100  0.027                                             #AR_QIF
   Tot:   9              652.917  1078  1.4   572  1.4  46.9  R   0.498  0.193  0.100  0.037                                             #AR_QIF
   Tot:  21              739.521  3484  1.3  1410  1.3  59.5 GR   0.498  0.172  0.100  0.030                                             #AR_QIF


  ================================================================================
   Direct L1/L2 Ambiguity Resolution (<10 km)
  ================================================================================

   File     Sta1 Sta2    Length     Before     After    Res  Sys  Max/RMS L1    Receiver 1           Receiver 2
                          (km)    #Amb (mm)  #Amb (mm)  (%)       (L1 Cycles)
   ----------------------------------------------------------------------------------------------------------------------
   AUTE1000 AUT1 THES      9.401   114  5.3    38  5.6  66.7 G    0.149  0.052  LEICA GRX1200PRO     TPS NET-G3A           #AR_L12
   CHTU1000 CHAN TUC2      5.386   140  3.9    80  4.0  42.9 G    0.096  0.034  TPS GB-1000          LEICA GRX1200+GNSS    #AR_L12
   CHTU1000 CHAN TUC2      5.386   146  3.9    96  4.0  34.2  R   0.125  0.059  TPS GB-1000          LEICA GRX1200+GNSS    #AR_L12
   CHTU1000 CHAN TUC2      5.386   286  3.9   176  4.0  38.5 GR   0.125  0.047  TPS GB-1000          LEICA GRX1200+GNSS    #AR_L12
   #[ .. More lines here ..]
   PAPT1000 PAT0 PATR      0.712   206  2.4     6  2.8  97.1 GR   0.137  0.036  TPS NET-G3A          TPS GB-1000           #AR_L12
   ---------------------------------------------------------------------------------------------------------------------
   Tot:   5                4.781   570  3.7   209  4.0  63.3 G    0.149  0.039                                             #AR_L12
   Tot:   4                3.626   460  3.1   183  3.5  60.2  R   0.141  0.047                                             #AR_L12
   Tot:   5                4.781  1030  3.7   392  4.0  61.9 GR   0.149  0.043                                             #AR_L12

  ## EOF
