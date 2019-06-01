#!/bin/sh
#
# Copyright (c) 2011, 2012 Advanced Micro Devices, Inc.
#
# Purpose
#    AMD uninstall script for RedHat RPM installs
#
# Usage
#    

printHelp()
{
    echo "AMD  Proprietary Driver Uninstall script supports the following arguments:"
    echo "--help                           : print help messages"
    echo "--force                          : uninstall without checking dependencies"
    echo "--dryrun                         : tests uninstall but does not uninstall"
}


#Function: getUninstallVersion()
#Purpose: return the the current version of this uninstall script
getUninstallVersion()
{
    return 2
}


getInstalledPackages()
{
   _INSTALLED_PKG=`rpm -q %AMD_RHEL_DRV_NAME`
	result=$?
	if [ $result -ne 0 ]; then
		_INSTALLED_PKG=""
	fi 
	
	echo ${_INSTALLED_PKG}
}

doUninstall()
{
	useForce=$1
	doDryRun=$2
	rpmOption=""

   #create an uninstall log file
   UNINSTALL_LOG=/etc/ati/fglrx-uninstall.log
   if [ -f $UNINSTALL_LOG ]; then
      count=0
      #backup last log
      while [ -f "$UNINSTALL_LOG-${count}" ]; do
           count=$(( ${count} + 1 ))
      done
      mv "$UNINSTALL_LOG" "$UNINSTALL_LOG-${count}"
   
   fi
   echo "*** AMD  Proprietary Driver Uninstall Log `date +'%F %H:%M:%S'` ***" > ${UNINSTALL_LOG}

	if [ "$doDryRun" = "Y" ]; then
	   rpmOption="$rpmOption --test"

      echo "Simulating uninstall of AMD  Proprietary Driver."
      echo "Dryrun only, uninstall is not done."
      echo "Dryrun only, uninstall is not done." >> ${UNINSTALL_LOG}
	   
   elif [ "$useForce" = "Y" ]; then
	   rpmOption="$rpmOption --nodeps"

      echo "Forcing uninstall of AMD  Proprietary Driver."
      echo "No integrity verification is done." 
      echo "Forcing uninstall." >> ${UNINSTALL_LOG}

	   
	fi		

	
	#check to make sure rpm is available
	RPM_BIN=`which rpm`
   uninstall_result=0
	if [ -n "${RPM_BIN}" -a -x "${RPM_BIN}" ]; then	
	
	
      for _pkg in `getInstalledPackages`; do
      
         if [ "$useForce" = "Y" ]; then
         
            verifyResult=0
         else
            #do verification
            echo "Executing rpm -V --nodeps ${_pkg}" >> ${UNINSTALL_LOG}
            rpmVerifyResult=`rpm -V --nodeps ${_pkg}`
            verifyResult=$?
            echo ${rpmVerifyResult} >> ${UNINSTALL_LOG}
            
            #workaround for RHEL6 issue bug #668629, verify returns result=0, even though verifyscript fails
            workaround_check=`echo ${rpmVerifyResult} | grep 'warning: %verify'`
            checkMode=`echo ${rpmVerifyResult#*/usr/bin/}`

            if [ $verifyResult -eq 0 -a -z "$workaround_check" ]; then
               verifyResult=0
            #workaround for failure due to Mode change result as SM5DLUGT for amd-console-helper
			elif [ "${checkMode}" = "amd-console-helper" ]; then
			   verifyResult=0
            else
               #check if failure is from changing a config file
               IFSbak=$IFS
               IFS=$'\n'
               verifyResult=0
               for line in ${rpmVerifyResult};
               do
                   #verify result returns in the form of SM5DLUGT c <file>
                   #Where: S is the file size.
                   #       M is the file's mode.
                   #       5 is the MD5 checksum of the file.
                   #       D is the file's major and minor numbers.
                   #       L is the file's symbolic link contents.
                   #       G is the file's group.
                   #       T is the modification time of the file.
                   #       c appears only if the file is a configuration file. This is handy for quickly identifying config files, as they are very likely to change, and therefore, very unlikely to verify successfully.
                   #       <file> is the file that failed verification. The complete path is listed to make it easy to find.      
                   checkConfig=`echo ${line} | cut -d' ' -f3`
                   if [ "${checkConfig}" != "c" ]; then
                       #file is not a config file and should fail verify
                       verifyResult=1
                       break
                   fi               
               done
               IFS=$IFSbak
            fi
         fi
         
         if [ $verifyResult -eq 0 ]; then
            #do uninstall
            
            #verification test passed, do uninstall
            echo "Executing rpm -e ${rpmOption} ${_pkg}" >> ${UNINSTALL_LOG}
            rpm -e ${rpmOption} ${_pkg}
            result=$?
            
            echo "Command result $result" >> ${UNINSTALL_LOG}
               
            if [ $result -ne 0 ]; then
               #uninstall error 
               uninstall_result=1
               echo "Unexpected error occurred with rpm -e ${rpmOption} ${_pkg}" 
            fi
         else
            #verification failed 
            uninstall_result=1
            echo "rpm verification failed." >> ${UNINSTALL_LOG}
         fi
          
		done
		
	else
	   #ERROR
	   uninstall_result=1
		echo "RPM is missing from the system.  Uninstall not completed."
   fi


   if [ $verifyResult -eq 1 ]; then
      echo "One or more files have been altered since installation. "
	   echo "Uninstall not completed. Please see ${UNINSTALL_LOG} for details."

cat - >> ${UNINSTALL_LOG} << UNINSTALL_ERR_END
One or more files have been altered since installation. 
Uninstall not completed.

Run uninstall with dryrun option, 
/usr/share/ati/amd-uninstall.sh --dryrun
to simulate uninstall and get details on which files 
have been altered.

Alternatively, force uninstall, removing 
all installed files without verification by running 
/usr/share/ati/amd-uninstall.sh --force.

Forcing uninstall is not recommended
and may cause system corruption.

UNINSTALL_ERR_END
   else
      if [ "$doDryRun" = "Y" ]; then
         echo "Dryrun uninstall of AMD  Proprietary Driver complete."
         echo "For detailed log of dryrun, please see $UNINSTALL_LOG"
      else 
         echo "Uninstall of AMD  Proprietary Driver complete."
         
         if [ $uninstall_result -ne 0 ]; then
            echo "One or more errors occurred during uninstall." 
         fi         
         
         echo "For detailed log of uninstall, please see $UNINSTALL_LOG"
         echo "System must be rebooted to avoid system instability and potential data loss."
      fi 
   fi

   return $uninstall_result

}


#Starting point of this script, process the {action} argument
useForce=N
doDryRun=N
quick=N
ATI_PRESERVE=N

#check for permissions before continuing
if [ "`whoami`" != "root" ]; then
    echo "[Warning] AMD  Proprietary Driver Uninstall : must be run as root to execute this script"
    exit 1
fi


#get parameters
while [ "$*" != "" ]
do
	#Requested action
	action=$1
	case "${action}" in
	-h | --help)
		printHelp
		exit 0
		;;
	--dryrun)
    	doDryRun=Y    
    	;;
	--force)
    	useForce=Y
    	;;
    --quick)
        #not used by this uninstaller
    	quick=Y
    	;;
    --preserve)
    	ATI_PRESERVE=Y
    	export ATI_PRESERVE
    	;;
	--getUninstallVersion)
    	getUninstallVersion
    	exit $?
    	;;
	*|--*)
    	echo "${action}: unsupported option passed to AMD  Proprietary Driver Uninstall"
    	exit 1
    	;;
	esac
	shift
done

if [ "$doDryRun" = "Y" -a "$useForce" = "Y" ]; then
   echo "AMD  Proprietary Driver does not support"
   echo "--dryrun and --force commands together."
   echo "Please use --dryrun only for uninstall details."
   exit 1
fi

doUninstall $useForce $doDryRun
exit $?

