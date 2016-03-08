; IDL Batch file to launch rabat3_lesia_processing.pro on Wind/Waves dataset
; To run this batch file, just enter the following command line in the IDL interpreter:
;       @run_rabat3_lesia_wind.batch
;
; NOTE: be sure that the required environment variables are correctly defined.
; (See scripts saved in the /setup sub-directory.)
;
; X.Bonnin, 17-NOV-2014.

rabat3_lesia_dir = getenv('RABAT3_LESIA_DIR')
rabat3_product_dir=getenv('RABAT3_PRODUCT_DIR')
rabat3_config_dir=getenv('RABAT3_CONFIG_DIR')
rabat3_src_dir=getenv('RABAT3_SRC_DIR')
rabat3_lib_dir=getenv('RABAT3_LIB_DIR')

if (rabat3_lesia_dir eq '') or (rabat3_product_dir eq '') or (rabat3_config_dir eq '') or $
(rabat3_src_dir eq '') or (rabat3_lib_dir eq '') then $
    message,'Environment variables for RABAT3_LESIA must be defined!'

;data_dir=rabat3_home_dir+'/data'
data_dir=['/nfs/wind/Data/WIND_Data/CDPP/rad1/l2/average',$
	'/nfs/wind/Data/WIND_Data/CDPP/rad2/l2/average'] ; Sorbet.obspm.fr data path

; Add IDL routine directories to the  !PATH
pathsep = path_sep(/search_path)
!PATH = expand_path('+'+rabat3_src_dir) + pathsep + !PATH
!PATH = expand_path('+'+rabat3_lib_dir+path_sep()+'idl') + pathsep + !PATH
!PATH = expand_path('+'+rabat3_lesia_dir+path_sep()+'prod' + path_sep() + 'wrapper') + pathsep + !PATH

@compile_rabat3_lesia.batch.pro

; Input arguments
config_file=rabat3_config_dir+path_sep()+'rabat3_wind_lig.config'
starttime='19950101'
endtime='20131231'
nfreq=20

rabat3_lesia_processing,config_file,results, $
		      		  starttime=starttime,endtime=endtime,$
		      		  output_dir=rabat3_product_dir,$
                                                      data_dir=data_dir, $
		      		  nfreq=nfreq


