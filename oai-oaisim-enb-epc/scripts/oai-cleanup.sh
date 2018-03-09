#!/bin/bash

. oai-funcs.sh

function cleanup {
	delete_enb
	delete_hss
	delete_mme
	delete_spgw
}

cleanup
