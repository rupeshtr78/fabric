## Generate HyperLedger Network Identities and Certificates using Fabric CA

This project indents to  illustrate how to use Fabric CA to setup a Fabric network without using cryptogen. 
This exercise is to give a better understanding of each identities and their associated cryptographic materials.
Each step is performed by manually running relevant commands.

All identities that participate on a Hyperledger Fabric network must be authorized. This authorization is provided in the form of cryptographic material that is verified against trusted certificate authorities.
We will see the process for setting up a basic fabric network that includes one organization,with two peers and one orderer.2 TLS CA servers and 2 CA Servers one CA each for peer org and orderer org.
We will generate cryptographic material for orderers, peers, administrators, and end users in a TLS enabled single host environment.

## Medium Article
https://medium.com/@rupeshtr/hyperledger-using-fabric-ca-to-generate-cryptographic-materials-6af08cd29e81?source=friends_link&sk=d6fc25107c87d87910440e84ff1935cf


## References
* https://cloud.ibm.com/docs/services/blockchain-icp-102/howto?topic=blockchain-icp-102-ca-operate#ca-operate-enroll-admin
* https://hyperledger-fabric-ca.readthedocs.io/en/release-1.4/users-guide.html#manage-certificates
* DB Browser SQLite
  https://sqlitebrowser.org
* Fabric CA Client Setup
  https://medium.com/mlg-blockchain-consulting/fabric-ca-setup-client-852136f6a63c
* Setting up Fabric-ca
  https://gist.github.com/AkshayCHD/f7c96175dca1e5ab8d5785a3af0d5692
