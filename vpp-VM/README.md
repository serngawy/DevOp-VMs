# vpp-VM
VPP and Honeycomb Agent VM

Steps to config VPP with eth2 

1- sudo vi /etc/vpp/startup.conf

      unix {
        nodaemon
        log /tmp/vpp.log
        full-coredump
      }

      api-trace {
        on
      }

      dpdk {
        dev 0000:00:09.0
        uio-driver uio_pci_generic
      }

      api-segment {
        gid vpp
      }

2- The eth2 should be not under the kernel control before VPP start

    sudo ifconfig eth2 down
    sudo ip addr flash dev eth2
    
3- start the vpp service

    sudo service vpp start  OR sudo /usr/bin/vpp -c /etc/vpp/startup.conf

4- Check the int detalis by

      sudo vppctl show hard detail
      sudo vppctl show int
