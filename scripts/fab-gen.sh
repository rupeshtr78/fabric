#!/bin/sh
echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Define Basic network by Rupesh rtr_basic_fabca"
echo


echo "1. Clean Earlier Network"
rm -rf channel-artifacts/*.block channel-artifacts/*.tx
rm -rf logs/*

export FABRIC_CFG_PATH=$PWD
configtxgen -profile OneOrgsOrdererGenesis -channelID rtr-sys-channel -outputBlock ../channel-artifacts/genesis.block
sleep 5s
echo "2. Created the orderer genesis block"

export CHANNEL_NAME=fabchannel01
echo $CHANNEL_NAME
configtxgen -profile OneOrgsChannel -outputCreateChannelTx ../channel-artifacts/channel.tx -channelID $CHANNEL_NAME
sleep 5s
echo "3. Created the channel"

export CHANNEL_NAME=fabchannel01
echo $CHANNEL_NAME
configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ../channel-artifacts/po1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg po1MSP
sleep 5s

configtxgen -inspectBlock ./channel-artifacts/genesis.block > logs/genesisblock.txt
configtxgen -inspectChannelCreateTx ./channel-artifacts/channel.tx > logs/channeltx.txt
configtxgen -inspectChannelCreateTx ./channel-artifacts/po1MSPanchors.tx > logs/po1MSPanchors.txt
tree ./crypto-config > logs/crypto-tree.txt

echo
echo "========= Generated Crypto Config and Network Blocks =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
echo "4. Completed Defining rtr_basic_fabca"
