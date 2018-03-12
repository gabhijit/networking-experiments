#!/bin/bash

# run as sudo

IP=ip

SPGW_EXE=/usr/local/bin/spgw

SPGW_CONFIG=/etc/oai/spgw.conf

${IP} netns exec spgw bash -c "${SPGW_EXE} -c ${SPGW_CONFIG}"
