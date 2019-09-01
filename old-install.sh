#!/bin/ash
# Paper Installation Script
#
# Server Files: /mnt/server
apk add --no-cache --update curl jq

if [ -n "${DL_PATH}" ]; then
    echo -e "using supplied download url"
    DOWNLOAD_URL=`eval echo $(echo ${DL_PATH} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
else
    VER_EXISTS=`curl -s https://papermc.io/api/v1/paper | jq -r --arg VERSION $MINECRAFT_VERSION '.versions[] | IN($VERSION)' | grep true`
    LATEST_PAPER_VERSION=`curl -s https://papermc.io/api/v1/paper | jq -r '.versions' | jq -r '.[0]'`

    if [ "${VER_EXISTS}" == "true" ]; then
        echo -e "Version is valid. Using version ${MINECRAFT_VERSION}"
    else
        echo -e "Using the latest paper version"
        MINECRAFT_VERSION=${LATEST_PAPER_VERSION}
    fi

    BUILD_EXISTS=`curl -s https://papermc.io/api/v1/paper/${MINECRAFT_VERSION} | jq -r --arg BUILD ${BUILD_NUMBER} '.builds.all[] | IN($BUILD)' | grep true`
    LATEST_PAPER_BUILD=`curl -s https://papermc.io/api/v1/paper/${MINECRAFT_VERSION} | jq -r '.builds.latest'`

    if [ "${BUILD_EXISTS}" == "true" ] || [ ${BUILD_NUMBER} == "latest" ]; then
        echo -e "Build is valid. Using version ${BUILD_NUMBER}"
    else
        echo -e "Using the latest paper build"
        BUILD_NUMBER=${LATEST_PAPER_BUILD}
    fi

    echo "Version being downloaded"
    echo -e "MC Version: ${MINECRAFT_VERSION}"
    echo -e "Build: ${BUILD_NUMBER}"
    DOWNLOAD_URL=https://papermc.io/api/v1/paper/${MINECRAFT_VERSION}/${BUILD_NUMBER}/download
fi

cd /mnt/server

echo -e "running curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL}"

if [ -f ${SERVER_JARFILE} ]; then
    mv ${SERVER_JARFILE} ${SERVER_JARFILE}.old
fi

curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL}

echo -e "Downloading 1.14.4 Plugins"
git clone https://github.com/Elexi-dev/plugins-1.14.4-core.git plugins

echo -e "Downloading MC server.properties"
curl -o server.properties https://gist.githubusercontent.com/roger109z/6cb6cd9757733ddcf9c1499cb07b2031/raw/server.properties
cd /mnt/server
curl -o spigot.yml https://gist.githubusercontent.com/roger109z/dc1908ae94aafaad5f31ba8c10c8c797/raw/spigot.yml
mkdir plugins
cd /mnt/server/plugins
curl -o DiscordSRV.jar ${DISCORD_SRV}
mkdir DiscordSRV
cd /mnt/server/plugins/DiscordSRV
curl -o config.yml https://gist.githubusercontent.com/roger109z/24d8f5db991d76d1ba0d5d5c8ceb8e31/raw/config.yml
sed -i 's/!BOTTOKEN!/"$BOT_TOKEN"/g' config.yml
sed -i 's/!CHANNELS!/{"global": "$CHAT_ID"}/g' config.yml
sed -i 's/!CONSOLE!/"$CONSOLE_ID"/g' config.yml
echo -e "Installed Server Config Stuff & DiscordSRV Shit"

# Put anything else above this line!
# ----------------------------------

start(){
cd /mnt/server
echo "Starting Auto Updater Installation..."
currentvercheck(){
	if [ -f currentversion.txt ]; then
		echo "currentversion exists..."
		cd ../
		echo "creating start..."
		cat << 'EOF' > start.sh
#!/bin/bash
#Check for Updates
sh updatescript/updatething.sh
#Start Server
current=`cat updatescript/currentversion.txt`
java -Xms128M -Xmx${SERVER_MEMORY}M -Dterminal.jline=false -Dterminal.ansi=true -jar paper-${current}.jar
EOF
		chmod +x start.sh
		echo "Auto Updater Installation Finished"
		cd
	else
		echo "creating currentversion..."
		cat << 'EOF' > currentversion.txt
0
EOF
		currentvercheck
	fi
}
currentmc(){
	if [ -f currentmc.txt ]; then
		echo "currentmc exists..."
		currentvercheck
	else
		echo "creating currentversion..."
		cat << 'EOF' > currentmc.txt
1.14.4
EOF
		currentmc
	fi
}
uthingcheck(){
	if [ -f updatething.sh ]; then
		echo "updatething exists..."
		currentmc
	else
		echo "creating updatething..."
		cat << 'EOF' > updatething.sh
#!/bin/bash
cd updatescript/
currentmc=`cat currentmc.txt`
current=`cat currentversion.txt`
echo "Checking for Server Update..."
newthing=`curl -s "https://papermc.io/api/v1/paper/${currentmc}" | jq -r '.builds | .latest' 2>&1 | tee latestversion.txt`
echo "Latest Paper is on version ${newthing}"
startserver(){
  echo "Starting Server"
}
comparedemapples(){
	if [ "${newthing}" -gt "${current}" ]; then
		echo "paper-${newthing}.jar is a new update."
		echo "Updating to paper-${newthing}.jar"
		wget -nv -nc --content-disposition https://papermc.io/api/v1/paper/${currentmc}/${newthing}/download
		file="paper-${newthing}.jar"
		if [ -f "${file}" ]; then
			echo "paper-${newthing}.jar has been downloaded. Renaming some shit..."
			rm -R ../paper-${current}.jar
			mv paper-${newthing}.jar ../paper-${newthing}.jar
			echo "${newthing}" > currentversion.txt
			startserver
		else
			echo "Error 404: paper-${newthing}.jar could not be found."
			comparedemapples
		fi
	else
		echo "paper-${newthing}.jar is already installed and running."
		echo "You good on your updates my dude."
		startserver
	fi
}
comparedemapples
EOF
		chmod +x updatething.sh
		uthingcheck
	fi
}
dircheck(){
	if [ -d updatescript ]; then
		echo "updatescript dir exists..."
		cd updatescript
		uthingcheck
	else
		echo "creating dir updatescript..."
		mkdir updatescript
		dircheck
	fi
}
dircheck
}
start
