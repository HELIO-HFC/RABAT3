;IDL batch file to build an binary runtime file (.sav)
;to run rabat3 code using a command line or a script.
;X.Bonnin, 13-APR-2012

sep = path_sep()

rabat3_dir = '/obs/helio/hfc/frc/rabat3'
target_dir=getenv('RABAT3_IDL_BIN_DIR')
if (target_dir eq '') then target_dir=rabat3_dir+'/lib/idl/bin'

pathsep = path_sep(/search_path) 
!PATH = expand_path('+'+rabat3_dir+'/src') + pathsep + !PATH
!PATH = expand_path('+'+rabat3_dir+'/lib/idl') + pathsep + !PATH

@/obs/helio/hfc/frc/rabat3/lib/idl/batch/compile_rabat3.batch

.compile mpfitfun
resolve_all, /CONTINUE_ON_ERROR
filename = target_dir + sep + 'rabat3_processing.sav'
save, /ROUTINES, filename=filename, $
      description='Runtime IDL program to call rabat3_processing.pro', $
      /VERBOSE, /EMBEDDED
print,filename+' saved'
