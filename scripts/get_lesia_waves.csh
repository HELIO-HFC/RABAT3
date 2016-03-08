#! /bin/sh

if ( ${#argv} < 3 ) then
	echo "/bin/csh get_lesia_waves.csh date receiver dataset [output_dir]"
    exit 1
endif

set date = "$1"
set rec = "$2"
set ds = "$3"

if (${#argv} == 4) then
    echo "cd "$4
    cd $4
endif

set data_path = /nfs/wind/WIND_Data/CDPP/$rec

switch ($ds)
    case l2_hres:
        set ds_path = l2/h_res
        set filename = "wi_wa_"$rec"_l2_"$date
        breaksw
    case l2_60s:
        set ds_path = l2/average
        set filename = "wi_wa_"$rec"_l2_60s_"$date
        breaksw
    default:
        echo "dataset must be l2_hres or l2_60s"
        exit 1
    breaksw
endsw


#Get GSFC/NASA Wind/Waves file
#echo "ftp -nv stereowaves.gsfc.nasa.gov <<EOF >/dev/null"
ftp -nv sorbet.obspm.fr <<EOF >/dev/null
user bonnin auberon1404
binary
cd $data_path/$ds_path
prompt
mget $filename"_v01.dat"

exit 0