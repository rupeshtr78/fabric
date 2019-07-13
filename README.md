Hyperledger -Using Fabric CA to generate cryptographic materials 
================================================================
This article will illustrate how to use Fabric CA to setup a basic Fabric network without using cryptogen to generate certificates.
The indent is to get an insight into the generation of cryptographic
materials associated with the fabric identities.For this purpose we will
be executing relevant
[commands](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/Fabric-Steps-ReadMe.txt) for each step without any scripts.

All identities that participate on a Hyperledger Fabric network must be
authorized. This authorization is provided in the form of cryptographic
material that is verified against trusted certificate authorities.

We will see the process for setting up a basic fabric network that
includes one organization, with two peers and one orderer.Two TLS CA
servers and two CA Servers one CA each for peer org and orderer org. We
will generate cryptographic material for orderers, peers,
administrators, and end users with TLS enabled in a single host
environment.

> Topology of this deployment can be seen in the image below:

![](images/model.png)

We will generate the model as shown below using Fabric CA.

![](images/blocktree.png)

-   **admincerts** to include PEM files each corresponding to an
    administrator certificate (signcerts of admin user)
-   **cacerts** to include PEM files each corresponding to a root CA's
    certificate (ca-cert.pem)
-   **keystore** to include a PEM file with the node's signing key;
    private key.currently RSA keys are not supported
-   **signcerts** to include a PEM file with the node's X.509
    certificate public key.
-   **tlscacerts** (optional) a folder to include PEM files each
    corresponding to a TLS root CA's certificate

**Step : Setting up the Fabric CA**

We will need the binaries for both Fabric and Fabric CA for this
exercise and make the relevant fabric-ca-servers ,fabric-ca-client
binaries and also make the docker images.User guides and other
[contributors](ht<span>tps://gist.github.com/AkshayCHD/f7c96175dca1e5ab8d5785a3af0d5692) has very good notes on the required steps for
setting up fabric and fabric ca binaries. Select and set the path to
latest binary for your machine.Or you could point to the samples
binaries.

This exercise uses version 1.4.2 of fabric-ca-client

**Step :Setup TLS CA**

Make the directory structure needed for TLS CA , Fabric CA client and
Server for our model.

![CA server
Directory](images/fabca-tree.png)

mkdir -p fabca/fabric.<span>com/{ca-admin,ca-server,tlsca-admin,tlsca-server}

mkdir -p
fabca/po1.fabric.<span>com/{ca-admin,ca-server,tlsca-admin,tlsca-server}

**Start the TLS enabled Fabric CA container**.First run the container
with *fabric-ca-server init* command .Refer
[docker-compose-tlsca.yaml](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/scripts/docker-compose-tlsca.yaml)

Copy the fabca/fabric.<span>com/tlsca-server/tls-ca-cert.pem to
/crypto-config/ordererOrganizations/fabric.<span>com/tlsca directory.

Copy the key file from fabca/fabric.<span>com/tlsca-server/msp/keystore to
./crypto-config/ordererOrganizations/fabric.<span>com/tlsca/tlsca.fabric.<span>com-key.pem.

After copy run the TLS CA container this time use the *fabric-ca-server*
*start* command.Check the logs to verify the server start and its
listening to your the port 7150 in this case.

At this point the TLA CA server is listening on a secure socket, and can
start issuing TLS certificates.

> **After starting the TLS and CA servers its mainly two steps.**
> 
> \(1) **Register** identities (orderers, peers ,admins,users) with TLS and
> CA servers
> 
> \(2) **Enroll** those identities by pointing to their relevant msp
> directory for generating CA certificates and to the **tls** directory for generating TLS certificates
> as per your model.These two steps creates all the cryptographic material
> for each identity in the network.
> 
If on different host machines the trusted root certificate for the TLS
CA has to be copied to other host machines that will communicate with
this CA .

**Orderer org TLS :***Enroll the TLS CA server admin and then register
org identities with orderer org's TLS CA server*

```
Register orderer org identities with the tls-ca

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto- 	config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin

fabric-ca-client enroll -d -u https://tls-ord-admin:tls-ord-adminpw@0.0.0.0:7150

fabric-ca-client register -d — id.name orderer1.fabric.com — id.secret ordererPW — id.type orderer -u https://0.0.0.0:7150

fabric-ca-client register -d — id.name Admin@fabric.com — id.secret ordereradminpw — id.type admin -u https://0.0.0.0:7150

Use command fabric-ca-client identity list or Gui DB Browser for SQLite to verify the generated identities.
```



![DB Browser
SQLite](images/sqlite.png)

Going forward you will notice we extensively use the
FABRIC\_CA\_CLIENT\_TLS\_CERTFILES,FABRIC\_CA\_CLIENT\_HOME environment
variables to point to the relevant server and client.

**Peer org TLS:** *Enroll the TLS CA admin and then register identities
with perr org's TLS CA server*

Follow the steps simialr to above to get the TLS CA for peer org
po1.fabric.<span>com up and running.Refer
[docker-compose-tlsca.yaml](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/scripts/docker-compose-tlsca.yaml) from repo.After the fabric server is up and running
execute below scripts to register peer org identities

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin

fabric-ca-client enroll -d -u https://tls-peer-admin:tls-peer-adminpw@0.0.0.0:7151
fabric-ca-client register -d — id.name peer0.po1.fabric.com — id.secret peer0PW — id.type peer -u https://0.0.0.0:7151

fabric-ca-client register -d — id.name peer1.po1.fabric.com — id.secret peer0PW — id.type peer -u https://0.0.0.0:7151

fabric-ca-client register -d — id.name Admin@po1.fabric.com — id.secret po1AdminPW — id.type admin -u https://0.0.0.0:7151
```



**Certificate Authority (CA)**\
Each organization must have it's own Certificate Authority (CA) for
issuing enrollment certificates.Follow the same set of steps that we
followed for TLS CA for starting CA . Initiate and Start both the CA
servers using\
[***docker-compose-rca.yaml***](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/scripts/docker-compose-rca.yaml) ***up*** refer repo.At this point the CA server is
listening on a secure socket, and can start issuing cryptographic
material.

**Orderer org CA:** *Enroll admin for the CA Server and register the
Orderer and Admin user with the orderer org CA*

```bash
Orderer org :fabric

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin

fabric-ca-client enroll -d -u https://rca-orderer-admin:rca-orderer-adminpw@0.0.0.0:7152

fabric-ca-client register -d — id.name orderer1.fabric.com — id.secret ordererpw — id.type orderer -u https://0.0.0.0:7152

fabric-ca-client register -d — id.name Admin@fabric.com — id.secret ordereradminpw — id.type admin — id.attrs hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert” -u https://0.0.0.0:7152
```



**Peer org CA:** *Enroll admin for the CA Server and register the peer0
,peer1 and Admin user with the peer org CA*

```bash
Peer org :po1.fabric.com

export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin

fabric-ca-client enroll -d -u https://rca-po1-admin:rca-po1-adminpw@0.0.0.0:7153

fabric-ca-client register -d — id.name peer0.po1.fabric.com — id.secret peer1PW — id.type peer -u https://0.0.0.0:7153

fabric-ca-client register -d — id.name peer1.po1.fabric.com — id.secret peer2PW — id.type peer -u https://0.0.0.0:7153

fabric-ca-client register -d — id.name Admin@po1.fabric.com — id.secret po1AdminPW — id.type admin — id.attrs “hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert” -u https://0.0.0.0:7153
fabric-ca-client register -d — id.name User1@po1.fabric.com — id.secret po1UserPW — id.type user -u https://0.0.0.0:7153

Use command fabric-ca-client identity list or Gui DB Browser for SQLite to verify the generated identities.
```



**Enroll Peers**

Administrator for peer org po1.fabric.<span>com will enroll the peers with
it's CA.If the machine running Peer is separate host the trusted root
certificate has to be copied to Peer's host machine. Acquiring of these
signing certificate is an out of band process.2 Enrollments are required
as we are TLS enabled.One againt TLS CA and one with Root CA.

**Enroll Peers with CA.**

Make sure the MSP directory of the peer points to the right directory of
your model.As we are following cryptogen **template** model we are
pointing to the
peerOrganizations/po1.fabric.<span>com/peers/peer0.po1.fabric.<span>com/msp. Change
the env variable FABRIC\_CA\_CLIENT\_MSPDIR for each peers **MSP**
directory and then enroll.You can pass **-M** in command for msp dir as
well.

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin

#Peer0:
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/msp
fabric-ca-client enroll -d -u https://peer0.po1.fabric.com:peer1PW@0.0.0.0:7153 — csr.hosts peer0.po1.fabric.com

#Peer1

export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer1.po1.fabric.com/msp
fabric-ca-client enroll -d -u https://peer1.po1.fabric.com:peer2PW@0.0.0.0:7153 — csr.hosts peer1.po1.fabric.com

Verify the generation of certificates in msp/cacerts , keystore , signcerts for each peer’s MSP directory.We just generated the local peer MSP.
```



![Peer Local
MSP](images/localmsp.png)

**Enroll and Get the TLS cryptographic material for the peers**.

We will point to the TLS CA cert and TLS Client Home for getting tls
certs.MSP directory here will be the peers **tls** directory.

crypto-config/peerOrganizations/po1.fabric.<span>com/peers/peer0.po1.fabric.<span>com/**tls**

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer0.po1.fabric.com/tls

fabric-ca-client enroll -d -u https://peer0.po1.fabric.com:peer0PW@0.0.0.0:7151 — enrollment.profile tls — csr.hosts peer0.po1.fabric.com

export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/peers/peer1.po1.fabric.com/tls

# peer1
fabric-ca-client enroll -d -u https://peer1.po1.fabric.com:peer0PW@0.0.0.0:7151 — enrollment.profile tls — csr.hosts peer1.po1.fabric.com
```



**Verify certificates** are generated in the peers **tls** directory
tls/keystore , signcerts ,tlscacerts.Rename keystore private key to
key.pem for ease of reference later on.

![Peer
TLS](images/peertls.png)

**Enroll peer org Admin User with CA**\
The admin identity is responsible for activities such as installing and
instantiating chaincode. The commands below has to be executed on Peer's
host machine if on seperate host.Admin user's MSP directory in our model
is peerOrganizations/po1.fabric.<span>com/user/Admin\@po1.fabric.<span>com/msp

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/msp

fabric-ca-client enroll -d -u https://Admin@po1.fabric.com:po1AdminPW@0.0.0.0:7153
```



**AdminCerts**: As per user guide An identity becomes an "ADMIN" role by
**adding the public certificate to the "admincerts" folder of the
MSP**.You can manually copy signcerts to admin certs or run below store
command.

```bash
fabric-ca-client certificate list — id Admin@po1.fabric.com — store $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/msp/admincerts
```



After enrollment, we should have an admin MSP.\
Copy the **admincerts** certificate ***Admin\@po1.fabric.<span>com.pem*** from this
Admin user MSP and move it to the Peer's MSP in the 'admincerts'
directory. Copy this admin certificate to other peers in the org , use
identity command above or copy to the 'admincerts' directory in each
peers' MSP.

**Enroll and Get the TLS cryptographic material for the Admin User**\
Enroll against the TLS CA using Tls cert and home.\

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/users/Admin@po1.fabric.com/tls

fabric-ca-client enroll -d -u https://Admin@po1.fabric.com:po1AdminPW@0.0.0.0:7151 — enrollment.profile tls

At this point we can test run our peers : docker-compose -f docker-compose-cli.yaml up peer0.po1.fabric.com
```



**Enroll Orderer with CA :** Enroll orderer1.fabric.<span>com and
Admin\@fabric.<span>com with the CA

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/msp

fabric-ca-client enroll -d -u https://orderer1.fabric.com:ordererpw@0.0.0.0:7152

# Enroll Orderer’s Admin User
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp

fabric-ca-client enroll -d -u https://Admin@fabric.com:ordereradminpw@0.0.0.0:7152

# Generate AdminCerts
fabric-ca-client identity list
fabric-ca-client certificate list — id Admin@fabric.com — store $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp/admincerts

# Copy Users AdminCerts to Orderer MSP AdminCerts Directory
cp $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/msp/admincerts/*.pem $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/msp/admincerts

# rename keystore = key.pem
```



**Enroll Orderer with TLS CA**

```bash
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/orderers/orderer1.fabric.com/tls

fabric-ca-client enroll -d -u https://orderer1.fabric.com:ordererPW@0.0.0.0:7150 — enrollment.profile tls — csr.hosts orderer1.fabric.com

# Enroll Orderer’s Admin User

export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls

fabric-ca-client enroll -d -u https://Admin@fabric.com:ordereradminpw@0.0.0.0:7150 — enrollment.profile tls — csr.hosts orderer1.fabric.com

# rename keystore -sk= key.pem
```



**Create Genesis Block and Channel Transaction artifacts**

Before generating genesis block we need the MSP directories of all the
orgs on the orderer host machine.Each org should have MSP directory in
the following structure:

![MSP](images/msp-str.png)

> The MSP for an Org will contain\
> 1. admincerts : The certificate of the Org's admin identity
> 2. cacerts: The trusted root certificate of Org's CA\
> 3. tlscacerts: The trusted root certificate of the Org's TLS CA.
>
> On the Orderer's host machine, we need to collect the MSPs for each of
> the organizations based on the above structure

**Generate Orderer Org MSP**

```
# cacerts — orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/ca/ca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/ca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7152 -M $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp

# AdminCerts — orderer
fabric-ca-client identity list
fabric-ca-client certificate list — id Admin@fabric.com — store $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp/admincerts

# tlscacerts — orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/tlsca/tlsca.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/fabric.com/tlsca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7150 -M $FABRIC_CFG_PATH/crypto-config/ordererOrganizations/fabric.com/msp — enrollment.profile tls
```



**Generate Peer Org MSP**

```bash
# cacerts — peer org
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/ca/ca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/ca-admin
fabric-ca-client getcainfo -u https://0.0.0.0:7153 -M $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp

# AdminCerts — peer org
fabric-ca-client identity list
fabric-ca-client certificate list — id Admin@po1.fabric.com — store $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp/admincerts

# tlscacerts — peer org
export FABRIC_CA_CLIENT_TLS_CERTFILES=$FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/tlsca/tlsca.po1.fabric.com-cert.pem
export FABRIC_CA_CLIENT_HOME=$FABRIC_CFG_PATH/fabca/po1.fabric.com/tlsca-admin
fabric-ca-client getcacert -u https://0.0.0.0:7151 -M $FABRIC_CFG_PATH/crypto-config/peerOrganizations/po1.fabric.com/msp — enrollment.profile tls
```



The above steps should generate the model similar to the [**directory
tree**](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/logs/tree-crypto-config.txt) in repo.

**Generate Orderer Genesis block and channel artifacts**: 
---------------------------------------------------------

Create
[configtx.yaml](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/configtx.yaml) file as per your model.

```bash
cd $FABRIC_CFG_PATH
# Create the orderer genesis.block
configtxgen -profile OneOrgsOrdererGenesis -channelID rtr-sys-channel -outputBlock $FABRIC_CFG_PATH/channel-artifacts/genesis.block
configtxgen -inspectBlock ./channel-artifacts/genesis.block > logs/genesisblock.txt

# Create channel.tx
export CHANNEL_NAME=fabchannel01
configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
configtxgen -inspectChannelCreateTx ./channel-artifacts/channel.tx > logs/channel.txt
# Update anchor peers
configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/po1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg po1MSP
```



**Start the services**

Lets start services one by one :- Start the Orderer : [docker-compose -f
docker-compose-cli.yaml up orderer1.fabric.<span>com](ht<span>tps://github.com/rupeshtr78/fabric/blob/master/docker-compose-cli.yaml)



![](images/orderer-starts.png)

​                                                                          *Orderer Start*

![Peer Start Gossip Protocol
Working](images/peer-start.png)

​	                                                                            *Peer Start*

​                                   

**Create and join Channel**

```bash
export CHANNEL_NAME=fabchannel01

peer channel create -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx -o orderer1.fabric.com:7050 — outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/fabchannel01.block — tls — cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0–0–0–0–7150.pem 60s

peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/fabchannel01.block 30s
```



![Peer Join](images/peer-join.png)

​																			*ChainCode Install*

```
Install and Instantiate Chaincode

peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/abac/go

peer chaincode instantiate -C $CHANNEL_NAME -n mycc -v 1.0 -c ‘{“Args”:[“init”,”a”, “100”, “b”,”200"]}’ -o orderer1.fabric.com:7050 — tls — cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.com/users/Admin@fabric.com/tls/tlscacerts/tls-0–0–0–0–7150.pem 60s
```



![Chaincode
Instantiate](images/cacc-Instantiate.png)

​                                                                             *ChainCode Instantiate*

![Chaincode
Invoke](images/cacc-invoke.png)

​																			 *ChainCode Invoke*

![Chaincode
Query](images/ca-cc-query.png)

​																				*ChainCode Query*

![peer channel fetch newest 
](images/peer-fetch-png.png)

This post simulated the deployment using docker containers.
For deployment on different hosts , you will need to get the signing
certificate on each of those hosts through an out-of-band process.

The network configuration for this project assumes that all containers
are running in the same network. If your deployment uses different
networks, make relevant adjustments to work with your network configurations.
