#!/bin/sh

#
# init.d-style example script for controlling the AMD External Events Daemon
#
# Distro maintainers may modify this reference script as necessary to conform
# to their distribution policies, or they may simply substitute their own script
# instead.  This reference script is provided merely as a simple example.
#
# Copyright (c) 2011 Advanced Micro Devices, Inc.  All rights reserved.
#

#
# Assumes atieventsd is on the default search path
#

DAEMONNAME=atieventsd
DAEMONOPTS=""
DAEMONPIDFILE=/var/run/$DAEMONNAME.pid
DAEMONXAUTHFILE=/var/run/$DAEMONNAME.Xauthority

case "$1" in
    start)
        if [ -n "`pidof $DAEMONNAME`" ]; then
            echo "$DAEMONNAME already started"
            exit -1
        fi

        echo -n "Starting $DAEMONNAME... "

        #
        # IMPORTANT NOTE
        #
        # Use a private .Xauthority file when starting the
        # daemon to prevent it from clobbering existing
        # display authorizations.
        #

        XAUTHORITY=$DAEMONXAUTHFILE $DAEMONNAME $DAEMONOPTS
        DAEMONPID=`pidof $DAEMONNAME`
        echo $DAEMONPID > $DAEMONPIDFILE

        echo "Started"
        ;;

    stop)
        if [ -z "`pidof $DAEMONNAME`" ]; then
            echo "$DAEMONNAME not running"
            exit -1
        fi

        echo -n "Stopping $DAEMONNAME... "

        kill `cat $DAEMONPIDFILE`
        rm -f $DAEMONPIDFILE

        echo "Stopped"
        ;;

    restart)
        $0 stop
        sleep 1
        $0 start
        ;;

    *)
        echo "$0 {start|stop|restart}"
        exit -1
        ;;
esac
