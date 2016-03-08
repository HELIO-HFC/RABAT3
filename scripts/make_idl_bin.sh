#!/bin/sh

# Produce IDL runtime binary files (called by the rabat3_hfc_processing.py program).
# Usage : sh make_idl_bin.sh target_directory
# X.Bonnin, 20-11-2012

IDL_LIB_DIR=/obs/helio/hfc/frc/rabat3/lib/idl/batch

export RABAT3_IDL_BIN_DIR=$1

# Save rabat3_processing.sav
IDL_BATCH_FILE=$IDL_LIB_DIR/make_rabat3_bin.batch
idl -e @$IDL_BATCH_FILE
