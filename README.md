# nexus-deployment
To start nexus, do several steps:
1) sudo usermod -aG docker $USER
2) newgrp docker
(if "groups | grep docker" includes 'docker', then everything is fine
You can also check if "docker ps" works without sudo)
3) docker compose up -d

In a few minutes nexus should be available at 8081 (for instance, 
127.0.0.1:8081)
