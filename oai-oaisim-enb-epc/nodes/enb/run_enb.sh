#!/bin/bash

# ideas copied from the run_enb_ue_virt_s1 script from the openairinterface5g
# repository,

# FIXME : set this to path where the oaisim binary files are genereated
#         typically, OPENAIR_BASE_DIR/targets/bin/

IP=ip

OPENAIR_TARGETS_BIN_DIR=../../../../openairinterface5g/targets/bin/

RELEASE=14

CONFIG_FILE=enb.band7.generic.oaisim.local_mme.conf

cp ${OPENAIR_TARGETS_BIN_DIR}/.*nvram* .

${IP} netns exec enb insmod ${OPENAIR_TARGETS_BIN_DIR}/ue_ip.ko
${IP} link set oip1 netns enb
${IP} netns exec enb ${OPENAIR_TARGETS_BIN_DIR}/oaisim.Rel${RELEASE} -W -s15 -u1 -b1 -y1 -Q0 -AAWGN -O ${CONFIG_FILE}

