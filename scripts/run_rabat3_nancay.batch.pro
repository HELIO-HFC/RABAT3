; IDL Batch file to launch rabat3_processing.pro on a Nancay Decametric Array file
; To run this batch file, just enter the following command line in the IDL interpreter:
;       @run_rabat3_nancay.batch
;
; NOTE: be sure that the required environment variables are correctly defined.
; (See scripts saved in the /setup sub-directory.)
;
; X.Bonnin, 17-NOV-2014.

; Edit date of the data file by hand
date = '120113' ;YYMMDD
filename = 'S' + date + '.RT1'

VERBOSE = 1b
DISPLAY = 1b
DEBUG = 1b
PREP = 0b

rabat3_home_dir = getenv('RABAT3_HOME_DIR')
rabat3_product_dir=getenv('RABAT3_PRODUCT_DIR')
rabat3_config_dir=getenv('RABAT3_CONFIG_DIR')
rabat3_src_dir=getenv('RABAT3_SRC_DIR')
rabat3_lib_dir=getenv('RABAT3_LIB_DIR')

if (rabat3_home_dir eq '') or (rabat3_product_dir eq '') or (rabat3_config_dir eq '') or $
(rabat3_src_dir eq '') or (rabat3_lib_dir eq '') then $
    message,'Environment variables for RABAT3_LESIA must be defined!'

data_dir = rabat3_home_dir + path_sep() + 'data'

data_file = data_dir + path_sep() + filename
if not (file_test(data_file)) then message,data_file + ' does not exist!'

; Add IDL routine directories to the  !PATH
pathsep = path_sep(/search_path)
!PATH = expand_path('+'+rabat3_src_dir) + pathsep + !PATH
!PATH = expand_path('+'+rabat3_lib_dir+path_sep()+'idl') + pathsep + !PATH

@compile_rabat3.batch.pro

; Input arguments
config_file=rabat3_config_dir+path_sep()+'rabat3_nancay_sht.config'
if not (file_test(config_file)) then message,config_file + ' does not exist!'

output_file = rabat3_product_dir + path_sep() + 'rabat3_nancay_sht_' + date + '_results.sav'

; Run rabat3_processing
rabat3_processing, data_file, config_file, results, $
                                   output_file=output_file, $
                                   PREP=PREP, DEBUG=DEBUG, $
                                   DISPLAY=DISPLAY, VERBOSE=VERBOSE
