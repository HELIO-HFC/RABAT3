#! /bin/csh

if ( ${#argv} < 3 ) then
    echo "/bin/csh damlaunch.csh day month year [output_dir]"
    exit 1
endif

if ($# > 2) then
    set month = ${2}
    set day = ${1}
    set year_yy = `echo ${3} | cut -c3-4`
    set year_yyyy = ${3}
else
    set month = `date -dyesterday +%m`
    set day = `date -dyesterday +%d`
    set year_yy = `date -dyesterday +%y`
    set year_yyyy = `date -dyesterday +%Y`
endif

if ($# == 4) then
    cd $4
endif

echo "Getting DAM file for $year_yyyy-$month-$day"

# FTP pour reccuperer les fichiers DAM
# ATTENTION au binary avec mesolr nouveau sinon les fichiers sont corrompus
ftp -nv <<%
open mesolr.obspm.fr
user nancay Jbieret0
cd ../decam/data/decam/$year_yy$month/
binary
get S$year_yy$month$day.RT1
close
%

# Sert a de pas avoir d'erreur du style No match
set nonomatch

exit
