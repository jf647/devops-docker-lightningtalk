#
# One way to set the STASH HOME path is here via this variable.  Simply uncomment it and set a valid path like
# /stash/home.  You can of course set it outside in the command terminal; that will also work.
#
STASH_HOME="/opt/stash-home"

#
# Occasionally Atlassian Support may recommend that you set some specific JVM arguments.  You can use this variable
# below to do that.
#
JVM_SUPPORT_RECOMMENDED_ARGS=""

#
# The following 2 settings control the minimum and maximum given to the Atlassian Stash Java virtual machine.
# In larger Stash instances, the maximum amount will need to be increased.
#
JVM_MINIMUM_MEMORY="256m"
JVM_MAXIMUM_MEMORY="384m"

#
# File encoding passed into the Atlassian Stash Java virtual machine
#
JVM_FILE_ENCODING="UTF-8"

#
# The following are the required arguments needed for Atlassian Stash.
#
JVM_REQUIRED_ARGS="-Djava.awt.headless=true -Dfile.encoding=${JVM_FILE_ENCODING} -Datlassian.standalone=STASH -Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Dmail.mime.decodeparameters=true  -Dorg.apache.catalina.connector.Response.ENFORCE_ENCODING_IN_GET_WRITER=false"

#
# Additional JVM arguments
#
JAVA_OPTS=" ${JAVA_OPTS}"

#-----------------------------------------------------------------------------------
#
# In general don't make changes below here
#
#-----------------------------------------------------------------------------------

PRGDIR=`dirname "$0"`

if [ -z "$STASH_HOME" ]; then
    echo ""
    echo "-------------------------------------------------------------------------------"
    echo "  Stash doesn't know where to store its data. Please configure the STASH_HOME"
    echo "  environment variable with the directory where Stash should store its data."
    echo "  Ensure that the path to STASH_HOME does not contain spaces. STASH_HOME may"
    echo "  be configured in setenv.sh, if preferred, rather than exporting it as an"
    echo "  environment variable."
    echo "-------------------------------------------------------------------------------"
    exit 1
fi

echo $STASH_HOME | grep -q " "
if [ $? -eq 0 ]; then
    echo ""
    echo "-------------------------------------------------------------------------------"
    echo "  STASH_HOME \"$STASH_HOME\" contains spaces."
    echo "  Using a directory with spaces is likely to cause unexpected behaviour and is"
    echo "  not supported. Please use a directory which does not contain spaces."
    echo "-------------------------------------------------------------------------------"
    exit 1
fi

STASH_HOME_MINUSD=-Dstash.home=$STASH_HOME

JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${STASH_HOME_MINUSD}"

# PermGen size needs to be increased if encountering OutOfMemoryError: PermGen problems. Specifying PermGen size is
# not valid on IBM JDKs
STASH_MAX_PERM_SIZE="256m"
if [ -f "${PRGDIR}/permgen.sh" ]; then
    echo "Detecting JVM PermGen support..."
    . "${PRGDIR}/permgen.sh"
    if [ $JAVA_PERMGEN_SUPPORTED = "true" ]; then
        echo "PermGen switch is supported. Setting to ${STASH_MAX_PERM_SIZE}"
        JAVA_OPTS="-XX:MaxPermSize=${STASH_MAX_PERM_SIZE} ${JAVA_OPTS}"
    else
        echo "PermGen switch is NOT supported and will NOT be set automatically."
    fi
fi

export JAVA_OPTS

echo ""
echo "If you encounter issues starting or stopping Atlassian Stash, please see the Troubleshooting guide at http://confluence.atlassian.com/display/STASH/Installation+Troubleshooting+Guide"
echo ""
if [ "$STASH_HOME_MINUSD" != "" ]; then
    echo "Using STASH_HOME:      $STASH_HOME"
fi

# set the location of the pid file
if [ -z "$CATALINA_PID" ] ; then
    if [ -n "$CATALINA_BASE" ] ; then
        CATALINA_PID="$CATALINA_BASE"/work/catalina.pid
    elif [ -n "$CATALINA_HOME" ] ; then
        CATALINA_PID="$CATALINA_HOME"/work/catalina.pid
    fi
fi
export CATALINA_PID
