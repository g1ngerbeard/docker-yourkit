#!/bin/sh

# ------------------------------------------------------------------------------
# YourKit Java Profiler startup script
# ------------------------------------------------------------------------------

if [ "`uname -a | grep Linux`" ] ; then
  Y0=`readlink -f "$0"`
else
  Y0=`readlink "$0" 2>/dev/null`
fi
if [ -z "$Y0" ] ; then
  Y0="$0"
fi

YH="$YOURKIT_HOME"
if [ -z "$YH" ] ; then
  YH="$HOME"
fi

YD=`dirname "$Y0"`/..

# handle JVM crash
if [ "$1" = "-on_error" ] && [ ! -z "$2" ]; then
  ERROR_PID="$2"

  # indicate the crash

  echo > $YH/.yjp/log/crash_marker_$ERROR_PID.log

  # copy crash log to the profiler log directory:
  # - HotSpot
  cp hs_err_pid$ERROR_PID.log         $YH/.yjp/log/                        2>/dev/null
  # - IcedTea
  cp /tmp/jvm-$ERROR_PID/hs_error.log $YH/.yjp/log/hs_error_$ERROR_PID.log 2>/dev/null

  # restart if needed

  MARKER="/tmp/yjp_ui_marker_$ERROR_PID"
  if [ -f "$MARKER" ] ; then
    rm $MARKER

    # close the dock icon
    kill -9 "$ERROR_PID"

    # continue for a restart
  else
    exit 0
  fi
fi

if [ ! -z "$YJP_JAVA_HOME" ] ; then
  JAVA_EXE="$YJP_JAVA_HOME/bin/java"
elif [ "`uname -a | grep HP-UX`" ] ; then
  JAVA_EXE="/opt/java7/bin/java"
elif [ "`uname | grep SunOS`" ] ; then
  JAVA_EXE="/usr/jdk/latest/bin/java"
elif [ "`uname | grep FreeBSD`" ] ; then
  JAVA_EXE="/usr/local/openjdk7/bin/java"
elif [ "`uname -a | grep Linux`" ] ; then
  # Any Linux
  if [ "`uname -m | grep x86_64`" ] || [ "`uname -i | grep 86`" ] ; then
    # Intel
    if [ "`getconf LONG_BIT | grep 64`" ] ; then
      JAVA_EXE="$YD/jre64/bin/java"
    fi
  fi
fi

if [ ! -r "$JAVA_EXE" ] && [ ! -z "$JAVA_HOME" ] ; then
  JAVA_EXE="$JAVA_HOME/bin/java"
fi

if [ ! -r "$JAVA_EXE" ] ; then
  JAVA_EXE=java
fi

# Solaris and HP-UX always support 64-bit processing
if [ "`uname | grep SunOS`" ] || [ "`uname -a | grep HP-UX`" ] ; then
  JAVA_EXE="$JAVA_EXE -d64"
fi

JAVA_VERSION="`$JAVA_EXE -version 2>&1`"

if [ -z "`echo $JAVA_VERSION | grep version`" ] ; then
  echo "Cannot find Java to run YourKit Java Profiler."
  echo "Java search priority:"
  echo " - environment variable YJP_JAVA_HOME, if set;"
  if [ "`uname -a | grep Linux`" ] ; then
    if [ "`uname -m | grep x86_64`" ] || [ "`uname -i | grep 86`" ] ; then
      echo " - bundled JRE, if exists;"
    fi
  elif [ "`uname | grep SunOS`" ] || [ "`uname -a | grep HP-UX`" ] ; then
    echo " - system default Java, if available;"
  fi
  echo " - environment variable JAVA_HOME, if set;"
  echo " - 'java' in PATH, if found."
  exit
fi

unset JAVA_TOOL_OPTIONS

if [ "`echo $JAVA_VERSION | grep 64-Bit`" ] ; then
  # 64-Bit Java

  JAVA_HEAP_LIMIT="-Xmx4G"

  # Set PermGen for pre-Java 8
  if [ "`echo $JAVA_VERSION | grep 1.6`" ] || [ "`echo $JAVA_VERSION | grep 1.7`" ] ; then
    JAVA_HEAP_LIMIT="$JAVA_HEAP_LIMIT -XX:PermSize=256m -XX:MaxPermSize=256m"
  fi
else
  # 32-Bit Java

  JAVA_HEAP_LIMIT="-Xmx700m"

  # Set PermGen for pre-Java 8
  if [ "`echo $JAVA_VERSION | grep 1.6`" ] || [ "`echo $JAVA_VERSION | grep 1.7`" ] ; then
    JAVA_HEAP_LIMIT="$JAVA_HEAP_LIMIT -XX:PermSize=64m -XX:MaxPermSize=64m"
  fi
fi

# If you use Xmonad window manager, uncomment next 3 lines:
# _JAVA_AWT_WM_NONREPARENTING=1
# export _JAVA_AWT_WM_NONREPARENTING
# wmname LG3D

if [ -e "$YH/.yjp/ui.ini" ] ; then
  INI_PARAMS="`cat $YH/.yjp/ui.ini | grep -v '#'`"
else
  INI_PARAMS="-Dyjp.no.ui.ini"
fi

if [ "`uname -a | grep Darwin`" ] ; then
  UI_PARAMS=-Dapple.laf.useScreenMenuBar=true
else
  UI_PARAMS=
fi

ON_ERROR="-XX:OnError=$YD/bin/yjp.sh -on_error %p"

if [ "`echo $@ | grep ideport`" ] || [ "`echo $@ | grep restart_for_update`" ] ; then
  if [ `uname` = "Darwin" ] ; then
    "$YD/../MacOS/yjp_mac" &
  else
    exec $JAVA_EXE $JAVA_HEAP_LIMIT $INI_PARAMS $UI_PARAMS "$ON_ERROR" -jar "$YD/lib/yjp.jar" $1 $2 $3 $4 $5 $6 $7 $8 $9 &
  fi
else
  exec $JAVA_EXE $JAVA_HEAP_LIMIT $INI_PARAMS $UI_PARAMS "$ON_ERROR" -jar "$YD/lib/yjp.jar" $1 $2 $3 $4 $5 $6 $7 $8 $9
fi
