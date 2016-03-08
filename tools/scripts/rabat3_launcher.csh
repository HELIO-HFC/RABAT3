#! /bin/csh 

if ( ${#argv} != 2 ) then
        echo "You must give the list of files to process and the name of the batch file"
        exit 1
endif

set file2process = $1
set batchfilename  = $2

set rabat3_dir = /Users/xavier/LESIA/Solaire/HELIO/HFC/Features/RadioBursts/RABAT3


if ( ! -e $rabat3_dir) then 
	echo "You must set the full path of the RABAT3 directory"
	exit 0
endif

## Create batch file
/bin/rm -f $batchfilename 
touch $batchfilename 

echo "\!PATH = \!PATH + ':$rabat3_dir/SRC'" >> $batchfilename
echo "print,\!PATH" >> $batchfilename
echo "@compile_rabat3" >> $batchfilename
foreach file ($file2process)
	echo "rabat3, '"$file"',/SILENT,/NOLOG" >> $batchfilename
end
echo "retall" >> $batchfilename
echo "exit" >> $batchfilename

echo $batchfilename" has been created." 


## Launch batch file
echo Executing batchfile: $batchfilename
/usr/local/bin/idl $batchfilename


exit 0