set -e
cd ../chaincodedev/

peer channel create -c myc -f myc.tx -o orderer:7050

peer channel join -b myc.block

sleep 600000
exit 0
