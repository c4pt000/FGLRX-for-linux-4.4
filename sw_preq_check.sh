#!/bin/bash
# SCRIPT:  sw_preq_check.sh
# PURPOSE: To find the pre-requisites required for Loki while installing the AMD Linux Graphics Driver.


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

#flags to popup the message in GUI and console mode if any pre-requisite is missing
gstatus=0
idstatus=0
pgstatus=0
#flag to set to the main thread for aborting install if occurs
pstatus=0
rstatus=0

#Finding OS Version and OS Type

CURR_OS_NAME=$(lsb_release -i | awk '{ print $3 }')
#echo "$CURR_OS_NAME"

CURR_OS_VERSION=$(lsb_release -r | awk '{ print $2 }')
#echo "$CURR_OS_VERSION"

# Configuration file
FILENAME="sw_preq_check_config"

#The RedHat distribution name will be long and cut it to just RedHat only to read from config file
if [[ ${CURR_OS_NAME} == RedHat* ]]; then
CURR_OS_NAME=RedHat
fi

#find the version from config file, if not available then make it to default.
VER_INFO=$(cat $FILENAME | grep $CURR_OS_VERSION)
#echo $VER_INFO
if [ "" = "$VER_INFO" ]; then
CURR_OS_VERSION=any
fi

# Filter the required line from the Configuration file
XML_DATA=$(cat $FILENAME | grep $CURR_OS_NAME | grep $CURR_OS_VERSION)
#echo $XML_DATA

LOOP=0
if [ "" != "$XML_DATA" ]; then
	#echo $XML_DATA

	arr=$(echo $XML_DATA | tr ";" "\n")

	for m in $arr
	do
		 LOOP=`expr $LOOP + 1`

		#to read the file path
		 if [ 3 = "$LOOP" ]; then
			FILE_NAME_ARR=$(echo $m | tr "=" "\n")
			#echo "$FILE_NAME_ARR"

			for file in $FILE_NAME_ARR

			do
	 	 		FILE_NAME=$file				
			done

			#echo "$FILE_NAME"
		 fi

		#to read the command string
		 if [ 4 = "$LOOP" ]; then
			COMMAND_NAME_ARR=$(echo $m | tr "=" "\n")
			#echo "$FILE_NAME_ARR"

			for cmd in $COMMAND_NAME_ARR

			do
	 	 		COMMAND_NAME=$cmd				
			done

			#echo "$COMMAND_NAME"
		 fi

		#to read the search pattern string
		 if [ 5 = "$LOOP" ]; then
			SEARCH_NAME_ARR=$(echo $m | tr "=" "\n")
			#echo "$FILE_NAME_ARR"

			for ser in $SEARCH_NAME_ARR

			do
	 	 		SEARCH_NAME=$ser				
			done

			#echo "$SEARCH_NAME"
		 fi		 		 				
	done
#fi

IS_X_SERVER_RUNNING=$(pidof X)

if [ -f $FILE_NAME ]; then

SEARCH_OUTPUT=$(cat $FILE_NAME | grep $SEARCH_NAME)
#echo $SEARCH_OUTPUT

if [ "$IS_X_SERVER_RUNNING" != "" ]; then
	if [ "" = "$SEARCH_OUTPUT" ]; then
		#echo "X-server is running"
		gstatus=1
		echo "Language packs are missing from your system, Install and apply language packs before continuing with the installation of the AMD Proprietary Driver. To install and apply the language packs, go to System Settings -> Language Support, will install default packages, click Apply System-Wide button, and then restart your system" >> ${LOG_FILE}
	fi

fi

fi
################################################
# ensure the working directory is where the script resides
scriptdir=`dirname $0`
curdir=`pwd`
if [ -n "$scriptdir" -a "$scriptdir" != "$curdir" ]; then
    cd "$scriptdir"
fi

echo "NOTE: If your system has logged the missing packages required for installation, install them in the order as per the log file to resolve package-dependency issues." >> ${LOG_FILE}

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
		echo "fglrx installation requires that the system has kernel headers for greater than 3.6 release.  "/lib/modules/${uname_r}/build/include/generated/uapi/linux/version.h" cannot be found on this system." >> ${LOG_FILE}
		if [ "$CURR_OS_NAME" = "Ubuntu" ]; then
			    echo "Install kernel headers using the command "apt-get install linux-headers-$(uname -r)"." >> ${LOG_FILE}
		fi

		if [ "$CURR_OS_NAME" = "RedHat" ]; then
			    echo "Install kernel headers using the command "yum install kernel-devel"." >> ${LOG_FILE}
		fi
		idstatus=1
		pgstatus=1
	fi
else
	if [ ! -f /lib/modules/${uname_r}/build/include/linux/version.h ]; then
		#system does not have the kernel build environment
		echo "fglrx installation requires that the system has kernel headers.  "/lib/modules/${uname_r}/build/include/linux/version.h" cannot be found on this system." >> ${LOG_FILE}
		if [ "$CURR_OS_NAME" = "Ubuntu" ]; then
			    echo "Install kernel headers using the command "apt-get install linux-headers-$(uname -r)"." >> ${LOG_FILE}
		fi

		if [ "$CURR_OS_NAME" = "RedHat" ]; then
			    echo "Install kernel headers using the command "yum install kernel-devel"." >> ${LOG_FILE}
		fi
		idstatus=1
		pgstatus=1
	fi
fi

#check for make
make_bin=`which make`
if [ $? -ne 0 -o "$make_bin" = "" ]; then
    #system does not have make 
    echo "fglrx installation requires that the system has "make tool". "make" cannot be found on this system." >> ${LOG_FILE}
		if [ "$CURR_OS_NAME" = "Ubuntu" ]; then
			    echo "Install "make tool" using command "apt-get install make"." >> ${LOG_FILE}
		fi

		if [ "$CURR_OS_NAME" = "RedHat" ]; then
			    echo "Install "make tool" using command "yum install make"." >> ${LOG_FILE}
		fi
    idstatus=1    
    pgtatus=1
fi

#check for gcc
gcc_bin=`which gcc`
if [ $? -ne 0 -o "$gcc_bin" = "" ]; then
    #system does not have gcc 
    echo "fglrx installation requires that the system has "gcc tool". "gcc" cannot be found on this system." >> ${LOG_FILE}
		if [ "$CURR_OS_NAME" = "Ubuntu" ]; then
			    echo "Install "gcc tool" using command "apt-get install gcc"." >> ${LOG_FILE}
		fi

		if [ "$CURR_OS_NAME" = "RedHat" ]; then
			    echo "Install "gcc tool" using command "yum install gcc"." >> ${LOG_FILE}
		fi
    idstatus=1
    pgtatus=1
fi

#check on redhat machine for specific packages
if [ "$CURR_OS_NAME" = "RedHat" ]; then
	#echo "$CURR_OS_NAME"
	rh_package1=$(rpm -qa | grep compat-libstdc++-33)
	#echo $rh_package1
	if [ "" = "$rh_package1" ]; then
		pgstatus=1
		echo "Package compat-libstdc++ is missing from the system. Download the architecture-specific compat-libstdc++-33-*.rpm package and Install it using the command "rpm -ivh compat-libstdc++-33-*.rpm" where * is version."  >> ${LOG_FILE}
	fi
fi


#check on Ubuntu machine for specific packages
if [ "$CURR_OS_NAME" = "Ubuntu" ]; then
	#echo "$CURR_OS_NAME"
	#check for dh-modaliases
	u_package1=$(dpkg --get-selections | grep dh-modaliases)
	#echo $u_package1
	if [ "" = "$u_package1" ]; then
		pgstatus=1
		echo "Package dh-modaliases is missing from the system. Install it using the command apt-get install dh-modaliases." >> ${LOG_FILE}
	fi
	#check for execstack
	u_package2=$(dpkg --get-selections | grep execstack)
	#echo $u_package2
	if [ "" = "$u_package2" ]; then
		pgstatus=1
		echo "Package execstack is missing from the system. Install it using the command apt-get install execstack." >> ${LOG_FILE}
	fi
	#check for dpkg-dev
	u_package3=$(dpkg --get-selections | grep dpkg-dev)
	#echo $u_package3
	if [ "" = "$u_package3" ]; then
		pgstatus=1
		echo "Package dpkg-dev is missing from the system. Install it using the command apt-get install dpkg-dev." >> ${LOG_FILE}
	fi
	#check for debhelper
	u_package4=$(dpkg --get-selections | grep debhelper)
	#echo $u_package4
	if [ "" = "$u_package4" ]; then
		pgstatus=1
		echo "Package debhelper is missing from the system. Install it using the command apt-get install debhelper." >> ${LOG_FILE}
	fi
	#check for dkms dependencies
	u_package5=$(dpkg --get-selections | grep dkms)
	#echo $u_package5
	if [ "" = "$u_package5" ]; then
		pgstatus=1
		echo "Package dkms is missing from the system. Install it using the command apt-get install dkms." >> ${LOG_FILE}
	fi

	#check for lib32gcc1 dependencies
	u_package6=$(dpkg --get-selections | grep lib32gcc1)
	#echo $u_package6
	if [ "" = "$u_package6" ]; then
		arch_var=$(uname -m)
		if [ "$arch_var" = "x86_64" ]; then
		pgstatus=1
		echo "Package lib32gcc1 is missing from the system. Install it using the command apt-get install lib32gcc1." >> ${LOG_FILE}
		fi
	fi

fi
################################################
if [ "$IS_X_SERVER_RUNNING" != "" ]; then
		#echo "X-server is running"
	if [ $pgstatus -ne 0 ]; then
		rstatus=2
	fi
	if [ $idstatus -ne 0 -o $gstatus -ne 0 ]; then
		rstatus=1
	fi	
	if [ $rstatus = "2" ]; then
		pstatus=0
		ZENITY_BIN=`which zenity 2> /dev/null`
                     if [ `id -u` -eq 0 -a -n "${ZENITY_BIN}" -a -x "${ZENITY_BIN}" ]; then
                        ${ZENITY_BIN} --warning --text "Please install the required pre-requisites for package generation before proceeding with AMD Proprietary Driver installation. Please check file usr/share/ati/fglrx-install.log for more details."
		     fi
	fi

        if [ $rstatus = "1" ]; then
		pstatus=1
		ZENITY_BIN=`which zenity 2> /dev/null`
                     if [ `id -u` -eq 0 -a -n "${ZENITY_BIN}" -a -x "${ZENITY_BIN}" ]; then
                        ${ZENITY_BIN} --error --text "Please install the required pre-requisites before proceeding with AMD Proprietary Driver installation. Please check file usr/share/ati/fglrx-install.log for more details."
		     fi
        fi

else
	if [ $pgstatus -ne 0 ]; then
		rstatus=2
	fi
	if [ $idstatus -ne 0 ]; then
		rstatus=1
	fi
	if [ $rstatus = "2" ]; then
			pstatus=0
			#echo "Console is running"
			echo "WARNING: Please install the required pre-requisites for package generation before proceeding with AMD Proprietary Driver installation. Please check file usr/share/ati/fglrx-install.log for more details."
	fi

	if [ $rstatus = "1" ]; then
			pstatus=1
			#echo "Console is running"
			echo "ERROR: Please install the required pre-requisites before proceeding with AMD Proprietary Driver installation. Please check file usr/share/ati/fglrx-install.log for more details."
	fi


fi

fi

exit $pstatus
