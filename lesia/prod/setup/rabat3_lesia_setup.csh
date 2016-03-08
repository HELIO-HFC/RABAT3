#! /bin/csh
#
# Script to load environment variables
# required by RABAT3 LESIA.
#
# To load this script:
# >source rabat3_lesia_setup.csh
#
# X.Bonnin, 12-DEC-2013

set CURRENT_DIR=`pwd`

# Define Rabat3 home directory
set ARGS=`/usr/sbin/lsof +p $$ | grep -oEi /.\*rabat3_lesia_setup.csh`
cd `dirname $ARGS`/..
setenv RABAT3_HOME_DIR `pwd`
cd $CURRENT_DIR

# Append rabat3 python library path to $PYTHONPATH
setenv PYTHONPATH "$PYTHONPATH":$RABAT3_HOME_DIR/lib/python/aux
setenv PYTHONPATH "$PYTHONPATH":$RABAT3_HOME_DIR/lib/python/data
setenv PYTHONPATH "$PYTHONPATH":$RABAT3_HOME_DIR/lesia/prod

# Append rabat3 idl library path to $IDL_PATH
setenv IDL_PATH "$IDL_PATH":+$RABAT3_HOME_DIR/src
setenv IDL_PATH "$IDL_PATH":+$RABAT3_HOME_DIR/lib/idl/aux
setenv IDL_PATH "$IDL_PATH":+$RABAT3_HOME_DIR/lib/idl/data
setenv IDL_PATH "$IDL_PATH":+$RABAT3_HOME_DIR/lesia/prod
