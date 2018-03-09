
# functions to create topology

IP=ip

function _do_create_node {
	nodename=$1
	${IP} netns add ${nodename}
	${IP} netns exec ${nodename} ip link set lo up
	${IP} netns exec ${nodename} ip addr add 127.0.0.1/24 dev lo
}

function create_enb {
	_do_create_node enb
}

function delete_enb {
	${IP} netns delete enb
}

function create_hss {
	_do_create_node hss
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
}

function delete_spgw {
	${IP} netns delete spgw
}


function setup_connectivity {

	echo "setting up S1-MME connectivity..."
	# enb - mme (S1-MME)
	${IP} link add enb-mme-eth type veth peer name mme-enb-eth

	${IP} link set enb-mme-eth netns enb
	${IP} netns exec enb ${IP} link set enb-mme-eth up
	${IP} netns exec enb ${IP} addr add 10.0.0.1/24 dev enb-mme-eth

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

	${IP} link set enb-sgw-eth netns enb
	${IP} netns exec enb ${IP} link set enb-sgw-eth up
	${IP} netns exec enb ${IP} addr add 10.0.2.1/24 dev enb-sgw-eth

	${IP} link set sgw-enb-eth netns spgw
	${IP} netns exec spgw ${IP} link set sgw-enb-eth up
	${IP} netns exec spgw ${IP} addr add 10.0.2.2/24 dev sgw-enb-eth

	echo "S1-U connectivity setup..."

}
