Trying to setup OAI ENB and EPC inside a single node using net namespace.

##
Currently the code is built from following repositories -

ENB : - https://github.com/gabhijit/oai5g
EPC : - https://github.com/gabhijit/openair-cn

The reason I have started my own repositories is I am going to be making breaking changes to the code-base
 - to make it easier for anyone to run eNB on their laptops
 - to dockerize the build and deployment as well
 - remove a lot of stray (and stale) documents and
 - make build process better so that it should be possible to build on any distribution (provided right kernel version is available)

## Setting Up

The actual topology is [from here](https://www.tutorialspoint.com/lte/images/lte_epc.jpg)

Below is a list of networks -
 - `S1-MME` - `10.0.0/24` network
 - `S1-U` - `10.0.2.0/24` network
 - `S6A` - `10.0.1.0/24` network
 - `S11` - `10.0.3.0/24` network

In addition, there is also another `10.0.4.0/24` network between HSS and host namespace for connecting to MySQL. See below for details.

The RAN is simulated using OAI SIM (which runs both UE and eNodeB and we are running all the nodes in EPC in their own net namespaces.

We are running everything on the same Linux machine - these scripts are tested on Ubuntu 16.04 and kernel version 4.15.0, but these scripts per-se are not dependent on distribution and kernel versions. Except the kernel version higher than 4.7.0 is required where GTP module is available in mainline kernel and is required as a part of building SPGW.

To get started with this - you need to have built already OAISIM and other node software (HSS, MME, SPGW etc.)

There are some parts of setup that are not yet automated and this is described below -

1. MySQL required for HSS runs in the default (host) namespace. It's possible to run this inside the HSS name-space but it's not run yet. For HSS to be able to connect to this, we are setting up a veth pair between HSS netns and default netns. Need some modifications to mysql configuration to make this setup run -
   - Change the `bind-address` parameter to `bind-address = 0.0.0.0`. WARNING : This should never be done on a machine exposed to Internet, but in a test setup this is okay.
   - Also a user needs to be added, so that it's possible to connect to `MySQL` on non `localhost` IP. This can be done following the instructions from [this SO discussion](https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server)

2. The configuration files required for running each of the EPC nodes are available inside `nodes/<nodename>` directory. These files should be first copied to `/etc/netns/<nodename>/oai` directory (creating the appropriate directories if required.)

3. Also the `etc-hosts` file inside the `nodes/<nodename>` directory should be copied to `/etc/netns/<nodename>` directory.

4. We are using `hostname` as `mme` for the MME node. We need to make sure that the entry for this node is added in `oai_db`.

5. After above changes are done, one should run the `./oai-setup.sh` script inside the `scripts/` directory.

6. After that one can run each of the `run_<nodename>.sh` files in the respective `nodes/<nodename>` directories. Keep in mind the order - HSS, MME and then SPGW (ie. first bring up the EPC) and then run the eNodeB side.

## Some Known Issues

1. eNodeb (`enb`) does not run in it's own namespace. This is because, the `ue_ip` kernel module doesn't run in non-default namespace. I am planning to fix this in my repository above. This should help one to run eNodeB in a net namespace as well.
2. The `SGi` interface gateway is not properly configured yet. The plan is to use `MACVTAP` interface, but since this was not running with wireless device, it's not implemented. After testing with a wired interface, will update the script for this.

Please create Issues, if something doesn't work for you, so that I can fix this.

