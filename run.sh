#!/bin/bash

# Workdir
PROJECT_DIR="/home/ubuntu/n8n-compose"

# go to work dir
cd "${PROJECT_DIR}"

# Run any (ngrok, nginx, postgres, n8n)
docker compose -f docker-compose.yml up -d

# Crawl ngrok domain
sleep 5
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_URL" ]; then
  echo "Ngrok not working, run this command to check: docker logs <ngrok_container_id>"
  exit 1
fi

# Update .env for n8n webhook with NGROK_URL (use HTTPS from ngrok)
sed -i "s|N8N_HOST=.*|N8N_HOST=${NGROK_URL#https://}|" .env
sed -i "s|N8N_PROTOCOL=.*|N8N_PROTOCOL=http|" .env  # Keep http
sed -i "s|WEBHOOK_URL=.*|WEBHOOK_URL=${NGROK_URL}/|" .env  # Webhook use HTTPS by ngrok

# Restart
docker compose -f docker-compose.yml restart n8n # It maybe not working. Start below command.
docker compose up -d
echo "Any things running."
echo "Domain webhook (HTTPS): ${NGROK_URL}"
echo "You only can access n8n on local !!!"
echo "If you want to access n8n on the internet. You can change filter on nginx.conf then re-compose all"
