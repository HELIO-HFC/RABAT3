#! /bin/sh

DATE=$1
OBSERVATORY=$2

idl -queue -rt=$RADEX_IDL_BIN -args $DATE $OBSERVATORY \
    output_dir=$RADEX_PRODUCT_DIR data_dir=$RADEX_DATA_DIR \
    min_val=0 max_val=20 /NOLOG /YLOG