#!/bin/bash

echo "coppying"
docker cp scripts nexus:/scripts
docker exec -it nexus sh -c "/scripts/change-pass.sh"
docker exec -it nexus sh -c "/scripts/end-wizard.sh"
docker exec -it nexus sh -c "/scripts/setup-repos.sh"

exit 0
