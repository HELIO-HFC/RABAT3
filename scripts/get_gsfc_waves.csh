#! /bin/sh

if ( ${#argv} < 1 ) then
	echo "/bin/csh getftp_waves.csh filename [output_dir]"
    exit 1
endif

set file = $1

if (${#argv} == 2) then 
	echo "cd "$2
	cd $2
endif

set ext = `echo $file | cut -d'.' -f2`	

if ("$ext" == "R1") then 
	set data_dir = "wind_rad1/rad1a"
else 
	set data_dir = "wind_rad2/rad2a"
endif	
			
#Get GSFC/NASA Wind/Waves file
#echo "ftp -nv stereowaves.gsfc.nasa.gov <<EOF >/dev/null"
ftp -nv stereowaves.gsfc.nasa.gov <<EOF >/dev/null
user anonymous bass2000@obspm.fr
binary
cd $data_dir
prompt
mget $file

exit 0