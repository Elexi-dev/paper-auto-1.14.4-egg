#!/bin/ash
# Paper Installation Script
# Server Files: /mnt/server
apk add --no-cache --update curl jq git

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

echo -e "Downloading Server files/plugins from Elexi.dev"
git clone https://github.com/Elexi-dev/paper-auto-1.14.4.git
mv paper-auto-1.14.4/ ../

echo -e "Changing configs based off of user variable input"
cd /mnt/server/plugins/DiscordSRV
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
echo -e "Checking for Server Update..."
newthing=`curl -s "https://papermc.io/api/v1/paper/${currentmc}" | jq -r '.builds | .latest' 2>&1 | tee latestversion.txt`
echo -e "Latest Paper is on version ${newthing}"
startserver(){
  echo -e "You good on your server/plugin updates my dude."
  echo -e "Starting server."
}
updatecoreplugins(){
  echo -e "Checking/Updating Core Plugins from Elexi.dev"
  git checkout master
  git stash
  git pull
  git stash pop --quiet
  echo -e "Core Plugin Check/Update done."
  startserver
}
comparedemapples(){
	if [ "${newthing}" -gt "${current}" ]; then
		echo -e "paper-${newthing}.jar is a new update."
		echo -e "Updating to paper-${newthing}.jar"
		wget -nv -nc --content-disposition https://papermc.io/api/v1/paper/${currentmc}/${newthing}/download
		file="paper-${newthing}.jar"
		if [ -f "${file}" ]; then
			echo -e "paper-${newthing}.jar has been downloaded. Renaming some shit..."
			rm -R ../paper-${current}.jar
			mv paper-${newthing}.jar ../paper-${newthing}.jar
			echo -e "${newthing}" > currentversion.txt
			startserver
		else
			echo -e "Error 404: paper-${newthing}.jar could not be found."
			comparedemapples
		fi
	else
		echo -e "paper-${newthing}.jar is already installed and running."
		updatecoreplugins
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
