#!/bin/bash

. vrf-funcs.sh

function setup
{
	echo "creating..."
	create_bridges
	create_hosts
	create_ce_routers
	create_pe_routers
	create_p_routers

	echo "setting up..."
	setup_mpls
	setup_routing
}

setup
