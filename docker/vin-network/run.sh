echo "############################################"
echo "#     Generating Crypto Material           #"
echo "############################################"
cryptogen generate --config=crypto-config.yaml

export FABRIC_CFG_PATH=$PWD


echo "############################################"
echo "#      Creating Channel Configuration      #"
echo "############################################"

mkdir ./channel-artifacts
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
export CHANNEL_NAME=vin-main-channel
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/DMVMSPanchors.tx -channelID $CHANNEL_NAME -asOrg DMVMSP

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ManufacturersMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ManufacturersMSP

export IMAGE_TAG=1.3.0
docker-compose -f docker-compose-cli.yaml up -d
