cd ../vin_chaincode/
go build
cd ../scripts
CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=mycc:0 ./../vin_chaincode/vin_chaincode
