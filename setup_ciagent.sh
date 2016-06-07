#!/usr/bin/env bash

sudo apt-get update

sudo apt-get install git

# Sometimes git pull stalls, so this could fix it
git config --global http.postBuffer 2M

# Install Mono 4.0.5
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/4.0.5.1/. main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list
sudo apt-get update
sudo apt-get install mono-complete

sudo apt-get install libunwind8

# We need the following to get and run teamcity agent
sudo apt-get install openjdk-7-jre-headless unzip

# Download build agent from http://aspnetci and update the agent name
(cd ~/; cp smb://kichallamain.redmond.corp.microsoft.com/UbuntuShare/buildAgent.zip buildAgent.zip)
(sudo mkdir TeamCity; cd TeamCity)
sudo unzip ~/buildAgent.zip
(cd bin; sudo chmod +x agent.sh)
(cd ../conf; cp buildAgent.dist.properties buildAgent.properties)

# Set the build agent name and CI server urls
sed -i "s/name=.*/name=$AGENTNAME/g" buildAgent.properties
sed -i "s/serverUrl=.*/serverUrl=$SERVERURL/g" buildAgent.properties

# We need to tell the machine to start our agent when it boots, like this:
sudo vi /etc/init.d/teamcity
sudo chmod +x /etc/init.d/teamcity
sudo update-rc.d teamcity defaults

# You can always start/stop the agent manually
#sudo ~/TeamCity/bin/agent.sh stop
sudo ~/TeamCity/bin/agent.sh start