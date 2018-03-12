#!/bin/bash

# run as sudo

IP=ip

HSS_EXE=/usr/local/bin/oai_hss

HSS_CONFIG=/etc/oai/hss.conf
HSS_FD_CONFIG=/etc/oai/hss_fd.conf

${IP} netns exec hss bash -c "${HSS_EXE} -c ${HSS_CONFIG}"
