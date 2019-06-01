#!/bin/sh
#
# init.d-style example script for controlling the ATI External Events Daemon
#
# Distro maintainers may modify this reference script as necessary to conform
# to their distribution policies, or they may simply substitute their own script
# instead.  This reference script is provided merely as a simple example.
#
# Copyright (c) 2006, ATI Technologies Inc.  All rights reserved.
#
### BEGIN INIT INFO
# Provides:       atieventsd
# Required-Start: acpid xdm
# Required-Stop:  acpid xdm
# Default-Start:  5
# Default-Stop:
# Description:    ATI Events Daemon
### END INIT INFO

. /etc/rc.status

DAEMON_BIN=/usr/sbin/atieventsd
test -x $DAEMON_BIN || exit 5

DAEMONNAME=atieventsd
DAEMONOPTS=""
DAEMONPIDFILE="/var/run/$DAEMONNAME.pid"
DAEMONXAUTHFILE=/var/run/$DAEMONNAME.Xauthority
ATICONFIG="/usr/X11R6/bin/aticonfig"

# First reset status of this service
rc_reset

case "$1" in
    start)
        if [ -n "`pidof $DAEMONNAME`" ]; then
            echo "$DAEMONNAME already started"
            exit
        fi

        #
        # IMPORTANT NOTE
        #
        # Use a private .Xauthority file when starting the
        # daemon to prevent it from clobbering existing
        # display authorizations.
        #

        echo -n "Starting $DAEMONNAME"

        XAUTHORITY=$DAEMONXAUTHFILE /usr/sbin/atieventsd $DAEMONOPTS
        rc_status -v
        DAEMONPID=`pidof $DAEMONNAME`
        echo $DAEMONPID > $DAEMONPIDFILE
        grep EVENT_BUTTON_LID_CLOSED=\"ignore\" /etc/powersave/events &> /dev/null
        if [ $? -eq 0 ]; then
          test -x $ATICONFIG &&  $ATICONFIG --set-policy="handle_lid"
        fi
        ;;

    stop)
        if [ -z "`pidof $DAEMONNAME`" ]; then
            echo "$DAEMONNAME not running"
            exit
        fi

        echo -n "Stopping $DAEMONNAME"

        kill `cat $DAEMONPIDFILE`
        rc_status -v
        rm -f $DAEMONPIDFILE
        ;;

    restart)
        $0 stop
        sleep 1
        $0 start
	rc_status
        ;;

    *)
        echo "$0 {start|stop|restart}"
        exit 1
        ;;
esac

rc_exit
