#!/usr/bin/env bash
# Select unassociated volumes and remove it from host

set -eo pipefail
IFS=$'\n\t'

backUpPath="/Backup/Docker/NamedVolumes/"

# Get list of all connected volumes including volumes
# associated with stopped containers
docker ps -a \
   | awk 'NR>1 {print $1}'   \
   | xargs -I {} bash -c 'docker inspect {} \
   | jq -r --arg id {} ".[0] 
   | .Id[0:12] as \$id 
   | (.Name | ltrimstr(\"/\")) as \$name 
   | .Mounts[] 
   | [\$id, \$name, .Name, .Source, .Destination] 
   | @csv"' > docker_volumes.csv

# Get list of all docker volumes on host
docker volume ls \
  | awk 'NR>1 {print $2}' \
  | xargs -I {} bash -c 'docker volume inspect {} \
  | jq -r ".[0] | [.Name, .Mountpoint] | @csv"' > each_docker_volumes.csv

# Get list of orphaned volumes
awk -F, 'NR==FNR {key = $3 FS $4; arr[key]; next} {key = $1 FS $2; if (!(key in arr)) print}' docker_volumes.csv each_docker_volumes.csv > orphaned_volumes.csv

# Backup all "named" orphaned containers, except those which were created by gitlab-runner service
grep -vE '^\"(.{64})\"|.*runner.*' orphaned_volumes.csv \
    | cut -d',' -f2 \
    | tr -d '"' \
    | sed 's|/_data$||' \
    | xargs -I {} cp -r {} $backUpPath

# Run deletion procedure
echo "Do you wish to continue? (Y/n) "
read -r  answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [[ "$answer" == "n" ]]; then
    echo "Script execution stopped by user. See ya!"
    exit 1
elif [[ "$answer" == "y" || "$answer" == "" ]]; then
    awk -F, '{print $1}' orphaned_volumes.csv | xargs -I {} docker volume rm -f {}
else
    echo "Please use Y to remove volumes. Any other options will stop script"
    exit 1
fi