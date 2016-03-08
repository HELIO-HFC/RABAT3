#! /bin/sh

if ( ${#argv} < 1 ) then
	echo "/bin/csh getftp_swaves.csh filename [output_dir]"
    exit 1
endif

set file = $1

if (${#argv} == 2) then 
	echo "cd "$2
	cd $2
endif

set year = `echo $file | cut -c 16-19`	

set data_dir = "swaves_data/"$year	
			
#Get GSFC/NASA Wind/Waves file
#echo "ftp -nv stereowaves.gsfc.nasa.gov <<EOF >/dev/null"
ftp -nv stereowaves.gsfc.nasa.gov <<EOF >/dev/null
user anonymous bass2000@obspm.fr
binary
cd $data_dir
prompt
mget $file

exit 0