#!/bin/bash

# run as sudo

IP=ip

MME_EXE=/usr/local/bin/mme

MME_CONFIG=/etc/oai/mme.conf
MME_FD_CONFIG=/etc/oai/mme_fd.conf

${IP} netns exec mme bash -c "${MME_EXE} -c ${MME_CONFIG}"
