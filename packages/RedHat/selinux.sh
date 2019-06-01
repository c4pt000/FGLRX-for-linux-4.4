#!/bin/sh
#
# Copyright (c) 2008-2009, 2011 Advanced Micro Devices, Inc.
#
# POSTINSTALLATION
#

###Begin: selinux - DO NOT REMOVE; used in b30specfile.sh ###

# Change security context when SELinux secutiry policy is enforcing.
# Source Context:AAsystem_u:system_r:unconfined_t:SystemLow-SystemHigh
# Target Context:AAsystem_u:object_r:lib_t
# Target Objects:AA$USR_LIB/xorg/modules/drivers/fglrx_drv.so, $USR_LIB/libGL.so.1.2, $USR_LIB/dri/fglrx_dri.so
# Affected RPM Packages:AAglibc, gnome-screensaver, xorg-x11-server [application]
# Policy RPM:AAselinux-policy-2.4.6-30.el5
# Selinux Enabled:AATrue
# Policy Type:AAtargeted
# MLS Enabled:AATrue
# Enforcing Mode:AAEnforcing
# Plugin Name:AAplugins.allow_execmod
#
# Allowing access if you trust share library to run correctly, we need to change the file context to textrel_shlib_t.

# is_selinux()
# SE Linux OS detection (RHEL5, RHEL5.x, etc.)
# The function expect the output from ls --context on a distribution with SELinux as the following 5 fields:
# mode        user group security context                file name
# -rw-r--r--  root root root:object_r:usr_t              /usr/share/ati/fglrx-install.log
# The field $4 on SELinux system is security context and on Non-SELinux system $4 is file name
is_selinux()
{
    local fglrx_log='/usr/share/ati/fglrx-install.log'
    ls --context $fglrx_log 2> /dev/null| awk -v logfile=$fglrx_log '{ print ($4 == logfile) ? "non-selinux" : "selinux" }'
}

if [ "${_ARCH}" = "x86_64" ]; then
       SE_USRLIB=/usr/lib64
else
       SE_USRLIB=/usr/lib
fi

    SE_OS=`is_selinux`

if [ "$SE_OS" = "selinux" ]; then
    echo "...."
    #Change security context if SELINUX is not disabled.
    SE_STAT=`getenforce`
    SELINUX_CMD=`which chcon`
    if [ $? = 0 ] && [ "${SE_STAT}" != "Disabled" ]; then
        ${SELINUX_CMD} -t textrel_shlib_t ${SE_USRLIB}/xorg/modules/drivers/fglrx_drv.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/fglrx/fglrx-libGL.so.1.2
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/dri/fglrx_dri.so
        ${SELINUX_CMD} -t textrel_shlib_t ${SE_USRLIB}/xorg/modules/glesx.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libatiadlxx.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libaticaldd.so
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libAMDXvBA.so.1.0
        ${SELINUX_CMD} -t textrel_shlib_t /usr/lib*/libXvBAW.so.1.0
    fi

    #Redhat assumes libGL.so.1.2 of fglrx is at "/usr/lib(64)?/fglrx/libGL\.so(\.[^/]*)*)".
    #Workaround the problem by change file_contexts.local file for Now. May need to contact Redhat.
    CONTEXT_LOCAL="/etc/selinux/targeted/contexts/files/file_contexts.local"
    grep "/usr/lib(64)?/fglrx/fglrx-libGL.so.1.2" ${CONTEXT_LOCAL} >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "/usr/lib(64)?/fglrx/fglrx-libGL.so.1.2 system_u:object_r:textrel_shlib_t:s0" >> ${CONTEXT_LOCAL}
    fi
    grep "/usr/lib(64)?/xorg/modules/glesx.so" ${CONTEXT_LOCAL} >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "/usr/lib(64)?/xorg/modules/glesx.so system_u:object_r:textrel_shlib_t:s0" >> ${CONTEXT_LOCAL}
    fi
fi

echo "[Message] Driver : End of installation " >> ${LOG_FILE}
exit 0;

###End: selinux - DO NOT REMOVE; used in b30specfile.sh ###
