#!/bin/sh
#Purpose: in the end of gtk/ncurses installer installtion, grep ${ATI_LOG}/fglrx-install.log for any "[Error]"
#	  messages and return 1 or 0 to determine if a pop-up message should show up to notify the user. 
#	  (pop up message content "There were errors in installation.  Please refer to ${ATI_LOG}/fglrx-install.log for 
#	  more details)
#	  This script is enclosed in <script> element.   
#Input  : none
#Return :
#       0 - if error present   ( gtk/ncurses will show the pop-up)
#       1 - if no error present(gtk/ncurses will no show the pop-up)
LOG_DIR=${SETUP_INSTALLPATH}${ATI_LOG}
LOG_FILE=${LOG_DIR}/fglrx-install.log
#Remove SETUP_INSTALLPATH/LICENSE.TXT, which is usually copied over by Loki Setup(by default) to  
#the install path chosen by the user.  We do not want the license file to linger around, for example under "/"
LICENSE_FILE=${SETUP_INSTALLPATH}/LICENSE.TXT 
if [ -e ${LICENSE_FILE} ]
then

    if [ "`grep 'AMD Software End User License Agreement' ${LICENSE_FILE}`" != "" ]
    then
        rm -f ${LICENSE_FILE} 2>/dev/null 
    fi
fi

#grep ${LOG_FILE} for [Error]
#if not, installer will display a "installation not successful" message in the end
#also tell the user to look into "fglrx-install.log"
if [ -e ${LOG_FILE} ]
then
    error_line=`cat ${LOG_FILE} | grep "^\[Error\]"`
    if [ "${error_line}" = ""	]
    then
	return 1
    else
	return 0
    fi	
else
    return 1
fi
