#!/bin/bash

# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok

# Replace variables and cp the service
cp -p ../../services/ngrok.service ../../services/ngrok.service.temp
sed -i ../../services/ngrok.service.temp \
    -e "s|NGORK_EDGE|$NGORK_EDGE|g" \
    -e "s|NODE_PORT|$NODE_PORT|g"
cp ../../services/ngrok.service.temp > /etc/systemd/system/ngrok.service

# Enable and start the tunnel
sudo systemctl enable ngrok.service
sudo systemctl status ngrok.service
