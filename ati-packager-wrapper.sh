#!/bin/sh
#Purpose: This script wraps all the packages/distro/ati-packager.sh
#	  This script is called in the gtk/ncurses installer(not the command line --buildpkg action)
#	  enclosed in the <script> element
#	  If error is detected, it will output a standardized erorr message "[Error] extra info..." into
#	  ${ATI_LOG}/fglrx-install.log
#
#Input  :
#	$1 - buildpkg
#	$2 - package name (must be <distro name>/<distro package>
#Return :
#	always exit with 0
#Assumption:
#	{SETUP_INSTALLPATH} is a Loki Setup environment variable(only exists in the scope of the lifetime 
#	of gtk/ncurse installer) It is the install path selected by the user 
#	(any scripts inclosed in <script> </script> in loki can see this variable)

. ${TMP_INST_PATH_DEFAULT}
. ${TMP_INST_PATH_OVERRIDE}

LOG_DIR=${SETUP_INSTALLPATH}${ATI_LOG}
LOG_FILE=${LOG_DIR}/fglrx-install.log
packageinfo=$1
distro=`echo ${packageinfo} | cut -d"/" -f1`
version=`echo ${packageinfo} | cut -d"/" -f2`
./packages/${distro}/ati-packager.sh --buildpkg ${version} >> ${LOG_FILE}
if [ $? != 0 ] 
then
    if [ -e ${LOG_FILE} ]
    then
	echo "[Error] Generate Package - error generating package : ${packageinfo}" >> ${LOG_FILE}  
    fi
fi

exit 0
