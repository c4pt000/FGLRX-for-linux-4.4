#!/bin/sh
#
#Purpose: 
#   Prints up-to-date information about the driver, depending on the option passed by the caller
#   --version           prints the driver version
#   --release           prints the driver release
#   --description       prints a description of the driver package
#   --url               prints the driver home URL
#   --vendor            prints ATI's corporation full name
#   --summary           prints driver's summary information

status=0

case "$1" in
--version)
    echo "15.302"
    ;;
--release)
    echo "1"
    ;;
--description)
    echo "Display driver files for the AMD RADEON (9500 and later), MOBILITY RADEON (M10 and later), RADEON XPRESS IGP and FireGL (Z1 and later) series of graphics accelerators.  This package provides 2D display drivers, precompiled kernel modules, kernel module build environment, control panel source coude and hardware accelerated OpenGL."
    ;;
--url)
    echo "http://ati.amd.com/support/driver.html"
    ;;
--vendor)
    echo "AMD: Advanced Micro Devices."
    ;;
--summary)
    echo "X Window display driver for the AMD graphics accelerators"
    ;;
*)
    echo "Unrecognized parameter '$1' to ati-packager-helper.sh"
    status=1
    ;;   
esac

exit ${status}
