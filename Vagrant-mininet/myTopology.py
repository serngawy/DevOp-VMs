#!/usr/bin/python

from mininet.net import Mininet
from mininet.node import Controller, RemoteController, OVSController
from mininet.node import CPULimitedHost, Host, Node
from mininet.node import OVSKernelSwitch, UserSwitch
from mininet.node import IVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import TCLink, Intf
from subprocess import call

def myNetwork():
    net = Mininet( topo=None, build=False)
    info( '*** Adding controller\n' )
    c1=net.addController(name='c1', controller=RemoteController, ip='192.168.2.6', protocol='tcp', port=6633)
    info( '*** Add switches\n')

    s4 = net.addSwitch('s4', cls=OVSKernelSwitch)
    s3 = net.addSwitch('s3', cls=OVSKernelSwitch)

    info( '*** Add hosts\n')
    h1 = net.addHost('h1', cls=Host, ip='10.0.1.2', defaultRoute=None)
    h2 = net.addHost('h2', cls=Host, ip='10.0.1.3', defaultRoute=None)
    h3 = net.addHost('h3', cls=Host, ip='10.0.2.3', defaultRoute=None)
    h4 = net.addHost('h4', cls=Host, ip='10.0.2.4', defaultRoute=None)
    h5 = net.addHost('h5', cls=Host, ip='10.0.2.5', defaultRoute=None)

    info( '*** Add links\n')
    net.addLink(s3, s4)
    net.addLink(s4, h5)

    net.addLink(h1, s3)
    net.addLink(h2, s3)
    net.addLink(s4, h3)
    net.addLink(s4, h4)
    info( '*** Starting network\n')
    net.build()
    info( '*** Starting controllers\n')
    for controller in net.controllers:
        controller.start()
    
    info( '*** Starting switches\n')
    net.get('s4').start([c1])
    net.get('s3').start([c1])

    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    myNetwork()