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

function create_customer_bridges
{
	echo "inside create_customer_bridges"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			ip link add br${j}-c${i} type bridge || { echo "error: ${IP} link add br${j}-c${i} type bridge"; cleanupl exit -1;}
		done
	done
}

function delete_customer_bridges
{
	echo "inside delete_customer_bridges"
	for i in `seq 1 2`; do
		for j in `seq 1 2`; do
			ip link del br${j}-c${i} 2> /dev/null
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
}

function list_namespaces
{
	ip netns list
}

function list_interfaces
{
	ip link list
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
