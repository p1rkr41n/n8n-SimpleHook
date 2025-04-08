#!/bin/bash

# Biến cấu hình chung
PROJECT_DIR="/home/user/n8n-compose"  # Work DIR
NGROK_AUTHTOKEN="ngrok-token"  # Ngrok Authtoken 
N8N_VERSION="latest"
POSTGRES_VERSION="13"
POSTGRES_USER="n8n"
POSTGRES_PASSWORD="verystrongpassword"      # Changeme
POSTGRES_DB="n8n"
N8N_BASIC_AUTH_ACTIVE="true"
N8N_BASIC_AUTH_USER="admin"
N8N_BASIC_AUTH_PASSWORD="verystrongpassword" # Changeme
GENERIC_TIMEZONE="Asia/Ho_Chi_Minh"
N8N_SECURE_COOKIE=false
# Make work dir
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# Create file ngrok.yml (simple config for ngrok v3, tunnel from 8443 Nginx to internet)
cat > ngrok.yml <<EOF
version: "2"
tunnels:
  n8n:
    proto: http
    addr: 8443
    inspect: false
EOF

# Create nginx.conf
cat > nginx.conf <<EOF
events {}

http {
    server {
        listen 8443;

        # Filtering
        set \$allow_request 0;
        if (\$request_uri ~ "^/webhook/") {
            set \$allow_request 1;
        }
        if (\$request_uri ~ "^/webhook-test/") {
            set \$allow_request 1;
        }
        # Deny others
        if (\$allow_request = 0) {
            return 403 "Access Denied";
        }

        # Forward n8n request
        location / {
            proxy_pass http://n8n:5678;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# Create docker-compose.yml  (include n8n + nginx + ngrok)
cat > docker-compose.yml <<EOF
version: '3'

services:
  ngrok:
    image: ngrok/ngrok:latest
    restart: always
    network_mode: host
    environment:
      - NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}
      - NGROK_CONFIG=/etc/ngrok.yml
    volumes:
      - ./ngrok.yml:/etc/ngrok.yml
    command: http 8443  # Create tunnel from 8443 to internet

  nginx:
    image: nginx:latest
    restart: always
    ports:
      - "8443:8443"  # Nginx listen on 8443
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro  # Include  Nginx config file
    depends_on:
      - n8n

  postgres:
    image: postgres:${POSTGRES_VERSION}
    restart: always
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  n8n:
    image: n8nio/n8n:${N8N_VERSION}
    restart: always
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
    env_file:
      - .env
    volumes:
      - n8n_data:/home/node/.n8n
      - ./local-files:/files

volumes:
  postgres_data:
  n8n_data:
EOF

# Create .env for n8n
cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}
EOF

echo "Setup ok. Run run.sh to start anythings ngrok, nginx và n8n."
echo "Nginx only allow host: path /webhook*/"
