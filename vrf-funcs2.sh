#!/bin/bash
# requires CAP_NET_ADMIN - run as sudo
# running on kernel version 4.15.0 from kernel.org

# Topology from -
# https://www.netdevconf.org/1.1/proceedings/slides/ahern-vrf-tutorial.pdf

IP=/media/gabhijit/opencontrail/gabhijit-home/backup/personal-code/iproute2/ip/ip


function create_bridges
{
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			${IP} link add br${cust}${edge} type bridge
			${IP} link set br${cust}${edge} up
		done
	done
}

function delete_bridges
{
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			${IP} link del br${cust}${edge}
		done
	done
}

function _do_create_host
{
	# We are passed following parameters -

	cust=$1
	host=$2
	edge=$3

	echo "creating cust=${cust} host=${host} edge=${edge}"
	custhost=c${cust}h${host}
	custbr=br${cust}${edge}

	${IP} link add ${custhost}-eth type veth peer name ${custhost}-${custbr}-eth

	${IP} link set ${custhost}-${custbr}-eth master ${custbr}
	${IP} link set ${custhost}-${custbr}-eth up

	${IP} link set ${custhost}-eth netns ${custhost}

	${IP} netns exec ${custhost} ${IP} link set ${custhost}-eth up
	${IP} netns exec ${custhost} ${IP} addr add 88.${edge}.1.${host}/24 dev ${custhost}-eth

}

function create_hosts
{
	# first create host namespace
	# add host interfaces
	# assign addresses to them
	# connect to the respective bridge

	edge=1
	for cust in `seq 1 2`; do
		for host in `seq 1 2`; do

			custhost=c${cust}h${host}
			${IP} netns add ${custhost}

			_do_create_host ${cust} ${host} ${edge}
		done
	done

	edge=2
	for cust in `seq 1 2`; do
		for host in `seq 3 4`; do

			custhost=c${cust}h${host}
			${IP} netns add ${custhost}

			_do_create_host ${cust} ${host} ${edge}
		done
	done
}

function delete_hosts
{
	# it's suffice to delete their net namespaces
	for cust in `seq 1 2`; do
		for host in `seq 1 4`; do
			custhost=c${cust}h${host}
			${IP} netns del ${custhost}
		done
	done
}

function create_ce_routers
{
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			custedge=c${cust}e${edge}
			custbr=br${cust}${edge}

			${IP} netns add ${custedge}

			${IP} link add ${custedge}-eth type veth peer name ${custedge}-${custbr}-eth

			${IP} link set ${custedge}-${custbr}-eth master ${custbr}
			${IP} link set ${custedge}-${custbr}-eth up

			${IP} link set ${custedge}-eth netns ${custedge}

			${IP} netns exec ${custedge} ${IP} link set ${custedge}-eth up
			${IP} netns exec ${custedge} ${IP} addr add 88.${edge}.1.254/24 dev ${custedge}-eth
		done
	done
}

function delete_ce_routers
{
	# it's suffice to delete their net namespaces
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			custedge=c${cust}e${edge}
			${IP} netns del ${custedge}
		done
	done
}

function create_pe_routers
{
	edge=1
	for cust in `seq 1 2`; do
		custedge=c${cust}e${edge}
		pe=pe${edge}

		# add veth link
		${IP} link add ${custedge}-${pe}-eth type veth peer name ${pe}-${custedge}-eth

		# do ce side setting
		${IP} link set ${custedge}-${pe}-eth netns ${custedge}
		${IP} netns exec ${custedge} ${IP} link set ${custedge}-${pe}-eth up
		${IP} netns exec ${custedge} ${IP} addr add 1.1.1.1/30 dev ${custedge}-${pe}-eth

		# do pe side setting
		${IP} link set ${pe}-${custedge}-eth up
		${IP} addr add 1.1.1.2/30 dev ${pe}-${custedge}-eth

		${IP} link add vrf-pe${edge}-c${cust} type vrf table 1${edge}${cust}
		${IP} link set vrf-pe${edge}-c${cust} up
		${IP} link set ${pe}-${custedge}-eth master vrf-pe${edge}-c${cust}
	done

	edge=2
	for cust in `seq 1 2`; do
		custedge=c${cust}e${edge}
		pe=pe${edge}

		# add veth link
		${IP} link add ${custedge}-${pe}-eth type veth peer name ${pe}-${custedge}-eth

		# do ce side setting
		${IP} link set ${custedge}-${pe}-eth netns ${custedge}
		${IP} netns exec ${custedge} ${IP} link set ${custedge}-${pe}-eth up
		${IP} netns exec ${custedge} ${IP} addr add 3.1.1.2/30 dev ${custedge}-${pe}-eth

		# do pe side setting
		${IP} link set ${pe}-${custedge}-eth up
		${IP} addr add 3.1.1.1/30 dev ${pe}-${custedge}-eth

		${IP} link add vrf-pe${edge}-c${cust} type vrf table 1${edge}${cust}
		${IP} link set vrf-pe${edge}-c${cust} up
		${IP} link set ${pe}-${custedge}-eth master vrf-pe${edge}-c${cust}
	done

	${IP} rule add l3mdev pref 1000
}

function delete_pe_routers
{
	${IP} link del vrf-pe1-c1
	${IP} link del vrf-pe1-c2

	${IP} link del vrf-pe2-c1
	${IP} link del vrf-pe2-c2

	# pe links will be deleted with ce netns delete
}


function create_p_routers
{
	# create netns
	${IP} netns add p

	# add links to pe1
	${IP} link add p-pe1-eth type veth peer name pe1-p-eth
	${IP} link set p-pe1-eth netns p
	${IP} netns exec p ${IP} link set p-pe1-eth up
	${IP} netns exec p ${IP} addr add 2.1.1.2/30 dev p-pe1-eth
	${IP} link set pe1-p-eth up
	${IP} addr add 2.1.1.1/30 dev pe1-p-eth

	# add links to pe2
	${IP} link add p-pe2-eth type veth peer name pe2-p-eth
	${IP} link set p-pe2-eth netns p
	${IP} netns exec p ${IP} link set p-pe2-eth up
	${IP} netns exec p ${IP} addr add 2.1.1.5/30 dev p-pe2-eth
	${IP} link set pe2-p-eth up
	${IP} addr add 2.1.1.6/30 dev pe2-p-eth
}

function delete_p_routers
{
	${IP} netns del p
}

function setup_mpls
{
	modprobe mpls_router
	sysctl -w net.mpls.platform_labels=10000

	${IP} netns exec p sysctl -w net.mpls.platform_labels=10000

	for edge in `seq 1 2`; do
		for cust in `seq 1 2`;do
			sysctl -w net.mpls.conf.pe${edge}-c${cust}e${edge}-eth.input=1
		done
		sysctl -w net.mpls.conf.pe${edge}-p-eth.input=1

		# for core
		${IP} netns exec p sysctl -w net.mpls.conf.p-pe${edge}-eth.input=1
	done
}

function setup_routing
{
	# first at each of the hosts
	for cust in `seq 1 2`; do
		for host in `seq 1 2`; do
			custhost=c${cust}h${host}
			${IP} netns exec ${custhost} ${IP} route add default via 88.1.1.254 dev ${custhost}-eth
		done
	done

	for cust in `seq 1 2`; do
		for host in `seq 3 4`; do
			custhost=c${cust}h${host}
			${IP} netns exec ${custhost} ${IP} route add default via 88.2.1.254 dev ${custhost}-eth
		done
	done

	# setup at ce routers
	${IP} netns exec c1e1 sysctl -w net.ipv4.ip_forward=1
	${IP} netns exec c1e1 ${IP} route add default via 1.1.1.2 dev c1e1-pe1-eth

	${IP} netns exec c2e1 sysctl -w net.ipv4.ip_forward=1
	${IP} netns exec c2e1 ${IP} route add default via 1.1.1.2 dev c2e1-pe1-eth

	${IP} netns exec c1e2 sysctl -w net.ipv4.ip_forward=1
	${IP} netns exec c1e2 ${IP} route add default via 3.1.1.1 dev c1e2-pe2-eth

	${IP} netns exec c2e2 sysctl -w net.ipv4.ip_forward=1
	${IP} netns exec c2e2 ${IP} route add default via 3.1.1.1 dev c2e2-pe2-eth


	# enable IP forwarding
	sysctl -w net.ipv4.ip_forward=1

	# setup at pe routers
	${IP} route add 88.2.1.0/24 encap mpls 101 via 2.1.1.2 table 111
	${IP} route add broadcast 2.1.1.0/30 dev pe1-p-eth table 111
	${IP} route add 88.2.1.0/24 encap mpls 201 via 2.1.1.2 table 112
	${IP} route add broadcast 2.1.1.0/30 dev pe1-p-eth table 112

	${IP} route add 88.1.1.0/24 encap mpls 102 via 2.1.1.5 table 121
	${IP} route add 88.1.1.0/24 encap mpls 202 via 2.1.1.5 table 122

	# setup at p router
	${IP} netns exec p sysctl -w net.ipv4.ip_forward=1

	# to pe2
	${IP} netns exec p ${IP} -f mpls route add 101 as 111 via inet 2.1.1.6
	${IP} netns exec p ${IP} -f mpls route add 201 as 211 via inet 2.1.1.6

	# to pe1
	${IP} netns exec p ${IP} -f mpls route add 102 as 112 via inet 2.1.1.1
	${IP} netns exec p ${IP} -f mpls route add 202 as 212 via inet 2.1.1.1

	# pop label at pe routers
	# pe1 pop mpls label
	${IP} -f mpls route add 112 dev vrf-pe1-c1
	${IP} -f mpls route add 212 dev vrf-pe1-c2

	# pe2 pop mpls label
	${IP} -f mpls route add 111 dev vrf-pe2-c1
	${IP} -f mpls route add 211 dev vrf-pe2-c2

}
