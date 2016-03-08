; IDL batch file to run train_rabat3.pro program for Wind.
; X.Bonnin, 05-MAR-2013

; Load rabat3 routines call by train_rabat3.pro
sep = path_sep()

rabat3_dir = '/obs/helio/hfc/frc/rabat3'
;rabat3_dir = '/Users/xavier/Dropbox/Workspace/rabat3'
;rabat3_dir = '/Users/xavier/Travail/Projets/HELIO/HFC/Features/frc/rabat3'
@../../../../lib/idl/batch/compile_rabat3.batch

target_dir=getenv('RABAT3_IDL_BIN_DIR')
if (target_dir eq '') then target_dir=rabat3_dir+'/lib/idl/bin'

pathsep = path_sep(/search_path)
!PATH = expand_path('+'+rabat3_dir+'/src') + pathsep + !PATH
!PATH = expand_path('+'+rabat3_dir+'/lib/idl') + pathsep + !PATH
@/obs/helio/hfc/frc/rabat3/lib/idl/batch/compile_rabat3.batch
;@/Users/xavier/Travail/Projets/HELIO/HFC/Features/frc/rabat3/lib/idl/batch/compile_rabat3.batch
.compile train_rabat3

config_file = rabat3_dir+'/tools/training/software/config/rabat3_wind_init.config'
output_file = rabat3_dir+'/tools/training/software/products/rabat3_training_wind.txt'
data_dir = rabat3_dir+'/data'
trange = ['19950304','20100331']
min_val=0 & max_val=2

train_rabat3,config_file,trange, $
	     data_dir=data_dir, $
	     output_file=output_file, $
	     min_val=0,max_val=2.0
