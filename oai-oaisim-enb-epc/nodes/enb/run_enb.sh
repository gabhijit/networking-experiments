#!/bin/bash

# ideas copied from the run_enb_ue_virt_s1 script from the openairinterface5g
# repository,

# FIXME : set this to path where the oaisim binary files are genereated
#         typically, OPENAIR_BASE_DIR/targets/bin/

IP=ip

OPENAIR_TARGETS_BIN_DIR=../../../../openairinterface5g/targets/bin/

RELEASE=14

CONFIG_FILE=enb.band7.generic.oaisim.local_mme.conf

exec ${IP} netns exec enb ${OPENAIR_TARGETS_BIN_DIR}/oaisim.Rel${RELEASE} -s15 -u1 -b1 -y1 -Q0 -AAWGN -O ${CONFIG_FILE}

