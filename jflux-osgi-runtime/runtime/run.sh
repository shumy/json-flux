#!/bin/bash

cd "$( dirname "${BASH_SOURCE[ 0 ]}" )"

JAVA="java"

# if JAVA_HOME exists, use it
if [ -x "$JAVA_HOME/bin/java" ]
then
  JAVA="$JAVA_HOME/bin/java"
else
  if [ -x "$JAVA_HOME/jre/bin/java" ]
  then
    JAVA="$JAVA_HOME/jre/bin/java"
  fi
fi

"$JAVA"  -cp system-libs/org.osgi.service.component.annotations-1.3.0.jar:system-libs/org.osgi.framework-1.8.0.jar:system-libs/org.apache.felix.main-5.4.0.jar:system-libs/pax-logging-api-1.9.1.jar org.apache.felix.main.Main  "$@"
