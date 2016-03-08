;IDL Batch file to launch rabat3_processing.pro
;X.Bonnin, 16-MAY-2013.

rabat3_home_dir = getenv('RABAT3_HOME_DIR')
if (rabat3_home_dir eq '') then message,'$RABAT3_HOME_DIR environment variable must set!'
output_dir=rabat3_home_dir+'/products'
data_dir=rabat3_home_dir+'/data'
config_dir=rabat3_home_dir+'/config'

!PATH = expand_path('+'+rabat3_home_dir+'/lib/idl') + path_sep(/SEARCH_PATH) + !PATH
!PATH = expand_path('+'+rabat3_home_dir+'/src') + path_sep(/SEARCH_PATH) + !PATH
@compile_rabat3.batch

; Input options
VERBOSE=1b
DEBUG=0b
DISPLAY=1b

date='20031102'
get_waves_file,date,'rad1',file_r1,level='l2_avg',target_dir=data_dir,/NOCLO
get_waves_file,date,'rad2',file_r2,level='l2_avg',target_dir=data_dir,/NOCLO
datafile=[file_r1,file_r2]
configfile=config_dir+path_sep()+'rabat3_wind.config'
output_file=output_dir+path_sep()+'rabat3_203_'+date+'_win.sav'

rabat3_processing,datafile, configfile, results, $
		  		  output_file=output_file, $	
                  VERBOSE=VERBOSE,DEBUG=DEBUG, $
		  		  DISPLAY=DISPLAY
                  
help,results
