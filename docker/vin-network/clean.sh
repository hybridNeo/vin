rm -rf channel-artifacts
rm -rf crypto-config
docker kill $(docker ps -aq)
docker rm $(docker ps -aq)

docker network prune -f
