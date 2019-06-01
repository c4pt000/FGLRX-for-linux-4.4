#!/bin/sh
#
# Copyright (c) 2012 Advanced Micro Devices, Inc.
#
# Purpose
#    AMD script to detect supported GPU prior to installing
#
# Usage
#    

#check if root
if [ "`whoami`" != "root" ]; then
    #do not run this script without root privileges
    #return 0 and installer will handle telling user that they need to be root
    exit 0
fi

#set the log file and other expected file pathes
if [ -n "${TMP_INST_PATH_DEFAULT}" -a -n "${TMP_INST_PATH_OVERRIDE}"  ]; then 
    . ${TMP_INST_PATH_DEFAULT}
    . ${TMP_INST_PATH_OVERRIDE}
    LOG_PATH=${SETUP_INSTALLPATH}${ATI_LOG}
else
    LOG_PATH=/usr/share/ati
fi

if [ ! -e ${LOG_PATH} ]
then
    mkdir -p ${LOG_PATH} 2>/dev/null 
fi

LOG_FILE=${LOG_PATH}/fglrx-install.log

# ensure the working directory is where the script resides
scriptdir=`dirname $0`
curdir=`pwd`
if [ -n "$scriptdir" -a "$scriptdir" != "$curdir" ]; then
    cd "$scriptdir"
fi

if [ `uname -m` = "x86_64" ]; then
    DCM_BIN=amd_dcm64
else
    DCM_BIN=amd_dcm32
fi

# check for detection binary
if [ ! -x "`pwd`/${DCM_BIN}" ]; then
    #no detection binary
    echo "Installer binary, amd_dcm, cannot be located. Installation will not proceed." >> ${LOG_FILE}
    exit 1
fi

# execute binary
./$DCM_BIN >> ${LOG_FILE} 2>&1 
status=$?


exit $status


