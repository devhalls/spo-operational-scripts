#!/bin/bash
# Usage: scripts/install/ngrok.sh
#
# Info:
#
#   - Install ngrok using $NGROK_TOKEN $NGROK_EDGE.
#   - Authenticate ngrok.
#   - Format supervisor files and start the services.
#   - View ngrok status 'systemctl status ngrok.service'

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
servicesDir="$(dirname "$0")/../../services"

curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok

sudo cp -p $servicesDir/ngrok.service $servicesDir/$NGROK_SERVICE.temp
sudo sed -i $servicesDir/$NGROK_SERVICE.temp \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|NGROK_EDGE|$NGROK_EDGE|g" \
    -e "s|NODE_PORT|$NODE_PORT|g"
sudo cp -p $servicesDir/$NGROK_SERVICE.temp $SERVICE_PATH/$NGROK_SERVICE

ngrok config add-authtoken $NGROK_TOKEN
sudo systemctl daemon-reload
sudo systemctl enable $NGROK_SERVICE
sudo systemctl start $NGROK_SERVICE
