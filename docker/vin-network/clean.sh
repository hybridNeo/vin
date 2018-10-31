rm -r channel-artifacts
rm -r crypto-config
docker kill $(docker ps -aq)
docker rm $(docker ps -aq)

docker network prune -f
