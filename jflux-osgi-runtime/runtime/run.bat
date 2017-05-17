
@ECHO OFF

cd /d %~dp0

set JAVA="java"

REM if JAVA_HOME exists, use it
if exist "%JAVA_HOME%/bin/java" (
  set JAVA="%JAVA_HOME%/bin/java"
) else (
  if exist "%JAVA_HOME%/jre/bin/java" (
    set JAVA="%JAVA_HOME%/jre/bin/java"
  )
)

%JAVA%  -cp system-libs/org.osgi.service.component.annotations-1.3.0.jar;system-libs/org.osgi.framework-1.8.0.jar;system-libs/org.apache.felix.main-5.4.0.jar;system-libs/pax-logging-api-1.9.1.jar org.apache.felix.main.Main  %*
