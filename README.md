# Experiments

Here a bunch of shell scripts, that run some experiments on Linux kernel.

# VRF with MPLS
	Scripts to setup the demo -
   - This directory consists of setup scripts for vrf-with-mpls from [netdev 1.1 tutorial](https://www.netdevconf.org/1.1/proceedings/slides/ahern-vrf-tutorial.pdf)
   - I have tested it with 4.15.0 kernel - uses L3mdev support, so any kernel with that support (and corresponding iproute2) should work

# OAI OAISIM ENB and EPC on Same Node

These are a few scripts and configurations to setup OAISIM eNB and EPC on the same node. Motivation and details are explained [in this blog post](https://hyphenos.io/blog/2018/oai-oaisim-enb-epc-netns/)
