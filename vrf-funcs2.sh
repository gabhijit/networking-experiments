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

echo "creating..."
create_bridges
create_hosts
create_ce_routers
create_pe_routers
create_p_routers

echo "deleting..."
delete_p_routers
delete_pe_routers
delete_ce_routers
delete_hosts
delete_bridges
