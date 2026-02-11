
docker rm -f open-webui

docker pull ghcr.io/open-webui/open-webui:main

docker run -d -p 8080:8080 -e WEBUI_AUTH=False -e OLLAMA_BASE_URL=http://192.168.2.12:11434 -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main



