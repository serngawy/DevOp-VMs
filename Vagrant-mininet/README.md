# vagrant-mininet

This Vagrantfile tries to be an all-inclusive script to provide an
OpenFlow 1.4 playground in a VM.

Tools included:

- Mininet 2.1.0
- OpenVSwitch 2.4.0

## Usage

Start with installation of VirtualBox and Vagrant. Next, download the
Vagrantfile and run `vagrant up` from the folder it is stored in.

After the script finishes its job, `vagrant ssh` from the corresponding folder
should let you in the VM.
