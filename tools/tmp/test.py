#! /usr/bin/env python
# -*- coding: latin-1 -*-

import sys, os
import waves
from datetime import datetime
import struct

date = datetime(2001,01,01)
ww = waves.wind(provider="lesia",receiver="rad2",dataset="l2_hres")
file = ww.get_file(date=date,username="waves",password="wavesuser")
print file

header_fields = ("P_FIELD","JULIAN_DAY_B1","JULIAN_DAY_B2","JULIAN_DAY_B3","MSEC_OF_DAY",
                 "RECEIVER_CODE","JULIAN_SEC_FRAC","YEAR","MONTH","DAY","HOUR","MINUTE","SECOND","JULIAN_SEC_FRAC",
                 "ISWEEP","IUNIT","NPBS","SUN_ANGLE","SPIN_RATE","KSPIN","MODE","LISTFR","NFREQ",
    "ICAL","IANTEN","IPOLA","IDIPXY","SDURCY","SDURPA","NPALCY","NFRPAL","NPALIF","NSPALF","NZPALF") 
header_dtype = '>bbbbihLhhhhhhfihhffhhhhhhhhffhhhhh'

header = [] ; data = [] ; nsweep=1
with open(file,'rb') as frb:
    while (True):
        try:
            print "Reading sweep #%i" % (nsweep)
            # Reading number of octets in the current sweep
            block = frb.read(4)
            if (len(block) == 0): break
            loctets1 = struct.unpack('>i',block)[0]
            # Reading header parameters in the current sweep
            block = frb.read(80)
            header_i = dict(zip(header_fields,struct.unpack(header_dtype,block)))
            npalf = header_i['NPALIF'] ; nspal = header_i['NSPALF'] ; nzpal = header_i['NZPALF']
            # Reading frequency list (kHz) in the current sweep
            block = frb.read(4*npalf)
            freq = struct.unpack('>'+'f'*npalf,block)
            # Reading intensity and time values for S/SP in the current sweep
            block = frb.read(4*npalf*nspal)
            Vspal = struct.unpack('>'+'f'*npalf*nspal,block)
            block = frb.read(4*npalf*nspal)
            Tspal = struct.unpack('>'+'f'*npalf*nspal,block)
            # Reading intensity and time values for Z in the current sweep
            block = frb.read(4*npalf*nzpal)
            Vzpal = struct.unpack('>'+'f'*npalf*nzpal,block)    
            block = frb.read(4*npalf*nzpal)
            Tzpal = struct.unpack('>'+'f'*npalf*nzpal,block)
            # Reading number of octets in the current sweep
            block = frb.read(4)
            loctets2 = struct.unpack('>i',block)[0]
            if (loctets2 != loctets1):
                print "Error reading file!"
                sys.exit(1)
        except EOFError:
            print "End of file reached"
            break
        else:
            header.append(header_i)
            data.append({"FREQ":freq,"VSPAL":Vspal,"VZPAL":Vzpal,"TSPAL":Tspal,"TZPAL":Tzpal})
            nsweep+=1
    
            # TODO : finir d ecrire les routines de lecture pour l'ensemble des jeux de donnees Wind/Waves puis tester dans waves.py
 
