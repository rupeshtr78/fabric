# fabric
# ------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------
# cd $FABRIC_CFG_PATH
# Remove files and start over if required
# sudo find crypto-config -maxdepth 10 -type f -exec rm -fv {} \;
# sudo find fabca -maxdepth 10 -type f -exec rm -fv {} \; 
# 
# First generate crypto material
# cryptogen generate --config=./crypto-config.yaml
# Remove all the crytographic material from the standard template run command below.
# sudo find crypto-config -maxdepth 10 -type f -exec rm -fv {} \;
# We will have empty directories structure as per the cryptogen template.
# ------------------------------------------------------------------------------------------------------
# This is the list of manual steps that are required to generate a basic network using Fabric CA
# ------------------------------------------------------------------------------------------------------

export FABRIC_CFG_PATH=$PWD
# ------------------------------------------------------------------------------------------------------
# Setup TLS CA & CA
# ------------------------------------------------------------------------------------------------------

cd $FABRIC_CFG_PATH

mkdir -p fabca/fabric.com/{ca-admin,ca-server,tlsca-admin,tlsca-server}
mkdir -p fabca/po1.fabric.com/{ca-admin,ca-server,tlsca-admin,tlsca-server}

# fabca
# ├── po1.fabric.com
# │   ├── ca-admin
# │   ├── ca-server
# │   ├── tlsca-admin
# │   └── tlsca-server
# │       
# └── fabric.com
    # ├── ca-admin
    # ├── ca-server
    # ├── tlsca-admin
    # └── tlsca-server


# ------------------------------------------------------------------------------------------------------
# Setup the Docker External Network
# ------------------------------------------------------------------------------------------------------
docker network create --driver bridge fab-net

cd $FABRIC_CFG_PATH/scripts
docker-compose -f docker-compose-tlsca.yaml up -d
# docker-compose -f docker-compose-tlsca.yaml down

# For better monitoring during configuration Start one at a time
docker-compose -f docker-compose-tlsca.yaml up tlsca.fabric.com
docker-compose -f docker-compose-tlsca.yaml up tlsca.po1.fabric.com

# docker logs tlsca.fabric.com
# docker logs tlsca.po1.fabric.com

# fabric-ca-server init  creates server cert.pem and key.pem
# fabric-ca-server start enrolls admin user creates admin cert.pem and key

# Copy the keys
sudo cp fabric.com/tlsca-server/msp/keystore/23db0a**&&*&*&*bc527_sk  $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca
sudo cp po1.fabric.com/tlsca-server/msp/keystore/23db0a**&&*&*&*bc527_sk  $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca
# ------------------------------------------------------------------------------------------------------
# Register orderer identities with the tls-ca-orderer
# ------------------------------------------------------------------------------------------------------
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin

fabric-ca-client enroll -d -u https://tls-ord-admin:tls-ord-adminpw@0.0.0.0:7150
fabric-ca-client register -d --id.name orderer1.fabric.com --id.secret ordererPW --id.type orderer -u https://0.0.0.0:7150
fabric-ca-client register -d --id.name Admin@fabric.com --id.secret ordereradminpw --id.type admin -u https://0.0.0.0:7150

# ------------------------------------------------------------------------------------------------------
# Register peer identities with the tls-ca-peer
# ------------------------------------------------------------------------------------------------------

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin

fabric-ca-client enroll -d -u https://tls-peer-admin:tls-peer-adminpw@0.0.0.0:7151
fabric-ca-client register -d --id.name peer0.po1.fabric.com --id.secret peer0PW --id.type peer -u https://0.0.0.0:7151
fabric-ca-client register -d --id.name peer1.po1.fabric.com --id.secret peer0PW --id.type peer -u https://0.0.0.0:7151
fabric-ca-client register -d --id.name Admin@po1.fabric.com --id.secret po1AdminPW --id.type admin -u https://0.0.0.0:7151

# ------------------------------------------------------------------------------------------------------
# Setup orderer CA
# Each organization must have it's own Certificate Authority (CA) for issuing enrollment certificates.
# ------------------------------------------------------------------------------------------------------


cd $FABRIC_CFG_PATH/scripts
docker-compose -f docker-compose-rca.yaml up
docker-compose -f docker-compose-rca.yaml down

docker-compose -f docker-compose-rca.yaml up ca.fabric.com
docker-compose -f docker-compose-rca.yaml up ca.po1.fabric.com

sudo cp 757391ada3e_sk /home/hyper/fabric/crypto-config/peerOrganizations/po1.fabric.com/ca
sudo cp 5d96720f_sk  /home/hyper/fabric/crypto-config/ordererOrganizations/fabric.com/ca

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin

fabric-ca-client enroll -d -u https://rca-orderer-admin:rca-orderer-adminpw@0.0.0.0:7152
fabric-ca-client register -d --id.name orderer1.fabric.com --id.secret ordererpw --id.type orderer -u https://0.0.0.0:7152
fabric-ca-client register -d --id.name Admin@fabric.com --id.secret ordereradminpw --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7152

# ------------------------------------------------------------------------------------------------------
# Setup peer CA
# ------------------------------------------------------------------------------------------------------	


cd $FABRIC_CFG_PATH/scripts
docker-compose -f rca-po1.yaml up
docker-compose -f rca-po1.yaml down
	

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin


fabric-ca-client enroll -d -u https://rca-po1-admin:rca-po1-adminpw@0.0.0.0:7153
fabric-ca-client register -d --id.name peer0.po1.fabric.com --id.secret peer1PW --id.type peer -u https://0.0.0.0:7153
fabric-ca-client register -d --id.name peer1.po1.fabric.com --id.secret peer2PW --id.type peer -u https://0.0.0.0:7153
fabric-ca-client register -d --id.name Admin@po1.fabric.com --id.secret po1AdminPW --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://0.0.0.0:7153
fabric-ca-client register -d --id.name User1@po1.fabric.com --id.secret po1UserPW --id.type user -u https://0.0.0.0:7153

fabric-ca-client identity list
# ------------------------------------------------------------------------------------------------------
# Enroll peers with the CA 
# Before starting up a peer, enroll the peer identities with the CA to get the MSP that the peer will use.
# This is known as the local peer MSP.
# ------------------------------------------------------------------------------------------------------

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/msp
fabric-ca-client enroll -d -u https://peer0.po1.fabric.com:peer1PW@0.0.0.0:7153 --csr.hosts peer0.po1.fabric.com

export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer1.po1.fabric.com/msp 
fabric-ca-client enroll -d -u https://peer1.po1.fabric.com:peer2PW@0.0.0.0:7153 --csr.hosts peer1.po1.fabric.com

# ------------------------------------------------------------------------------------------------------
# Enroll and Get the TLS cryptographic material for the peer. 
# This requires another enrollment,
# Enroll against the ``tls`` profile on the TLS CA. 
#Copy TLS CA from TLS if on another server.

# cp $FABRIC_CFG_PATH/tls-rca/po1.fabric.com/tls/ca/server/tls-cert.pem $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/tls

fabric-ca-client enroll -d -u https://peer0.po1.fabric.com:peer0PW@0.0.0.0:7151 --enrollment.profile tls --csr.hosts peer0.po1.fabric.com

export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer1.po1.fabric.com/tls
fabric-ca-client enroll -d -u https://peer1.po1.fabric.com:peer0PW@0.0.0.0:7151 --enrollment.profile tls --csr.hosts peer1.po1.fabric.com

# rename keystore = key.pem

# Mutuall TLS Enables then rename
# tls/signcerts/cert.pem = server.crt
# tls/keystore/key.pem = server.key
# tls/tlscacerts/tls-0-0-0-0-7151.pem = ca.crt

# ------------------------------------------------------------------------------------------------------
# Enroll and Setup peer org Admin User
# The admin identity is responsible for activities such as # installing and instantiating chaincode. 
# The commands below assumes that this is being executed on Peer1's host machine.
# Fabric does this by Creating folder user/Admin@po1.fabric.com
# ------------------------------------------------------------------------------------------------------

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/msp
fabric-ca-client enroll -d -u https://Admin@po1.fabric.com:po1AdminPW@0.0.0.0:7153

# AdminCerts
fabric-ca-client identity list
fabric-ca-client certificate list --id Admin@po1.fabric.com --store $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/msp/admincerts


# --------------------------------------------------------------
# Enroll user
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/User1@po1.fabric.com/msp
fabric-ca-client enroll -d -u https://User1@po1.fabric.com:po1UserPW@0.0.0.0:7153

# After enrollment, you should have an admin MSP. 
# You will copy the certificate from this MSP and move it to the Peer1's MSP in the ``admincerts``
# folder. You will need to disseminate this admin certificate to other peers in the
# org, and it will need to go in to the ``admincerts`` folder of each peers' MSP.

# --------------------------------------------------------------
# Alternate Method manual copy
mkdir $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/msp/admincerts
cp $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/msp/signcerts/cert.pem $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/msp/admincerts

# --------------------------------------------------------------
# Enroll and Get the TLS cryptographic material for the Admin User
## Enroll against the ``tls`` profile on the TLS CA. Using Tls cert.

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/tls
fabric-ca-client enroll -d -u https://Admin@po1.fabric.com:po1AdminPW@0.0.0.0:7151 --enrollment.profile tls 

# ------------------------------------------------------------------------------------------------------
# Launch Org1's Peers
# ------------------------------------------------------------------------------------------------------

#peer1-org1.yaml
cd $FABRIC_CFG_PATH/scripts
docker-compose -f peer0-po1.yaml up
docker-compose -f peer0-po1.yaml down

docker-compose -f docker-compose-cli.yaml up peer0.po1.fabric.com


# ------------------------------------------------------------------------------------------------------------------------
# Setup Orderer CA
# ------------------------------------------------------------------------------------------------------------------------
# Alternate Method manual copy

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/msp
fabric-ca-client enroll -d -u https://orderer1.fabric.com:ordererpw@0.0.0.0:7152

# Enroll Orderer's Admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp
fabric-ca-client enroll -d -u https://Admin@fabric.com:ordereradminpw@0.0.0.0:7152

# AdminCerts
fabric-ca-client identity list
fabric-ca-client certificate list --id Admin@fabric.com --store $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp/admincerts

# Copy AdminCerts to Orderer MSP AdminCerts
cp $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp/admincerts/*.pem $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/msp/admincerts


# renane keystore _sk = key.pem

# --------------------------------------------------------------------------------
# Orderer TLS certificate.

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/tls
fabric-ca-client enroll -d -u https://orderer1.fabric.com:ordererPW@0.0.0.0:7150 --enrollment.profile tls --csr.hosts orderer1.fabric.com


export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls
fabric-ca-client enroll -d -u https://Admin@fabric.com:ordereradminpw@0.0.0.0:7150 --enrollment.profile tls --csr.hosts orderer1.fabric.com

# rename keystore -sk= key.pem


# ------------------------------------------------------------------------------------------------------------------------
# Create The MSP directory for Orgs
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# On the orderer's host machine, we need to collect the MSPs for all the # organizations. 
# ------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------
#The MSP for Org will contain 
# 1. The trusted root certificate of Org,
# 2. The certificate of the Org's admin identity, 
# 3. The trusted root certificate of the TLS CA. 
# The MSP folder structure can be seen below.

   # /msp
   # ├── admincerts
   # │   └── admin-org-cert.pem
   # ├── cacerts
   # │   └── org-ca-cert.pem
   # ├── tlscacerts
   # │   └── tls-ca-cert.pem
   # └── users
# ---------------
# ------------------------------------------------------------------------------------------------------------------------
# Commands for gathering certificates
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# The Fabric CA client has a couple commands that are useful in acquiring the certificates
# for the orderer genesis and peer MSP setup.

# The first command is the `fabric-ca-client certificate` command. This command can be used
# to get certificates for the admincerts folder. For more information on how to use this command
# , please refer to: `listing certificate information 
# <https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#listing-certificate-information>`__

# The second command is the `fabric-ca-client getcainfo` command. This command can be used to gather
# certificates for the `cacerts` and `tlscacerts` folders. The `getcainfo` command returns back the
# certificate of the CA.
---------------------------------------------------------------------------------------------------------
mkdir -p msp/{cacerts,tlscacerts,admincerts}
# ---------------------------------------------------
# Orderer.org MSP
# ---------------------------------------------------

# cacerts --orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7152 -M $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp

# AdminCerts --orderer
fabric-ca-client identity list
fabric-ca-client certificate list --id Admin@fabric.com --store $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp/admincerts

# tlscacerts --orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7150 -M $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp --enrollment.profile tls

# delete keystore and signcerts empty dir

# ---------------------------------------------------
# Peer Org MSP
# ---------------------------------------------------

# cacerts --peer org
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin
fabric-ca-client getcainfo -u https://0.0.0.0:7153 -M $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp

# AdminCerts --peer org
fabric-ca-client identity list
fabric-ca-client certificate list --id Admin@po1.fabric.com --store $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp/admincerts

# tlscacerts --peer org
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7151 -M $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp --enrollment.profile tls

# ------------------------------------------------------------------------------------------------------------------------
# Create Peer config.yaml
#
# cd ~/fabric01/rtr-fab-cr01
# Edit Configtx.yaml
# ------------------------------------------------------------------------------------------------------------------------

nano $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/msp/config.yaml

NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/0-0-0-0-7054.pem
    OrganizationalUnitIdentifier: peer
# ------------------------------------------------------------------------------------------------------------------------
# Create Genesis Block and Channel Transaction
#
# cd $FABRIC_CFG_PATH
# Edit Configtx.yaml
# ------------------------------------------------------------------------------------------------------------------------

cd $FABRIC_CFG_PATH
# Create the orderer genesis block
configtxgen -profile OneOrgsOrdererGenesis -channelID rtr-sys-channel -outputBlock $FABRIC_CFG_PATH/channel-artifacts/genesis.block
configtxgen -inspectBlock ./channel-artifacts/genesis.block > logs/genesisblock.txt

# Create the channel
export CHANNEL_NAME=fabchannel01													 
configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
configtxgen -inspectChannelCreateTx ./channel-artifacts/channel.tx > logs/channel.txt
# Defining anchor peers
configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/po1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg po1MSP

configtxgen -inspectChannelCreateTx /channel.tx > logs/inspectchannel.txt

# ------------------------------------------------------------------------------------------------------------------------
# Start Services
# ------------------------------------------------------------------------------------------------------------------------
cd $FABRIC_CFG_PATH
docker network create --driver bridge fab-net

cd $FABRIC_CFG_PATH
docker-compose -f docker-compose-cli.yaml up orderer1.fabric.com
docker-compose -f docker-compose-cli.yaml up peer0.po1.fabric.com
docker-compose -f docker-compose-cli.yaml up peer1.po1.fabric.com
docker-compose -f docker-compose-cli.yaml up -d cli
docker exec -it cli bash

docker-compose -f docker-compose-cli.yaml down


# ------------------------------------------------------------------------------------------------------------------------
Create Channel
# The ``channel.tx`` is an artifact that was generated by running the # ``configtxgen`` command on the orderer. 
# This artifact needs to be transferred # to Peer1's host machine out-of-band from the orderer. 
# The command peer channel create -c fabchannel01 will generate fabchannel01.block on Peer1 
# At the specified output path ``/tmp/hyperledger/org1/peer1/assets/mychannel.block``,
# which will be used by all peers in the network that wish # to join the channel. 
# This ``fabchannel01.block`` will be need to transferred to all peers # in both Org1 and Org2 out-of-band.
------------------------------------------------------------------------------------------------------------------------
docker exec -it cli bash

export CHANNEL_NAME=fabchannel01
export ORDERER_TLS_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts

# Added 30s Time
peer channel create -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx -o orderer1.fabric.com:7050 --outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/fabchannel01.block --tls  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0-0-0-0-7150.pem 60s


# configtxgen -inspectBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/fabchannel01.block  >/opt/gopath/src/github.com/hyperledger/fabric/logs/fabchannel01.txt
# ------------------------------------------------------------------------------------------------------------------------
# Peer1 in join the channel.
# ------------------------------------------------------------------------------------------------------------------------
peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/fabchannel01.block 30s

peer channel list
peer channel fetch newest -c $CHANNEL_NAME
peer channel getinfo -c $CHANNEL_NAME
# ------------------------------------------------------------------------------------------------------------------------
# Peer1 channel update
peer channel update -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/po1MSPanchors.tx -o orderer1.fabric.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0-0-0-0-7150.pem 60s
# ------------------------------------------------------------------------------------------------------------------------
# Chain Code
# ------------------------------------------------------------------------------------------------------------------------
# Chain Code 
peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/abac/go
peer chaincode install -n marbles -v 1 -p github.com/chaincode/marbles02/go
# Installed remotely response:<status:200 payload:"OK" 
peer chaincode list --installed

# Verify Docker Images and Containers
docker container ls --all --format "{{.ID}} : {{.Names}}   : {{.Status}} "
docker images --format "{{.ID}} : {{.Tag}}   : {{.Repository}} "

# chaincode install
export CHANNEL_NAME=fabchannel01
peer chaincode instantiate -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -o orderer1.fabric.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0-0-0-0-7150.pem 60s
peer chaincode list --instantiated -C $CHANNEL_NAME 

# chaincode query
peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","b"]}'
peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'

# chaincode invoke
peer chaincode invoke -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0-0-0-0-7150.pem 60s


# Fabric Indentity fix
fabric-ca-client identity modify admin-org1  --attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert"
fabric-ca-client reenroll -d -u https://admin-org1:org1AdminPW@0.0.0.0:7054

fabric-ca-client revoke -e admin-org1 -s 2456c3b9cb9236e61b573f2465345ade67951876
fabric-ca-client revoke -e peer1 --gencrl