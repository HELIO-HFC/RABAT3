#! /bin/csh
#
# Script to load environment variables
# required by RABAT3.
#
# To load this script:
# >source rabat3_setup.example.csh
#
# X.Bonnin, 12-DEC-2013

# Edit the main RABAT3 directory
setenv RABAT3_HOME_DIR $HOME/Work/Projects/VO/HELIO/Services/HFC/devtest/Features/Codes/rabat3/Current

# Define Rabat3 sub-directories
setenv RABAT3_LIB_DIR $RABAT3_HOME_DIR/lib
setenv RABAT3_SRC_DIR $RABAT3_HOME_DIR/src
setenv RABAT3_CONFIG_DIR $RABAT3_HOME_DIR/config
setenv RABAT3_PRODUCT_DIR $RABAT3_HOME_DIR/products
setenv RABAT3_DATA_DIR $RABAT3_HOME_DIR/products
setenv RABAT3_LOG_DIR $RABAT3_HOME_DIR/logs

# Append rabat3 idl library path to $IDL_PATH
setenv IDL_PATH "$IDL_PATH":+$RABAT3_SRC_DIR
setenv IDL_PATH "$IDL_PATH":+$RABAT3_LIB_DIR/idl/aux
setenv IDL_PATH "$IDL_PATH":+$RABAT3_LIB_DIR/idl/data
