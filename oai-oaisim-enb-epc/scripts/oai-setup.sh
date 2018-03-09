#!/bin/bash



. oai-funcs.sh


function setup {
	create_enb
	create_hss
	create_mme
	create_spgw

	setup_connectivity
}

setup

