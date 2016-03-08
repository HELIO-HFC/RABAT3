; IDL batch file to run train_rabat3.pro program for Nancay Decametric Array.
; X.Bonnin, 29-JAN-2015

; Load rabat3 routines call by train_rabat3.pro
sep = path_sep()


rabat3_dir = getenv('RABAT3_HOME_DIR')
if (rabat3_dir eq '') then message,'rabat3 env. variables are not defined!'
@../../../../lib/idl/batch/compile_rabat3.batch

target_dir=getenv('RABAT3_IDL_BIN_DIR')
if (target_dir eq '') then target_dir=rabat3_dir+'/lib/idl/bin'

.compile t3_manual_selection

DEBUG=1b & OVERWRITE=1b
config_file = rabat3_dir+'/config/rabat3_nancay_sht.config'
output_dir = rabat3_dir+'/tools/training/software/products'
data_dir = rabat3_dir+'/tools/training/data/samples/dam'
data_files = file_search(data_dir + sep + ['S*.RT1'])
if (data_files[0] eq '') then message,'List of input data file is empty!'
min_val=0 & max_val=12
time_wind = 0.5*3600.0d

t3_manual_selection,data_files, config_file, output_dir, $
	     min_val=min_val,max_val=max_val, $
                  time_window=time_wind, $
                  DEBUG=DEBUG, OVERWRITE=OVERWRITE