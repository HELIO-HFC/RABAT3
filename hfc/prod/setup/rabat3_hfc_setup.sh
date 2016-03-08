#! /bin/sh

# Script to load environment variables 
# required by RABAT3.
# Must be placed in the rabat3/setup sub-directory. 
#
# To load this script:
# >source rabat3_setup.csh
#
# X.Bonnin, 20-JUN-2013

CURRENT_DIR=`pwd`

ARGS=${BASH_SOURCE[0]}
cd `dirname $ARGS`/..
export RABAT3_HOME_DIR=`pwd`
#echo $RABAT3_HOME_DIR
cd $CURRENT_DIR

# Append rabat3 python library path to $PYTHONPATH
PYTHONPATH=$PYTHONPATH:$RABAT3_HOME_DIR/lib/python/aux
PYTHONPATH=$PYTHONPATH:$RABAT3_HOME_DIR/lib/python/data
export PYTHONPATH

# Append rabat3 idl library path to $IDL_PATH
IDL_PATH=$IDL_PATH:+$RABAT3_HOME_DIR/src
IDL_PATH=$IDL_PATH:+$RABAT3_HOME_DIR/lib/idl/aux
IDL_PATH=$IDL_PATH:+$RABAT3_HOME_DIR/lib/idl/data
export IDL_PATH