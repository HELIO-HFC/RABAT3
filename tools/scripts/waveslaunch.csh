#! /bin/csh

switch ($#) 
	case 4:
		set instr = ${1}
    	set month = ${3}
    	set day = ${2}
    	set year = ${4}
    	breaksw
 	case 5:
		set instr = ${1}
    	set month = ${3}
    	set day = ${2}
    	set year = ${4}
		set output_dir = ${5}
		breaksw
	default:
    	echo 'csh waveslaunch.csh instr day month year [output_dir]'
    	exit
    	breaksw
endsw

set data_path = '/Volumes/WindServer/WIND_Data/'
if ($instr == 'rad1') then
	set instr_path = 'Rad1/L3/'
	set filename = 'WIN_WAV_RAD1_HRES_'
else
	set instr_path = 'Rad2/L3/'
	set filename = 'WIN_WAV_RAD2_HRES_'
endif


# FTP pour reccuperer les fichiers Wind/Waves
# ATTENTION au binary avec sorbet nouveau sinon les fichiers sont corrompus
set HOST = sorbet.obspm.fr
set USER = bonnin
set PASS = auberon1404

echo $data_path$instr_path
ftp -nv <<%
open $HOST 
user $USER $PASS
cd $data_path$instr_path
binary
get $filename$year$month$day.SFU
close
%

if (-e $filename$year$month$day.SFU) then
	if ($# == 5) mv $filename$year$month$day.SFU $output_dir
endif

# Sert a de pas avoir d'erreur du style No match
set nonomatch

exit
