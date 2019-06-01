#!/bin/sh
#
# Script to toggle monitors
#
# Note: This script is not part of the Powersave Daemon!
#

getXuser() {
        user=`finger| grep -m1 ":$displaynum " | awk '{print $1}'`

        if [ x"$user" = x"" ]; then
                user=`finger| grep -m1 ":$displaynum" | awk '{print $1}'`
        fi
        if [ x"$user" != x"" ]; then
                userhome=`getent passwd $user | cut -d: -f6`
                export XAUTHORITY=$userhome/.Xauthority
        else
                export XAUTHORITY=""
        fi
}

for x in /tmp/.X11-unix/*; do
    displaynum=`echo $x | sed s#/tmp/.X11-unix/X##`
    getXuser
    if [ x"$XAUTHORITY" != x"" ]; then
        # extract current state
	export DISPLAY=":$displaynum"
	_enabled_monitors=`su $user -c "aticonfig --query-monitor | grep Enabled"`
	_connected_monitors=`su $user -c "aticonfig --query-monitor | grep Connected"`
    fi
done

# determine if lvds is active
echo "${_enabled_monitors}" | grep lvds > /dev/null 2>&1 
if [ $? -eq 0 ]; then
  _lvds_enabled=yes
else
  _lvds_enabled=no
fi

# switch display
if [ "${_lvds_enabled}" = "no" ]; then
  #switch to lvds only if available
  echo "${_connected_monitors}" | grep lvds > /dev/null 2>&1 
  if [ $? -eq 0 ]; then
    echo 1
    su $user -c "aticonfig --enable-monitor lvds"
    echo 2
  else 
    echo "Warning: lvds is not connected"
  fi

else
  _monitors="" 

  #switch to crt+dvi (if available)
  for _type in crt1 crt2 tmds1 tmds2 tv cv; do 
    echo ${_connected_monitors} | grep ${_type} > /dev/null 2>&1 
    if [ $? -eq 0 ]; then
      # Add a comma after the first connected display
      if [ "${_monitors}" != "" ]; then
        _monitors="${_monitors},"
      fi

      _monitors="${_monitors}${_type}"
    fi

  done
  if [ "${_monitors}" != "" ]; then
    echo "Enabling ${_monitors}"
    su $user -c "aticonfig --enable-monitor ${_monitors}"
  else 
    echo "Warning: No monitors available to toggle to"
  fi
fi

exit 0
