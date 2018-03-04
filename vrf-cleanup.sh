#!/bin/bash

. vrf-funcs.sh

function cleanup
{
	echo "deleting..."
	delete_p_routers
	delete_pe_routers
	delete_ce_routers
	delete_hosts
	delete_bridges
}

cleanup
