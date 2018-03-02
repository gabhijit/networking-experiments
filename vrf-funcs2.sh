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

create_bridges
create_hosts
create_ce_routers

echo "deleting..."
delete_ce_routers
delete_hosts
delete_bridges
