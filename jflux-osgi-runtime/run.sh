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

cd ./runtime
"$JAVA" -Dorg.ops4j.pax.logging.DefaultServiceLog.level=INFO -Dio.netty.processId=$$ -cp "system-libs/*" org.apache.felix.main.Main "$@"
