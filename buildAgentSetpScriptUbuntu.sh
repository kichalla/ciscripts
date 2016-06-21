#!/usr/bin/env bash

# NOTE: This script must be run with an account having 'sudo' privileges

if [ $# -ne 2 ]; then
    echo "Invalid number of arguments specified."
    echo "Usage: <script-name> <agent-name> <agent-url>"
    echo "Examples:"
    echo "<script-name> 'aspnetci-b01' 'http://aspnetci/'"
    exit 1
fi

apt-get update

echo "Installing Git..."
apt-get install -y git

# Sometimes git pull stalls, so this could fix it
git config --global http.postBuffer 2M

echo "Installing Mono 4.2.3..."
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/4.2.3/. main" | tee /etc/apt/sources.list.d/mono-xamarin.list
apt-get update
apt-get install -y mono-complete

echo "Installing libunwind8..."
apt-get install -y libunwind8

echo "Installing Java..."
apt-get install -y openjdk-7-jre-headless unzip

echo "Installing Nodejs..."
apt-get install -y nodejs
ln -s /usr/bin/nodejs /usr/bin/node

echo "Installing NPM..."
apt-get install -y npm

echo "Installing Bower globally..."
npm install -g bower

echo "Installing Grunt globally..."
npm install -g grunt

echo "Installing Gulp globally..."
npm install -g gulp

echo "Installing TypeScript globally..."
npm install -g typescript

echo "Downloading build agent from http://aspnetci/ and updating the properties..."
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
sed -i "s/name=.*/name=$1/" buildAgent.properties
sed -i "s#serverUrl=.*#serverUrl=$2#g" buildAgent.properties

echo >> buildAgent.properties # append a new line
echo "system.aspnet.os.name=ubuntu" >> buildAgent.properties

cd ~/TeamCity

cat <<EOF >> agentStartStop
#!/usr/bin/env bash
 
case "\$1" in
start)
 sudo ~/TeamCity/bin/agent.sh start
;;
stop)
 sudo ~/TeamCity/bin/agent.sh stop
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
update-rc.d agentStartStop defaults

echo "Starting the build agent..."
~/TeamCity/bin/agent.sh start