#!/bin/bash

# Function to expose the docker network namespace
exposedockernetns () {
    if [ "$1" == "" ]; then
      echo "usage: $0 <container_name>"
      echo "Exposes the netns of a docker container to the host"
      exit 1
    fi

    pid=`docker inspect -f '{{.State.Pid}}' $1`
    ln -s /proc/$pid/ns/net /var/run/netns/$1
    return 0
}

# Remove old netns simlink
rm -Rf /var/run/netns/*
mkdir /var/run/netns

service vpp start

sleep 10

service honeycomb start

sleep 60

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
        "interface": [
            {
                "name": "tap-0",
                "description": "for testing purposes",
                "type": "v3po:tap",
                "tap" :{
                    "tap-name" : "tapcontainer1"
                }
            }
        ]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-0"

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
        "interface": [
            {
                "name": "tap-1",
                "description": "for testing purposes",
                "type": "v3po:tap",
                "tap" :{
                    "tap-name" : "taphost"
                }
            }
        ]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-1"

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
        "interface": [
            {
                "name": "tap-2",
                "description": "for testing purposes",
                "type": "v3po:tap",
                "tap" :{
                    "tap-name" : "tapcontainer2"
                }
            }
        ]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-2"

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
            "address": [{
                "ip" : "192.168.1.1",
                "prefix-length" : "24"
            }]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-0/ipv4/address/192.168.1.1"

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
            "address": [{
                "ip" : "192.168.2.1",
                "prefix-length" : "24"
            }]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-1/ipv4/address/192.168.2.1"

curl -X PUT -k -u admin:admin -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{
            "address": [{
                "ip" : "192.168.3.1",
                "prefix-length" : "24"
            }]
}' "https://localhost:8443/restconf/config/ietf-interfaces:interfaces/interface/tap-2/ipv4/address/192.168.3.1"

ip addr add 192.168.2.2/24 dev taphost

# Create a docker container
docker pull melserngawy/devopdocker
docker run --name "hasvppinterface1" melserngawy/devopdocker sleep 30000 &
docker run --name "hasvppinterface2" melserngawy/devopdocker sleep 30000 &
# Wait
sleep 5

# Expose our container to the 'ip netns exec' tools
exposedockernetns hasvppinterface1
exposedockernetns hasvppinterface2

# Move the 'tapcontainer1+2 VPP linux tap interface's into container1+2's network namespace respectivley.
ip link set tapcontainer1 netns hasvppinterface1
ip link set tapcontainer2 netns hasvppinterface2

# Give our in-container TAP interface's IP addresses and bring them up. Add routes back to the host TAP's via VPP.
ip netns exec hasvppinterface1 ip addr add 192.168.1.2/24 dev tapcontainer1
ip netns exec hasvppinterface1 ip link set tapcontainer1 up
ip netns exec hasvppinterface1 ip route add 192.168.2.0/24 via 192.168.1.1
ip netns exec hasvppinterface1 ip route add 192.168.3.0/24 via 192.168.1.1

ip netns exec hasvppinterface2 ip addr add 192.168.3.2/24 dev tapcontainer2
ip netns exec hasvppinterface2 ip link set tapcontainer2 up
ip netns exec hasvppinterface2 ip route add 192.168.2.0/24 via 192.168.3.1
ip netns exec hasvppinterface2 ip route add 192.168.1.0/24 via 192.168.3.1

# Let the host also know howto get to the container TAP via VPE
ip route add 192.168.1.0/24 via 192.168.2.1
ip route add 192.168.3.0/24 via 192.168.2.1

# Block ICMP out of the default docker0 container interfaces to prevent false positive results
ip netns exec hasvppinterface1 iptables -A OUTPUT -p icmp -o eth0 -j REJECT
ip netns exec hasvppinterface2 iptables -A OUTPUT -p icmp -o eth0 -j REJECT