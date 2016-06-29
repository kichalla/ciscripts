#!/usr/bin/env bash
#trap 'exit' ERR # exit as soon as a command fails

# NOTE: This script must be run with an account having 'sudo' privileges

if [ $# -ne 3 ]; then
    echo "Invalid number of arguments specified."
    echo "Usage: <script-name> <agent-name> <agent-url> <aspnet-os-name>"
    echo "Examples:"
    echo "<script-name> 'aspnetci-b01' 'http://aspnetci/' 'osx'"
    exit 1
fi

AGENTNAME=$1
SERVERURL=${2%/} # trim the final '/' in the string
ASPNETOSNAME=$3

brew update

echo "Installing Git..."
brew install git

# Sometimes git pull stalls, so this could fix it
git config --global http.postBuffer 2M

echo "Installing Mono..."
brew install mono

brew install icu4c

brew install openssl

brew link --force openssl

echo "Installing Unzip..."
brew install unzip

echo "Installing Java..."
brew install caskroom/versions/java7

echo "Installing Node.js..."
brew install node

echo "Installing node-pre-gyp globally..."
npm install -g node-pre-gyp

echo "Installing Bower globally..."
npm install -g bower
echo '{ "allow_root": true }' > ~/.bowerrc # workaround for bower install errors when using with sudo

echo "Installing Grunt globally..."
npm install -g grunt

echo "Installing Gulp globally..."
npm install -g gulp

echo "Installing TypeScript globally..."
npm install -g typescript
npm install -g tsd

echo "Installing Nginx..."
brew install nginx

echo "Starting Nginx..."
brew services start nginx

brew install wget 

echo "Downloading build agent from $SERVERURL and updating the properties..."
mkdir ~/TeamCity
cd ~/TeamCity
wget $SERVERURL/update/buildAgent.zip
unzip buildAgent.zip
cd bin
chmod +x agent.sh
cd ~/TeamCity/conf
cp buildAgent.dist.properties buildAgent.properties

brew install gnu-sed --with-default-names

#TODO--------------------------------------------------------------------------------------
# Set the build agent name and CI server urls
sed -i "s/name=.*/name=$AGENTNAME/" buildAgent.properties
sed -i "s#serverUrl=.*#serverUrl=$SERVERURL#g" buildAgent.properties

echo >> buildAgent.properties # append a new line
echo "system.aspnet.os.name=$ASPNETOSNAME" >> buildAgent.properties

cd ~/TeamCity

chmod \+x ~/TeamCity/launcher/bin/\*
sh ~/TeamCity/bin/mac.launchd.sh load
tail -f ~/TeamCity/logs/teamcity-agent.log
sh ~/TeamCity/bin/mac.launchd.sh unload
cp ~/TeamCity/bin/jetbrains.teamcity.BuildAgent.plist $HOME/Library/LaunchAgents/

echo "Starting the build agent..."
~/TeamCity/bin/agent.sh start