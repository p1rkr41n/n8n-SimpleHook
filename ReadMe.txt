### The self-host n8n cluster in local can connect with safe webhook by ngrok
Step 1: Change variables in all file ( get ngrok free token on https://ngrok.com/)
Step 2: Check valid installed pack: docker, jq...
Step 3: Run setup.sh
Step 4: Run run.sh
==========
Now you only can access in http://[n8n-local-ip]:5678.
If you want to access n8n on the internet, you can edit file nginx.conf or setup.sh to allow external access.(Force to rerun run.sh)
