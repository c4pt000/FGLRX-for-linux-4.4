#!/bin/sh
#
# Copyright (c) 2008-2009, 2010, 2011 Advanced Micro Devices, Inc.
#
# Purpose: 
#	1. Detect X server version
#	2. Detect system architecture
# Description: 
#	1. The script tries to detect version of X (it has to detect XOrg 6.9.X on most of installations).  
#	The detected version (or diagnostics) is printed out.  Also, variable X_VERSION is set to a string
#	having the following format: "XOrg <major>.<minor>.<x>" (or empty string, if cannot detect X version)
#	2. The script runs 'uname -m" to detect the architechture, prints it out and sets variable _ARCH to the value 
#	returned by uname
# Parameters (can specify these in $1 or $2 or both; order does not matter):
#   --noprint  - the results of the detection are not printed to the screen
#   --nodetect - detection of X_VERSION and _ARCH are skipped; uses X_VERSION
#                and _ARCH from current environment; this also implies that
#                check.sh will not indicate that X_VERSION was specified by the
#                user unless --override is specified
#   --override - (only has effect when --nodetect is specified) specifies that
#                the user overrode X_VERSION so the output should reflect that;
#                by default, check.sh assumes that X_VERSION was not overridden
#                when --nodetect is used
#
#                Rationale for --override:
#                sometimes the calling function will handle the case where the
#                user overrides X_VERSION and then will call check.sh to print
#                out a human-readable X_VERSION and _ARCH so we need some way
#                for the calling function to tell check.sh that the user
#                overrode X_VERSION in order for it to print out the appropriate
#                string to standard out; this setting only has an effect if
#                --nodetect is set since it does not make sense to say that the
#                X_VERSION was overrode when it was, in fact, detected
# Known users: 
#	- end user
# 	- ati-installer.sh
# 	- default_policy.sh
# 	- packages/*/ati-packager.sh (possibly only some of these use it)
# 	- buildpkg.d/b30specfile.sh


# parameter processing; must be done here because it would cause problems if
#  used in the spec file (the part between ###Begin... and ###End... goes in
#  the spec file; see b30specfile.sh for details)

while [ ! -z "$1" ]
do
    PARAM=$1
    case ${PARAM} in
        --noprint)
            if [ -z "${NO_PRINT}" ]; then
                NO_PRINT="1"
            else
                echo "NO_PRINT variable is needed by check.sh but is non-empty"
                exit 1
            fi
            ;;
        --nodetect)
            if [ -z "${NO_DETECT}" ]; then
                NO_DETECT="1"
            else
                echo "NO_DETECT variable is needed by check.sh but is non-empty"
                exit 1
            fi
            ;;
        --override)
            if [ -z "${OVERRIDE}" ]; then
                OVERRIDE="1"
            else
                echo "OVERRIDE variable is needed by check.sh but is non-empty"
                exit 1
            fi
            ;;
        *)
            echo "Unrecognized parameter (${PARAM}) passed to check.sh"
            exit 1
            ;;
    esac
    shift
done


###Begin: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

DetectX()
{
x_binaries="X Xorg"
x_dirs="/usr/X11R6/bin/ /usr/local/bin/ /usr/X11/bin/ /usr/bin/ /bin/"


for the_x_binary in ${x_binaries}; do
    x_full_dirs=""
    for x_tmp in ${x_dirs}; do
        x_full_dirs=${x_full_dirs}" "${x_tmp}${the_x_binary}
    done
    x_full_dirs=${x_full_dirs}" "`which ${the_x_binary}`
    for x_bin in ${x_full_dirs}; do 
        if [ -x ${x_bin} ];
        then
           # try to detect XOrg up to 7.2
           x_ver_num=`${x_bin} -version 2>&1 | grep 'X Window System Version [0-9]\.' | sed -e 's/^.*X Window System Version //' | cut -d' ' -f1`

            if [ -n "$x_ver_num" ]
            then
                X_VERSION="Xorg $x_ver_num"
                x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                x_min=`echo ${x_ver_num} | cut -d '.' -f2`

                if [ ${x_maj} -eq 1 -a ${x_min} -le 3 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"
                    X_VERSION="Xserver $x_ver_num"

                elif [ ${x_maj} -eq 6 -a ${x_min} -eq 9 ]; then
                    x_internal="xpic"
                    X_LAYOUT="monolithic"

                elif [ ${x_maj} -eq 7 -a ${x_min} -le 2 ]; then
                    x_internal="xpic"
                    X_LAYOUT="modular"

                fi

            fi
        

            if [ -z "${X_VERSION}" ]
            then

              
                # XOrg 7.2 or lower has not been detected, try to detect XOrg 7.3 and greater
                x_ver_num=`${x_bin} -version 2>&1 | grep 'X\.Org X Server [0-9]\.[0-9]' | sed -e 's/^.*X\.Org X Server //'`
                X_VERSION="XServer $x_ver_num"
                	
                if [ "$x_ver_num" ]
                then
                    x_maj=`echo ${x_ver_num} | cut -d '.' -f1`
                    x_min=`echo ${x_ver_num} | cut -d '.' -f2`    

		    # Add XServer 1.17 support with user restriction on non-supported version
                    if [ \( ${x_maj} -eq 1 -a ${x_min} -ge 3 \) -a \( ${x_maj} -eq 1 -a ${x_min} -le 18 \) ]; then
                        
                        x_internal="xpic"
                        X_LAYOUT="modular"                        
                    fi
                fi
            fi
        fi
       
        if [ -n "${X_VERSION}" ]
        then
           break
        fi

    done
    
    if [ -n "${X_VERSION}" ]
    then
       break
    fi
done

# Produce the final X version string
if [ -n "${X_VERSION}" ]; then

    if [ "${NO_PRINT}" != "1" ]; then
        echo "X Server: ${X_VERSION}"
    fi
    
    if [ -n "$x_internal" ]; then
        X_VERSION=$x_internal
    fi

fi


}

########################################################################
# Begin of the main script


if [ "${NO_PRINT}" != "1" ]; then
    echo "Detected configuration:"
fi

# Detect system architecture
if [ "${NO_DETECT}" != "1" ]; then
    _ARCH=`uname -m`
fi

if [ "${NO_PRINT}" != "1" ]; then
    case ${_ARCH} in
        i?86)	arch_bits="32-bit";;
        x86_64)	arch_bits="64-bit";;
    esac

    echo "Architecture: ${_ARCH} (${arch_bits})"
fi

# Try to detect version of X, if X_VERSION is not set explicitly by the user
if [ -z "${X_VERSION}" ]; then

    # Detect X version
    if [ "${NO_DETECT}" != "1" ]; then
        DetectX
    
        if [ -z "${X_VERSION}" ]; then
            if [ "${NO_PRINT}" != "1" ]; then
                echo "X Server: unable to detect"
            fi
        elif [ "${_ARCH}" = "x86_64" ]; then
                X_VERSION=${X_VERSION}_64a
                  
        fi
    fi

else
    # If X_VERSION was set by the user, don't try to detect X, just use user's value
    if [ "${NO_PRINT}" != "1" ]; then

        # see --nodetect and --override in check.sh header for explanation
        if [ "${NO_DETECT}" = "1" ]; then
            if [ "${OVERRIDE}" = "1" ]; then
                OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
            else
                OVERRIDE_STRING=""
            fi
        else
            OVERRIDE_STRING=" (OVERRIDEN BY USER)" 
        fi

        if [ -x map_xname.sh ]; then
            echo "X Server${OVERRIDE_STRING}: `./map_xname.sh ${X_VERSION}`"
        else
            echo "X Server${OVERRIDE_STRING}: ${X_VERSION} (lookup failed)"
        fi
    fi
fi

# unset values in case this script is sourced again
unset NO_PRINT
unset NO_DETECT
unset OVERRIDE

###End: check_sh - DO NOT REMOVE; used in b30specfile.sh ###

