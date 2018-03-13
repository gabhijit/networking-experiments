
# functions to create topology

IP=ip

function _do_create_node {
	nodename=$1
	${IP} netns add ${nodename}
	${IP} netns exec ${nodename} ip link set lo up
	${IP} netns exec ${nodename} ip addr add 127.0.0.1/24 dev lo
}

function create_enb {
	#_do_create_node enb
	echo "creating enb"
}

function delete_enb {
	# ${IP} netns delete enb
	echo "deleting enb"
	rmmod ue_ip
}

function create_hss {
	_do_create_node hss

	# for HSS, we need an interface that connects to default netns to connect to mysql running there
	# FIXME : run mysql in hss netns as well.

	${IP} link add hss-host-eth type veth peer name host-hss-eth
	${IP} link set hss-host-eth netns hss
	${IP} netns exec hss ${IP} link set hss-host-eth up
	${IP} netns exec hss ${IP} addr add 10.0.4.2/24 dev hss-host-eth
	${IP} link set host-hss-eth up
	${IP} addr add 10.0.4.1/24 dev host-hss-eth

}

function delete_hss {
	${IP} netns delete hss
}

function create_mme {
	_do_create_node mme
}

function delete_mme {
	${IP} netns delete mme
}

function create_spgw {
	_do_create_node spgw

	# Add a gateway interface and connect it to bridge and outside
	${IP} link add spgw-br type bridge
	${IP} link set spgw-br up
	${IP} addr add 10.0.5.254/24 dev spgw-br
	${IP} link add spgw-gw-eth type veth peer name gw-br-eth
	${IP} link set gw-br-eth master spgw-br
	${IP} link set gw-br-eth up
	${IP} link set spgw-gw-eth netns spgw
	#${IP} netns exec spgw ${IP} link add gw-eth type dummy
	${IP} netns exec spgw ${IP} link set spgw-gw-eth up
	${IP} netns exec spgw ${IP} addr add 10.0.5.2/24 dev spgw-gw-eth
	${IP} netns exec spgw ${IP} route add default via 10.0.5.254 dev spgw-gw-eth
}

function delete_spgw {
	${IP} netns delete spgw
	${IP} link del spgw-br
}


function setup_connectivity {

	echo "setting up S1-MME connectivity..."
	# enb - mme (S1-MME)
	${IP} link add enb-mme-eth type veth peer name mme-enb-eth

	#${IP} link set enb-mme-eth netns enb
	#${IP} netns exec enb ${IP} link set enb-mme-eth up
	#${IP} netns exec enb ${IP} addr add 10.0.0.1/24 dev enb-mme-eth
	${IP} link set enb-mme-eth up
	${IP} addr add 10.0.0.1/24 dev enb-mme-eth

	${IP} link set mme-enb-eth netns mme
	${IP} netns exec mme ${IP} link set mme-enb-eth up
	${IP} netns exec mme ${IP} addr add 10.0.0.2/24 dev mme-enb-eth

	echo "S1-MME connectivity setup..."

	echo "setting up S6A connectivity..."
	# mme - hss (S6A)
	${IP} link add mme-hss-eth type veth peer name hss-mme-eth

	${IP} link set mme-hss-eth netns mme
	${IP} netns exec mme ${IP} link set mme-hss-eth up
	${IP} netns exec mme ${IP} addr add 10.0.1.1/24 dev mme-hss-eth

	${IP} link set hss-mme-eth netns hss
	${IP} netns exec hss ${IP} link set hss-mme-eth up
	${IP} netns exec hss ${IP} addr add 10.0.1.2/24 dev hss-mme-eth

	echo "S6A connectivity setup..."

	echo "setting up S11 connectivity..."
	# mme - sgw (S11)
	${IP} link add mme-sgw-eth type veth peer name sgw-mme-eth

	${IP} link set mme-sgw-eth netns mme
	${IP} netns exec mme ${IP} link set mme-sgw-eth up
	${IP} netns exec mme ${IP} addr add 10.0.3.1/24 dev mme-sgw-eth

	${IP} link set sgw-mme-eth netns spgw
	${IP} netns exec spgw ${IP} link set sgw-mme-eth up
	${IP} netns exec spgw ${IP} addr add 10.0.3.2/24 dev sgw-mme-eth

	echo "S11 connectivity setup..."

	echo "setting up S1-U connectivity..."

	# enb - sgw (S1-U)
	${IP} link add enb-sgw-eth type veth peer name sgw-enb-eth

	#${IP} link set enb-sgw-eth netns enb
	#${IP} netns exec enb ${IP} link set enb-sgw-eth up
	#${IP} netns exec enb ${IP} addr add 10.0.2.1/24 dev enb-sgw-eth
	${IP} link set enb-sgw-eth up
	${IP} addr add 10.0.2.1/24 dev enb-sgw-eth

	${IP} link set sgw-enb-eth netns spgw
	${IP} netns exec spgw ${IP} link set sgw-enb-eth up
	${IP} netns exec spgw ${IP} addr add 10.0.2.2/24 dev sgw-enb-eth

	echo "S1-U connectivity setup..."

}
