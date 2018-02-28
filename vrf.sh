#!/bin/bash

# requires CAP_NET_ADMIN - run as sudo
# running on kernel version 4.15.0 from kernel.org

# Topology from -
# https://www.netdevconf.org/1.1/proceedings/slides/ahern-vrf-tutorial.pdf

IP=/media/gabhijit/opencontrail/gabhijit-home/backup/personal-code/iproute2/ip/ip


# Create network namespace for each of the devices
# c1h1, c1h2, c1h3 and c1h4 are Customer 1 machines. Let's create a namespace for each
# c2h1, c2h2, c2h3 and c2h4 are Customer 2 machines. Let's create a namespace for each

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

		ce=c${cust}e${edge}
		cebr=${ce}-br
		${IP} addr add 88.${edge}.1.254/24 dev ${cebr}
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

function create_cepe_interfaces
{

	for cust in `seq 1 2`; do
		edge=2

		ce=c${cust}e${edge}
		pe=pe${edge}

		${IP} link add ${ce}-eth type veth peer name ${pe}-eth${cust}
		${IP} link set ${ce}-eth netns ${ce}
		${IP} link set ${pe}-eth${cust} netns ${pe}

		${IP} netns exec ${ce} ${IP} addr add 3.${cust}.1.2/30 dev ${ce}-eth
		${IP} netns exec ${pe} ${IP} addr add 3.${cust}.1.1/30 dev ${pe}-eth${cust}
	done

	for cust in `seq 1 2`; do
		edge=1

		ce=c${cust}e${edge}
		pe=pe${edge}

		${IP} link add ${ce}-eth type veth peer name ${pe}-eth${cust}
		${IP} link set ${ce}-eth netns ${ce}
		${IP} link set ${pe}-eth${cust} netns ${pe}

		${IP} netns exec ${ce} ${IP} addr add 1.1.1.2/30 dev ${ce}-eth
		${IP} netns exec ${pe} ${IP} addr add 1.1.1.1/30 dev ${pe}-eth${cust}
	done

}

function create_core_interfaces
{
	${IP} link add pe1-eth type veth peer name pc-eth1
	${IP} link set pe1-eth netns pe1
	${IP} link set pc-eth1 netns pc

	${IP} netns exec pe1 ${IP} addr add 2.1.1.1/30 dev pe1-eth
	${IP} netns exec pc ${IP} addr add 2.1.1.2/30 dev pc-eth1


	${IP} link add pe2-eth type veth peer name pc-eth2
	${IP} link set pe2-eth netns pe2
	${IP} link set pc-eth2 netns pc

	${IP} netns exec pe2 ${IP} addr add 2.1.1.4/30 dev pe2-eth
	${IP} netns exec pc ${IP} addr add 2.1.1.6/30 dev pc-eth2

}

function create_customer_bridges
{
	echo "inside create_customer_bridges"
	for cust in `seq 1 2`; do
		for edge in `seq 1 2`; do
			${IP} link add c${cust}e${edge}-br type bridge || { echo "error: ${IP} link add c${cust}e${edge}-br type bridge"; cleanupl exit -1;}
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
	#delete bridges
	delete_customer_bridges

	#delete namespaces
	delete_customer_host_namespaces
	delete_customer_edge_namespaces
	delete_provider_edge_namespaces
	delete_provider_core_namespaces
}

setup
#list_namespaces
#list_interfaces
cleanup
list_namespaces
