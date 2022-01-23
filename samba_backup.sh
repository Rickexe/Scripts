#!/bin/bash

now=$(date +"%Y_%m_%d_%I_%M")

echo "Creating backup archive..."

zip -r backup_docker_$now.zip authelia/ bazarr/ grafana/ homer/ influxdb/ plex/ prowlarr/ radarr/ radarr4k/ sonarr/ sonarr4k/ tdarr/config tdarr/server tdarr/logs traefik/ transmission/

echo "Archive created, uploading to samba share..."

smbclient //192.168.178.1/FlooNetwork -A /root/.smbclient.conf -c 'cd Backup/Backup/backup_docker ; put backup_docker_'$now'.zip'

echo "Configuration files succesfully backed up to samba share!"

echo "Cleaning up..."

rm backup_docker_$now.zip

KEEP_REMOTE=5
[ "$KEEP_REMOTE" == "all" ] && return 0

input="$(smbclient //192.168.178.1/FlooNetwork -A /root/.smbclient.conf -c 'cd Backup/Backup/backup_docker ; ls')"
group="$(echo "$input" | grep -E '\<([0-9a-f]{8}|backup_docker_.*)\.zip\>' | while read -r name _ _ _ a b c d; do
        theDate=$(echo "$a $b $c $d" | xargs -i date +'%Y-%m-%d %H:%M' -d "{}")
        echo "$theDate $name"
    done | sort -r)"

echo "$group" | tail -n +$((KEEP_REMOTE + 1)) | while read -r _ _ name; do
        smbclient //192.168.178.1/FlooNetwork -A /root/.smbclient.conf -c 'cd Backup/Backup/backup_docker ; rm '$name''
    done

echo "Done"
