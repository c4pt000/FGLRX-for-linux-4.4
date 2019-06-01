#!/bin/sh
#Purpose: Post-install configure the driver with aticonfig --initial if not currently configured
#	  This script is enclosed in <script> element before the verify_install.sh is called.   
#Input  : none


# Process security context
sh ./packages/RedHat/selinux.sh 2>/dev/null
	
###Begin: config_install_sh - DO NOT REMOVE; used in post.sh ###

if [ -z "$NoAMDXorg" ]; then
		ATICONFIG_BIN=`which aticonfig` 2> /dev/null
		if [ -n "${ATICONFIG_BIN}" -a -x "${ATICONFIG_BIN}" ]; then

		   ${ATICONFIG_BIN} --initial=check > /dev/null
		   if [ $? -eq 1 ]; then
			  # Suppress output identifying backup creation as this will affect the installer text output
			  ${ATICONFIG_BIN} --initial > /dev/null
		   fi

		fi
else
#We will revert libGL links which we have created during installation of driver
#so atleast compute test cases will work with native X libs.
#this is the case when user passed with "--NoAMDXorg" parameter passed to RUN file
	echo "Reverting of libGL libraries..." >> /etc/ati/NoAMDXorg
	
	if [ "`cat /etc/*-release | grep -i "Ubuntu"`" ]
	then 
		unlink /usr/lib32/libGL.so 2>> /dev/null
		unlink /usr/lib32/libGL.so.1 2>> /dev/null
		unlink /usr/lib32/libGL.so.1.2 2>> /dev/null
	
		unlink /usr/lib/i386-linux-gnu/libGL.so 2>> /dev/null
		unlink /usr/lib/i386-linux-gnu/libGL.so.1 2>> /dev/null
		unlink /usr/lib/i386-linux-gnu/libGL.so.1.2 2>> /dev/null
		rm -rf /usr/lib/i386-linux-gnu/fglrx 2>> /dev/null

		unlink /usr/lib/libGL.so 2>> /dev/null
		unlink /usr/lib/libGL.so.1 2>> /dev/null
		unlink /usr/lib/libGL.so.1.2 2>> /dev/null
		rm -rf /usr/lib/fglrx 2>> /dev/null
		if [ -f /usr/lib/i386-linux-gnu/mesa/FGL.renamed.libGL.so.1.2.0 ]
		then 
			cp /usr/lib/i386-linux-gnu/mesa/FGL.renamed.libGL.so.1.2.0 /usr/lib/i386-linux-gnu/mesa/libGL.so.1.2.0 
			ln -sf /usr/lib/i386-linux-gnu/mesa/libGL.so.1.2.0 /usr/lib/i386-linux-gnu/mesa/libGL.so.1 2>> /dev/null
		fi

		if [ -f /usr/lib/x86_64-linux-gnu/mesa/FGL.renamed.libGL.so.1.2.0 ]
		then 
			 cp /usr/lib/x86_64-linux-gnu/mesa/FGL.renamed.libGL.so.1.2.0 /usr/lib/x86_64-linux-gnu/mesa/libGL.so.1.2.0
			ln -sf /usr/lib/x86_64-linux-gnu/mesa/libGL.so.1.2.0 /usr/lib/x86_64-linux-gnu/mesa/libGL.so.1 2>> /dev/null
		fi
		rm -rf /usr/lib/xorg/modules/drivers/fglrx_drv.so 2>> /dev/null

		unlink /usr/lib/xorg/modules/extensions/libglx.so 2>> /dev/null
		rm -rf /usr/lib/xorg/modules/extensions/fglrx 2>> /dev/null
		mv /usr/lib/xorg/modules/extensions/FGL.renamed.libglx.so /usr/lib/xorg/modules/extensions/libglx.so 
		ldconfig
	else
		#non-Ubuntu
		if [ -f /usr/lib/NoAMDXorgBak/libGL.so.1.2.0 ];then
			cp -f /usr/lib/NoAMDXorgBak/libGL.so.1.2.0 /usr/lib/libGL.so.1.2.0 2>> /dev/null
			ln -sf /usr/lib/libGL.so.1.2.0 /usr/lib/libGL.so.1 2>> /dev/null
		fi
		if [ -f /usr/lib64/NoAMDXorgBak/libGL.so.1.2.0 ];then
			cp -f /usr/lib64/NoAMDXorgBak/libGL.so.1.2.0 /usr/lib64/libGL.so.1.2.0 2>> /dev/null
			ln -sf /usr/lib64/libGL.so.1.2.0 /usr/lib64/libGL.so.1 2>> /dev/null
		fi

		unlink /usr/lib/libGL.so.1.2 2>> /dev/null
		rm -rf /usr/lib/xorg/modules/drivers/fglrx_drv.so 2>> /dev/null
	
		if [ -f /etc/redhat-release ]
		then
			unlink /usr/lib64/xorg/modules/extensions/libglx.so 2>> /dev/null
			mv /usr/lib64/xorg/modules/extensions/FGL.renamed.libglx.so /usr/lib64/xorg/modules/extensions/libglx.so 2>> /dev/null
		elif [ -f /etc/SuSE-release ]
		then
			if [ -f /usr/lib64/xorg/modules/extensions/FGL.renamed.libglx.so ]; then
				unlink /usr/lib64/xorg/modules/extensions/libglx.so 2>> /dev/null
				mv /usr/lib64/xorg/modules/extensions/FGL.renamed.libglx.so /usr/lib64/xorg/modules/extensions/libglx.so 2>> /dev/null
			fi
			if [ -f /etc/alternatives/libglx.so ];then
				ln -sf /etc/alternatives/libglx.so /usr/lib64/xorg/modules/extensions/libglx.so 2>> /dev/null
			fi
		fi
		if [ -f /usr/lib/xorg/modules/extensions/FGL.renamed.libglx.so ]; then
				unlink /usr/lib/xorg/modules/extensions/libglx.so 2>> /dev/null
				mv /usr/lib/xorg/modules/extensions/FGL.renamed.libglx.so /usr/lib/xorg/modules/extensions/libglx.so 2>> /dev/null
		fi
		rm -rf /usr/lib/NoAMDXorgBak 2>> /dev/null
		rm -rf /usr/lib64/NoAMDXorgBak 2>> /dev/null
	fi
fi

###End: config_install_sh - DO NOT REMOVE; used in post.sh ###
