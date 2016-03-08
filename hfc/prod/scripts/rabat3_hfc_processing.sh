#! /bin/bash

# Run the rabat3_hfc_processing.py python script 
# with the input arguments set.
# Usage: sh rabat3_hfc_processing.sh config_file starttime endtime

SRC_DIR=/obs/helio/hfc/frc/rabat3
SCRIPT=$SRC_DIR/lib/python/rabat3_hfc_processing.py

if [ $# -ne 3 ]
then
  echo "Usage: `basename $0` config_file starttime endtime"
  exit 1
fi


CONFIG_FILE=$1
STARTTIME=$2
ENDTIME=$3
OUTPUT_DIR=$SRC_DIR/products
DATA_DIR=$SRC_DIR/data
LOG_FILE=$SRC_DIR/products/rabat3_hfc_processing.log
HISTORY_FILE=$SRC_DIR/products/rabat3_hfc_processing.history
IDL_BIN_FILE=$SRC_DIR/lib/idl/bin/rabat3_processing.sav

python $SCRIPT -V -Q -D -s $STARTTIME -e $ENDTIME \
    -d $DATA_DIR -o $OUTPUT_DIR -l $LOG_FILE \
    -h $HISTORY_FILE -i $IDL_BIN_FILE \
    $CONFIG_FILE