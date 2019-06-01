#!/bin/sh
#Purpose: 
#   Enclosed into the <script> element of the installer.
#   It copies necessary preun_<component>.sh, postun_<component>.sh, 
#   and creates <component>.list in ${ATI_UNINST} (from policy layer), therefore
#	helping to keep track of what components have been installed
#   This is only used for the Install Driver->Recommended/Expert option.
#Input:
#	$1 - version of X selected by the user (x???[_64a])
#	$2 - component selected by the user
#Return: 
#   exit 1 if either the uninstallation directory or the log file do not exist
#   exit 0 if no errors
#Assumption: 
#   {SETUP_INSTALLPATH} is a Loki Setup variable visible to all scripts invoked from the installer
#	It is the install path selected by the user in the installer

RunComponentConfig()
{
    . ./component_config.sh $@
}

optiontype=$1
install_root=$2

UN_DIR=${ATI_UNINST}
UN_SCRIPT=fglrx-uninstall.sh
AMD_UN_SCRIPT=amd-uninstall.sh
LOG_FILE=${SETUP_INSTALLPATH}${ATI_LOG}/fglrx-install.log

filelist=${UN_DIR}/${optiontype}.list
install_files=files_${optiontype}

if [ ! -e ${LOG_FILE} ]; then
    # The log file is supposed to be created by create_log.sh
    # If it doesn't exist, return error to the installer
    exit 1   
fi

if [ ! -d "${UN_DIR}" ]; then
   mkdir -p "${UN_DIR}"
fi


# Create component's file list in the uninstall directory
#  this is used to initialize the $files_* variables in $install_files;
#  inst_path_* must be sourced first to ensure that the policy variables are set
. ${TMP_INST_PATH_DEFAULT}
. ${TMP_INST_PATH_OVERRIDE}
RunComponentConfig ${install_root}

touch ${filelist}
if [ ! -e ${filelist} ]; then
	echo "[Error] Unable to create ${filelist}" >> ${LOG_FILE}  
    exit 1   
fi

MD5SUM=`which md5sum`
if [ $? -eq 1 ]; then
	#no md5sum available on system
	MD5SUM=""
fi

eval install_files=\$${install_files}
for f in ${install_files}; do
    echo "`${MD5SUM} ${SETUP_INSTALLPATH}${f}`" >> ${filelist}
done


# copy over policy files
if [ ! -d /etc/ati/ ]; then
   mkdir -p /etc/ati
fi
cp -p ${TMP_INST_PATH_DEFAULT} /etc/ati/inst_path_default
cp -p ${TMP_INST_PATH_OVERRIDE} /etc/ati/inst_path_override
echo "SETUP_INSTALLPATH=$SETUP_INSTALLPATH" >> /etc/ati/inst_path_default

# Copy preun_<component>.sh
if [ -e preun_${optiontype}.sh ]; then
    cp preun_${optiontype}.sh ${UN_DIR}
fi

# Copy postun_<component>.sh
if [ -e postun_${optiontype}.sh ]; then
    cp postun_${optiontype}.sh ${UN_DIR}
fi

# Copy fglrx-uninstall.sh
cp -f ${UN_SCRIPT} ${UN_DIR} 2>/dev/null
chmod u+x ${UN_DIR}/${UN_SCRIPT} 2>/dev/null

# Copy amd-uninstall.sh
cp -f ${AMD_UN_SCRIPT} ${UN_DIR} 2>/dev/null
chmod u+x ${UN_DIR}/${AMD_UN_SCRIPT} 2>/dev/null


# All done
exit 0 
