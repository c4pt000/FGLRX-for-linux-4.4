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

echo "Check if system has the tools required for Packages Generation." >> ${LOG_FILE}


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
		echo "fglrx installation requires that the system have kernel headers for 3.7 release.  /lib/modules/${uname_r}/build/include/generated/uapi/linux/version.h cannot be found on this system." >> ${LOG_FILE}
		status=1
		echo "" >> ${LOG_FILE}
	fi
else
	if [ ! -f /lib/modules/${uname_r}/build/include/linux/version.h ]; then
		#system does not have the kernel build environment
		echo "fglrx installation requires that the system have kernel headers.  /lib/modules/${uname_r}/build/include/linux/version.h cannot be found on this system." >> ${LOG_FILE}
		status=1
		echo "" >> ${LOG_FILE}
	fi
fi

#check for make
make_bin=`which make`
if [ $? -ne 0 -o "$make_bin" = "" ]; then
    #system does not have make 
    echo "fglrx installation requires that the system has make tool. make cannot be found on this system." >> ${LOG_FILE}
    status=1    
    echo "" >> ${LOG_FILE}
fi

#check for gcc
gcc_bin=`which gcc`
if [ $? -ne 0 -o "$gcc_bin" = "" ]; then
    #system does not have gcc 
    echo "fglrx installation requires that the system has gcc tool. gcc cannot be found on this system." >> ${LOG_FILE}
    status=1
    echo "" >> ${LOG_FILE}
fi

#check if forcing install
if [ "$FORCE_ATI_UNINSTALL" = "y" ]; then
    #force install so do not need to fail
    echo "fglrx installation is being forced. Installation will proceed without the required tools on the system." >> ${LOG_FILE}
    exit 0
fi

if [ `cat /etc/*-release | grep "SuSE" ` ]; then 
	distro="SuSE"
elif [ `cat /etc/*-release | grep "Red Hat" ` ]; then 
	distro="RHEL"
fi

if [ "$distro" = "SuSE" -o "$distro" = "RHEL" ];
then
	
	gcc_bin=`which rpmbuild`
	if [ $? -ne 0 -o "$gcc_bin" = "" ]; then
	    #system does not have rpmbuild 
	    echo "To build RPM packages 'rpmbuild' software package is necessary. Please install it either from DVD or download from any website." >> ${LOG_FILE}
	    echo "On Red Hat, please run commnad : "sudo yum install rpm-build" <we presume, you have RedHat registration. Otherwise create local repo from DVD> " >> ${LOG_FILE}
	    echo "On SuSE, please run commnad: "sudo zypper install rpm-build" <we presume, you have DVD in CD drive>" >> ${LOG_FILE}
	    echo "Please look in to "Installer Notes" for further information" >> ${LOG_FILE}
    	    echo "" >> ${LOG_FILE}
	    status=1
	fi
fi

if [ "$distro" = "SuSE" -o "$distro" = "RHEL" ]; then 
	gcc_bin=`rpm -qa | grep kernel-devel`
        if [ $? -ne 0 -o "$gcc_bin" = "" ]; then
		#system doesn't have kernel development packags which is madatory
		echo ""
		echo "To build kernel modules of AMD, system needs Kernel-Development package to be installed" >> ${LOG_FILE}
		echo "Please run command: "sudo zypper install kernel-devel" <we presume, you have DVD in the CD driver>" >> ${LOG_FILE}
		status=1
                echo "" >> ${LOG_FILE}
	fi
fi
if [ $status -ne 0 ]; then
    echo "One or more tools required for Graphics Pacakges Generation are not found on the system. Recommended is to install the required tools for successful package generation."  >> ${LOG_FILE}
    echo "Optionally, you can run commands to ignore these dependecies but end result may not be as expected. Not recommended"  >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
fi

exit $status
