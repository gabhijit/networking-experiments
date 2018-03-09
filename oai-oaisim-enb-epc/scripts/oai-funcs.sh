
# functions to create topology

IP=ip

function create_enb {
	${IP} netns create enb
}

function delete_enb {
	${IP} netns delete enb
}

function create_hss {
	${IP} netns create hss
}

function delete_hss {
	${IP} netns delete hss
}

function create_mme {
	${IP} netns create mme
}

function delete_mme {
	${IP} netns delete mme
}

function create_spgw {
	${IP} netns create spgw
}

function delete_spgw {
	${IP} netns delete spgw
}


function setup_connectivity {
	# enb - mme (S1-MME)
	${IP} link add enb-mme-eth type veth peer name mme-enb-eth

	${IP} link set enb-mme-eth netns enb
	${IP} netns exec enb ${IP} link set enb-mme-eth up
	${IP} netns exec enb ${IP} addr add 10.0.0.1/24 dev enb-mme-eth

	${IP} link set mme-enb-eth netns mme
	${IP} netns exec mme ${IP} link set mme-enb-eth up
	${IP} netns exec mme ${IP} addr add 10.0.0.2/24 dev mme-enb-eth

	# mme - hss (S6A)
	${IP} link add mme-hss-eth type veth peer name hss-mme-eth

	${IP} link set mme-hss-eth netns mme
	${IP} netns exec mme ${IP} link set mme-hss-eth up
	${IP} netns exec mme ${IP} addr add 10.0.1.1/24 dev mme-hss-eth

	${IP} link set hss-mme-eth netns hss
	${IP} netns exec hss ${IP} link set mme-enb-eth up
	${IP} netns exec hss ${IP} addr add 10.0.1.2/24 dev hss-mme-eth

	# mme - sgw (S11)
	${IP} link add mme-sgw-eth type veth peer name sgw-mme-eth

	${IP} link set mme-sgw-eth netns mme
	${IP} netns exec mme ${IP} link set mme-sgw-eth up
	${IP} netns exec mme ${IP} addr add 10.0.3.1/24 dev mme-sgw-eth

	${IP} link set sgw-mme-eth netns sgw
	${IP} netns exec sgw ${IP} link set mme-enb-eth up
	${IP} netns exec sgw ${IP} addr add 10.0.3.2/24 dev sgw-mme-eth

	# enb - sgw (S1-U)
	${IP} link add enb-sgw-eth type veth peer name sgw-enb-eth

	${IP} link set enb-sgw-eth netns enb
	${IP} netns exec enb ${IP} link set enb-sgw-eth up
	${IP} netns exec enb ${IP} addr add 10.0.0.1/24 dev enb-sgw-eth

	${IP} link set sgw-enb-eth netns sgw
	${IP} netns exec sgw ${IP} link set mme-enb-eth up
	${IP} netns exec sgw ${IP} addr add 10.0.0.2/24 dev sgw-enb-eth


}
