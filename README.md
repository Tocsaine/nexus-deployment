# nexus-deployment
To start nexus, do several steps:
1) sudo usermod -aG docker $USER
2) newgrp docker
(if "groups | grep docker" includes 'docker', then everything is fine
You can also check if "docker ps" works without sudo)
3) make an .env file in /scripts with NEXUS_ADMIN_PASSWORD=your_password
4) Use chmod +x start.sh and chmod +x scripts to let the scripts work
5) docker compose up -d
6) In a few moments Nexus should be available on a Localhost:8081.
You can follow this process with docker logs nexus -f
7) After nexus launched, use ./start.sh to setup your nexus.

When you'll be on http://localhost:8081, you will need to accept the agreement
Now you have a docker HTTP repository and RPM repository, disabled anonymous mode

You can access through the https://localhost
login docker through https: docker login localhost:8444

