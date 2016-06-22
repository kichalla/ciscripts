#!/usr/bin/env bash

# NOTE: This script must be run with an account having 'sudo' privileges

if [ $# -ne 2 ]; then
    echo "Invalid number of arguments specified."
    echo "Usage: <script-name> <agent-name> <agent-url>"
    echo "Examples:"
    echo "<script-name> 'aspnetci-b01' 'http://aspnetci/'"
    exit 1
fi

USER="aspnetagent"
AGENTNAME=$1
SERVERURL=$2

yum check-update

echo "Installing Git..."
yum install -y git

# Sometimes git pull stalls, so this could fix it
git config --global http.postBuffer 2M

yum install -y epel-release

echo "Installing Mono 4.2.3..."
yum install yum-utils
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
yum-config-manager --add-repo http://download.mono-project.com/repo/centos/
yum check-update
yum install -y mono-complete

echo "Installing libunwind..."
yum install -y libunwind

echo "Installing Java..."
yum install -y java-1.7.0-openjdk 

echo "Installing NodeJs..."
yum -y install nodejs

echo "Installing NPM..."
yum -y install npm

echo "Installing Bower globally..."
npm install -g bower

echo "Installing Grunt globally..."
npm install -g grunt

echo "Installing Gulp globally..."
npm install -g gulp

echo "Installing TypeScript globally..."
npm install -g typescript

yum install -y unzip

echo "Downloading build agent from http://aspnetci and update the agent name.."
cd ~/
wget http://aspnetci/update/buildAgent.zip
mkdir TeamCity
cd TeamCity
unzip ~/buildAgent.zip
cd bin
chmod +x agent.sh
cd ../conf
cp buildAgent.dist.properties buildAgent.properties

# Set the build agent name and CI server urls
sed -i "s/name=.*/name=$AGENTNAME/" buildAgent.properties
sed -i "s#serverUrl=.*#serverUrl=$SERVERURL#g" buildAgent.properties

echo >> buildAgent.properties # append a new line
echo "system.aspnet.os.name=centos" >> buildAgent.properties

cd ~/TeamCity

cat <<EOF >> agentStartStop
#!/usr/bin/env bash
### BEGIN INIT INFO
# Provides:          TeamCity build agent
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO
USER="aspnetagent"

case "\$1" in
start)
 su - \$USER -c "cd ~/TeamCity/bin ; ./agent.sh start"
;;
stop)
 su - \$USER -c "cd ~/TeamCity/bin ; ./agent.sh stop"
;;
*)
  echo "usage start/stop"
  exit 1
 ;;
 
esac
 
exit 0
EOF

chmod +x agentStartStop
cp agentStartStop /etc/init.d/
sudo chkconfig agentStartStop on

su $USER -c "~/TeamCity/bin/agent.sh start"
