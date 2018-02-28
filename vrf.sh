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
	br=1
	for cust in `seq 1 2`; do
		for host in `seq 1 2`; do
			_do_create_cust_interface ${cust} ${host} ${br}
		done
		${IP} addr add 88.${br}.1.254/24 dev br${br}-c${cust}
	done

	# c1h3, c1h4, c2h3, c2h4
	br=2
	for cust in `seq 1 2`; do
		for host in `seq 3 4`; do
			_do_create_cust_interface ${cust} ${host} ${br}
		done
		${IP} addr add 88.${br}.1.254/24 dev br${br}-c${cust}
	done
}

function _do_create_cust_interface
{
	cust=${1}
	host=${2}
	br=${3}

	custhost=c${1}h${2}
	custbr=br${br}-c${cust}

	${IP} link add ${custhost}-eth0 type veth peer name ${custbr}-eth${host};
	${IP} link set ${custhost}-eth0 netns ${custhost};
	${IP} link set ${custbr}-eth${host} master ${custbr};
	${IP} netns exec ${custhost} ${IP} addr add  88.${br}.1.${host}/24 dev ${custhost}-eth0
}


function create_customer_bridges
{
	echo "inside create_customer_bridges"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			${IP} link add br${j}-c${i} type bridge || { echo "error: ${IP} link add br${j}-c${i} type bridge"; cleanupl exit -1;}
		done
	done
}

function delete_customer_bridges
{
	echo "inside delete_customer_bridges"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			${IP} link del br${j}-c${i} 2> /dev/null
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

	#setup bridges
	create_customer_bridges

	#setup customer interfaces
	create_customer_interfaces
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
list_namespaces
list_interfaces
cleanup
list_namespaces
