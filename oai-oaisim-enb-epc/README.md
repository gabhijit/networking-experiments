Trying to setup OAI ENB and EPC inside a single node using net namespace.

Currently the code is built from following repositories -

ENB : - https://github.com/gabhijit/oai5g
EPC : - https://github.com/gabhijit/openair-cn

The reason I have started my own repositories is I am going to be making breaking changes to the code-base
 - to make it easier for anyone to run ENB on their laptops
 - to dockerize the build and deployment as well
 - remove a lot of stray (and stale) documents and
 - make build process better so that it should be possible to build on any distro (provided right kernel version is available)


This repository is setup for creating the topology for testing with oaisim based ENB.

The actual topology is [from here](https://www.tutorialspoint.com/lte/images/lte_epc.jpg)
