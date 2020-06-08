#!/bin/bash
logger *** TF Remote-Exec Started ***
  echo "MGT :: Remote-Exec :: Let's get started.."

    echo "MGT :: Remote-Exec :: Configuring routing.."
        sysctl -w net.ipv4.ip_forward=1
        iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
        iptables -A FORWARD -i eth0 -j ACCEPT
        iptables -A FORWARD -o eth0 -j ACCEPT
    echo "MGT :: Remote-Exec :: Configuring routing.. :: Done.."
  
  echo "MGT :: Remote-Exec :: Done.."
logger *** TF Remote-Exec Stopped ***