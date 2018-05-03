
# functions to create topology

IP=ip

function _do_create_node {
	nodename=$1
	${IP} netns add ${nodename}
	${IP} netns exec ${nodename} ip link set lo up
	${IP} netns exec ${nodename} ip addr add 127.0.0.1/24 dev lo
}

function create_enb {
	echo "creating enb"
	_do_create_node enb
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

	# Add a MACVTAP Interface and connect it to the underlying eth device
	# For this we need to get the 'eth' device in our namespace.
	# Warning: Does not work with WLAN devices
	# Need to set this interface in promiscuous mode or set the mac for the
	# macvtap interface properly.

	${IP} link set eth0 netns spgw
	${IP} netns exec spgw ip link set eth0 up
	${IP} netns exec spgw ip link add link eth0 name spgw-gw-eth type macvtap
	${IP} netns exec spgw ip link set spgw-gw-eth up
	${IP} netns exec spgw ip addr add 192.168.1.100/24 dev spgw-gw-eth
	${IP} netns exec spgw ip route add default via 192.168.1.1
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
	#${IP} link set enb-mme-eth up
	#${IP} addr add 10.0.0.1/24 dev enb-mme-eth

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
	#${IP} link set enb-sgw-eth up
	#${IP} addr add 10.0.2.1/24 dev enb-sgw-eth

	${IP} link set sgw-enb-eth netns spgw
	${IP} netns exec spgw ${IP} link set sgw-enb-eth up
	${IP} netns exec spgw ${IP} addr add 10.0.2.2/24 dev sgw-enb-eth

	echo "S1-U connectivity setup..."

}
