#!/bin/sh
#
# Copyright (c) 2012 Advanced Micro Devices, Inc.
#
# Purpose
#    AMD script to detect required tools prior to install
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

echo "Check if system has the tools required for installation." >> ${LOG_FILE}


status=0

#check for kernel header
uname_r=`uname -r`
#Changes related to Kernel 3.7 support where version.h file location has been changed (EPR-369980). 
uname_r_major=${uname_r%%.*}
uname_r_rest=${uname_r#*.}
uname_r_minor=${uname_r_rest%%-*}
uname_r_minor=${uname_r_minor%%.*}

# in /lib/modules/<kernel-version> there is a symlink for latest kernel
# which calls "build" and points to the directory where modules were built.
if  [ "$uname_r_major" -eq 3 -a "$uname_r_minor" -gt 6 ] || [ "$uname_r_major" -eq 4 ]; then
	if [ ! -f /lib/modules/${uname_r}/build/include/generated/uapi/linux/version.h ]; then
		#system does not have the kernel build environment for kernel release > 3.7
		echo "fglrx installation requires that the system have kernel headers for greater than 3.6 release.  /lib/modules/${uname_r}/build/include/generated/uapi/linux/version.h cannot be found on this system." >> ${LOG_FILE}
		status=1
	fi
else
	if [ ! -f /lib/modules/${uname_r}/build/include/linux/version.h ]; then
		#system does not have the kernel build environment
		echo "fglrx installation requires that the system have kernel headers.  /lib/modules/${uname_r}/build/include/linux/version.h cannot be found on this system." >> ${LOG_FILE}
		status=1
	fi
fi

#check for make
make_bin=`which make`
if [ $? -ne 0 -o "$make_bin" = "" ]; then
    #system does not have make 
    echo "fglrx installation requires that the system has make tool. make cannot be found on this system." >> ${LOG_FILE}
    status=1    
fi

#check for gcc
gcc_bin=`which gcc`
if [ $? -ne 0 -o "$gcc_bin" = "" ]; then
    #system does not have gcc 
    echo "fglrx installation requires that the system has gcc tool. gcc cannot be found on this system." >> ${LOG_FILE}
    status=1
fi

#check if forcing install
if [ "$FORCE_ATI_UNINSTALL" = "y" ]; then
    #force install so do not need to fail
    echo "fglrx installation is being forced. Installation will proceed without the required tools on the system." >> ${LOG_FILE}
    exit 0
fi

if [ $status -ne 0 ]; then
    echo "One or more tools required for installation cannot be found on the system. Install the required tools before installing the fglrx driver."  >> ${LOG_FILE}
    echo "Optionally, run the installer with --force option to install without the tools."  >> ${LOG_FILE}
    echo "Forcing install will disable AMD hardware acceleration and may make your system unstable. Not recommended."  >> ${LOG_FILE}
fi

exit $status
