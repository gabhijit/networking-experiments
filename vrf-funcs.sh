#!/bin/bash

# requires CAP_NET_ADMIN - run as sudo
# running on kernel version 4.15.0 from kernel.org

# Topology from -
# https://www.netdevconf.org/1.1/proceedings/slides/ahern-vrf-tutorial.pdf

IP=/media/gabhijit/opencontrail/gabhijit-home/backup/personal-code/iproute2/ip/ip


function create_customer_host_namespaces
{
	echo "inside create_customer_host_namespaces"
	for i in  `seq 1 2`; do
		for j in `seq 1 4`; do
			${IP} netns add c${i}h${j} || { echo "error: ${IP} netns add c${i}h${j}"; cleanup; exit -1;}
		done
	done
}

function delete_customer_host_namespaces
{
	echo "inside delete_customer_host_namespaces"
	for i in `seq 1 2`; do
		for j in `seq 1 4`; do
			${IP} netns del c${i}h${j} 2> /dev/null
		done
	done
}

function create_customer_edge_namespaces
{
	echo "inside create_customer_edge_namespaces"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			${IP} netns add c${i}e${j} || { echo "error: ${IP} netns add c${i}e${j}"; cleanup; exit -1;}
		done
	done
}

function delete_customer_edge_namespaces
{
	echo "inside delete_customer_edge_namespaces"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			${IP} netns del c${i}e${j} 2> /dev/null
		done
	done
}

function create_provider_edge_namespaces
{
	echo "inside create_provider_edge_namespaces"
	for i in `seq 1 2`; do
		${IP} netns add pe${i} || { echo "error: ${IP} netns add pe${i}"; cleanup; exit -1;}
	done
}

function delete_provider_edge_namespaces
{
	echo "inside delete_provider_edge_namespaces"
	for i in `seq 1 2`; do
		${IP} netns del pe${i} 2> /dev/null
	done
}

function create_provider_core_namespaces
{
	echo "inside create_provider_core_namespaces"
	${IP} netns add pc || { echo "error: ${IP} netns add pc"; cleanup; exit -1;}
}


function delete_provider_core_namespaces
{
	echo "calling delete_provider_core_namespaces"
	${IP} netns del pc 2> /dev/null
}

function create_customer_interfaces
{
	# c1h1, c1h2, c2h1, c2h2
	edge=1
	for cust in `seq 1 2`; do
		for host in `seq 1 2`; do
			_do_create_cust_interface ${cust} ${host} ${edge}
		done

		ce=c${cust}e${edge}
		cebr=${ce}-br
		${IP} addr add 88.${edge}.1.254/24 dev ${cebr}
	done

	# c1h3, c1h4, c2h3, c2h4
	edge=2
	for cust in `seq 1 2`; do
		for host in `seq 3 4`; do
			_do_create_cust_interface ${cust} ${host} ${edge}
		done
	done
}

function _do_create_cust_interface
{
	cust=${1}
	host=${2}
	edge=${3}

	custhost=c${1}h${2}
	cebr=c${cust}e${edge}-br

	${IP} link add ${custhost}-eth0 type veth peer name ${cebr}-eth${host};
	${IP} link set ${custhost}-eth0 netns ${custhost};
	${IP} link set ${cebr}-eth${host} master ${cebr};
	${IP} netns exec ${custhost} ${IP} addr add  88.${edge}.1.${host}/24 dev ${custhost}-eth0
}

function create_cehost_interfaces
{
	edge=1
	for cust in `seq 1 2`; do
		custedge=c${cust}e${edge}
		${IP} link add ${custedge}-eth0 type veth peer name ${custedge}-br-eth${cust};
	done
}

function create_cepe_interfaces
{

	for cust in `seq 1 2`; do
		edge=2

		ce=c${cust}e${edge}
		pe=pe${edge}

		${IP} link add ${ce}-eth type veth peer name ${pe}-eth${cust}
		${IP} link set ${ce}-eth netns ${ce}
		# since we cannot add vrf to netns, we've to keep it here
		#${IP} link set ${pe}-eth${cust} netns ${pe}

		${IP} netns exec ${ce} ${IP} addr add 3.${cust}.1.2/30 dev ${ce}-eth
		${IP} addr add 3.${cust}.1.1/30 dev ${pe}-eth${cust}
		#${IP} netns exec ${pe} ${IP} addr add 3.${cust}.1.1/30 dev ${pe}-eth${cust}
	done

	for cust in `seq 1 2`; do
		edge=1

		ce=c${cust}e${edge}
		pe=pe${edge}

		${IP} link add ${ce}-eth type veth peer name ${pe}-eth${cust}
		${IP} link set ${ce}-eth master ${ce}-br
		${IP} link set ${ce}-eth netns ${ce}
		#${IP} link set ${pe}-eth${cust} netns ${pe}

		${IP} netns exec ${ce} ${IP} addr add 1.1.1.1/30 dev ${ce}-eth
		${IP} addr add 1.1.1.2/30 dev ${pe}-eth${cust}
		#${IP} netns exec ${pe} ${IP} addr add 1.1.1.1/30 dev ${pe}-eth${cust}
	done

}

function create_core_interfaces
{
	${IP} link add pe1-eth type veth peer name pc-eth1
	${IP} link set pe1-eth netns pe1
	${IP} link set pc-eth1 netns pc
	${IP} netns exec pe1 ${IP} link set pe1-eth up
	${IP} netns exec pc ${IP} link set pc-eth1 up

	${IP} netns exec pe1 ${IP} addr add 2.1.1.1/30 dev pe1-eth
	${IP} netns exec pc ${IP} addr add 2.1.1.2/30 dev pc-eth1


	${IP} link add pe2-eth type veth peer name pc-eth2
	${IP} link set pe2-eth netns pe2
	${IP} link set pc-eth2 netns pc
	${IP} netns exec pe2 ${IP} link set pe2-eth up
	${IP} netns exec pc ${IP} link set pc-eth2 up

	${IP} netns exec pe2 ${IP} addr add 2.1.1.6/30 dev pe2-eth
	${IP} netns exec pc ${IP} addr add 2.1.1.5/30 dev pc-eth2

}

function create_vrf_interfaces
{
	for edge in `seq 1 2`; do
		for cust in `seq 1 2`; do
			${IP} link add vrf-pe${edge}-c${cust} type vrf table 1${edge}${cust}
			${IP} link set vrf-pe${edge}-c${cust} up
			${IP} link set pe${edge}-eth${cust} master vrf-pe${edge}-c${cust}
		done
	done

	# copied from https://netdevconf.org/1.2/papers/ahern-what-is-l3mdev-paper.pdf
	${IP} rule add l3mdev pref 1000
}

function delete_vrf_interfaces
{
	for edge in `seq 1 2`; do
		for cust in `seq 1 2`; do
			${IP} link del vrf-pe${edge}-c${cust}
			#${IP} netns exec pe${edge} ${IP} link set pe${edge}-eth${cust} master vrf-pe${edge}-c${cust}
		done
	done
	${IP} rule del pref 1000
}

function setup_mpls
{
	modprobe mpls_router
	sysctl -w net.mpls.platform_labels=10000

	for edge in `seq 1 2`; do
		for cust in `seq 1 2`;do
			sysctl -w net.mpls.conf.pe${edge}-eth${cust}.input=1
		done
		${IP} netns exec pe${edge} sysctl -w net.mpls.conf.pe${edge}-eth.input=1
		${IP} netns exec pe${edge} sysctl -w net.mpls.platform_labels=10000
		${IP} netns exec pc sysctl -w net.mpls.conf.pc-eth${edge}.input=1
		${IP} netns exec pc sysctl -w net.mpls.platform_labels=10000
		#sysctl -w net.mpls.conf.vrf-pe${edge}-c1.input=1
		#sysctl -w net.mpls.conf.vrf-pe${edge}-c2.input=1
	done
}

function setup_routing
{
	echo "inside setup_routing"

	# FIXME : remove duplcate commands

	# FIXME : Move into separate functions

	# customer hosts
	for cust in `seq 1 2`; do
		${IP} link set c${cust}e1-br-eth1 up
		${IP} netns exec c${cust}h1 ${IP} link set c${cust}h1-eth0 up
		${IP} netns exec c${cust}h1 ${IP} route add 88.2.1.0/24 via 88.1.1.254

		${IP} link set c${cust}e1-br-eth2 up
		${IP} netns exec c${cust}h2 ${IP} link set c${cust}h2-eth0 up
		${IP} netns exec c${cust}h2 ${IP} route add 88.2.1.0/24 via 88.1.1.254

		${IP} link set c${cust}e2-br-eth3 up
		${IP} netns exec c${cust}h3 ${IP} link set c${cust}h3-eth0 up
		${IP} netns exec c${cust}h3 ${IP} route add 88.1.1.0/24 via 88.2.1.254

		${IP} link set c${cust}e2-br-eth4 up
		${IP} netns exec c${cust}h4 ${IP} link set c${cust}h4-eth0 up
		${IP} netns exec c${cust}h4 ${IP} route add 88.1.1.0/24 via 88.2.1.254
	done


	# cepe edges
	${IP} netns exec c1e1 ${IP} link set c1e1-eth up
	${IP} link set pe1-eth1 up
	${IP} netns exec c1e1 ${IP} route add 88.2.1.0/24 via 1.1.1.2

	${IP} netns exec c2e1 ${IP} link set c2e1-eth up
	${IP} link set pe1-eth2 up
	${IP} netns exec c2e1 ${IP} route add 88.2.1.0/24 via 1.1.1.2

	${IP} netns exec c1e2 ${IP} link set c1e2-eth up
	${IP} link set pe2-eth1 up
	${IP} netns exec c1e2 ${IP} route add 88.1.1.0/24 via 3.1.1.1

	${IP} netns exec c2e2 ${IP} link set c2e2-eth up
	${IP} link set pe2-eth2 up
	${IP} netns exec c2e2 ${IP} route add 88.1.1.0/24 via 3.2.1.1

	# mpls network

	# pe1 push mpls
	${IP} netns exec pe1 ${IP} route add 88.2.1.0/24 encap mpls 101 via 2.1.1.2 table 111
	${IP} netns exec pe1 ${IP} route add 88.2.1.0/24 encap mpls 201 via 2.1.1.2 table 112

	# pe2 push mpls
	${IP} netns exec pe2 ${IP} route add 88.1.1.0/24 encap mpls 102 via 2.1.1.5 table 121
	${IP} netns exec pe2 ${IP} route add 88.1.1.0/24 encap mpls 202 via 2.1.1.5 table 122

	# pc mpls
	# to pe2
	${IP} netns exec pc ${IP} -f mpls route add 101 as 111 via inet 2.1.1.6
	${IP} netns exec pc ${IP} -f mpls route add 201 as 211 via inet 2.1.1.6

	# to pe1
	${IP} netns exec pc ${IP} -f mpls route add 102 as 112 via inet 2.1.1.1
	${IP} netns exec pc ${IP} -f mpls route add 202 as 212 via inet 2.1.1.1

	# pe1 pop mpls label
	${IP} -f mpls route add 112 dev vrf-pe1-c1
	${IP} -f mpls route add 212 dev vrf-pe1-c2

	# pe2 pop mpls label
	${IP} -f mpls route add 111 dev vrf-pe2-c1
	${IP} -f mpls route add 211 dev vrf-pe2-c2
}

function create_customer_bridges
{
	echo "inside create_customer_bridges"
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			${IP} link add c${cust}e${edge}-br type bridge || { echo "error: ${IP} link add c${cust}e${edge}-br type bridge"; cleanupl exit -1;}
			${IP} link set c${cust}e${edge}-br up
		done
	done
}

function delete_customer_bridges
{
	echo "inside delete_customer_bridges"
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			${IP} link del c${cust}e${edge}-br 2> /dev/null
		done
	done
}


function setup
{
	# first setup namespaces
	create_customer_host_namespaces
	create_customer_edge_namespaces
	create_provider_edge_namespaces
	create_provider_core_namespaces

	echo "namespaces created..."
	#setup bridges
	create_customer_bridges

	echo "bridges setup..."
	#setup customer interfaces
	create_customer_interfaces
	echo "customer interfaces setup..."

	#create CE-PE interfaces
	create_cepe_interfaces
	echo "CE-PE interfaces setup..."

	#create core interfaces
	create_core_interfaces
	echo "core interfaces setup..."
	echo "all interfaces setup..."

	#create VRF interfaces
	create_vrf_interfaces

	#setup mpls
	setup_mpls

	#setup routing now
	setup_routing

}

function list_namespaces
{
	${IP} netns list
}

function list_interfaces
{
	${IP} link list
	${IP} addr list
}

function cleanup
{
	#delete vrfs
	delete_vrf_interfaces

	#delete bridges
	delete_customer_bridges

	#delete namespaces
	delete_customer_host_namespaces
	delete_customer_edge_namespaces
	delete_provider_edge_namespaces
	delete_provider_core_namespaces
}
