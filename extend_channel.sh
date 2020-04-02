#!/bin/bash
#read -p "Channel to add: " CHANNEL_NAME

if [ -z "$1" ]; then
    echo "Usage: ./extend_channel.sh ChannelProfileName"
    exit 5
fi

CHANNEL_NAME=$1
FILENAME=configtx.yaml

export PATH=${PWD}/../bin:${PWD}:$PATH

CONFIGTX_FILE_START=$(cat $FILENAME |sed -n '/#start-configtx.yaml/,/#start-channel-profiles/p')
CHANNEL_PROFILES=$(cat $FILENAME | sed -n '/#start-channel-profiles/,/#end-channel-profiles/p'|sed -e '1d;$d')
CONFIGTX_FILE_END=$(cat $FILENAME |sed -n '/#end-channel-profiles/,/#end-configtx.yaml/p')

if [ "${CONFIGTX_FILE_START}" == "" ] || [ "${CHANNEL_PROFILES}" == "" ] || [ "${CHANNEL_PROFILES}" == "" ]; then
    echo "Invalid pattern in file configtx.yaml"
    exit 5
fi 

# Create new file
cat <<EOF > /tmp/.tmp_configtx.yaml
$CONFIGTX_FILE_START
EOF

cat <<EOF >> /tmp/.tmp_configtx.yaml
$CHANNEL_PROFILES

    $CHANNEL_NAME:
        Consortium: SampleConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Org1
                - *Org2
            Capabilities:
                <<: *ApplicationCapabilities
EOF

cat <<EOF >> /tmp/.tmp_configtx.yaml
$CONFIGTX_FILE_END
EOF

mv $FILENAME $FILENAME.old
mv /tmp/.tmp_configtx.yaml $FILENAME

echo "Updated file configtx.yaml"

CHANNEL_ID=$(echo "$CHANNEL_NAME"|tr [:upper:] [:lower:])

configtxgen -profile $CHANNEL_NAME -outputCreateChannelTx ./channel-artifacts/${CHANNEL_ID}.tx -channelID $CHANNEL_ID
configtxgen -profile $CHANNEL_NAME -outputAnchorPeersUpdate ./channel-artifacts/${CHANNEL_ID}_Org1MSPanchors.tx -channelID $CHANNEL_ID -asOrg Org1MSP
configtxgen -profile $CHANNEL_NAME -outputAnchorPeersUpdate ./channel-artifacts/${CHANNEL_ID}_Org2MSPanchors.tx -channelID $CHANNEL_ID -asOrg Org2MSP

docker exec cli scripts/script_extend.sh $CHANNEL_ID 3 golang 10 false true
