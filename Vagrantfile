# -*- mode: ruby -*-
# vi: set ft=ruby :
# To use it: vagrant reload && vagrant provision && vagrant ssh

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "generic/fedora29"
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  # Create a forwarded port mapping which allows access to a specific port
  # via 127.0.0.1 to disable public access
  config.vm.network "forwarded_port", guest: 80, host: 10080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 443, host: 10443, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5000, host: 15000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8080, host: 18080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8888, host: 18888, host_ip: "127.0.0.1"
  # Share an additional folder to the guest VM
  config.vm.synced_folder "../", "/vagrant", type: "virtualbox" #, disabled: true
  # Provider-specific configuration so you can fine-tune various backing
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    vb.memory = "4096" #"6144"
    vb.cpus = "2" #"4"
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--vram", "64"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    # Create a second disk (80G)
    file_to_disk = File.realpath( "." ).to_s + '/secondDisk.vdi'
    if ARGV[0] == "up" && ! File.exist?(file_to_disk)
      vb.customize ['createhd', '--filename', file_to_disk, '--format', 'VDI', '--size', 80 * 1024] #[,'--variant', 'Fixed',]
      vb.customize ['storagectl', :id, '--name', 'SATA Controlleri', '--add', 'sata', '--portcount', 4]
    end
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controlleri', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
  end

  config.vm.provision :shell, :privileged => true, :path => "add_new_disk.sh"
  config.vm.provision :shell, :privileged => false, :path => "bootstrap_fedora29.sh"

  # Additional Plugin config for vagrant-vbguest (0.16.0)
  # VBoxGuestAdditions we will try to autodetect this path.
  #   [default] GuestAdditions seems to be installed (6.0.4) correctly, but not running.
  #   Redirecting to /bin/systemctl start vboxadd.service
  # However, if we cannot or you have a special one you may pass it like:
  # config.vbguest.iso_path = "%PROGRAMFILES%/Oracle/VirtualBox/VBoxGuestAdditions.iso"
  # Avoid sync everytime:
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false  
  end
  # do NOT download the iso file from a webserver
  #config.vbguest.no_remote = true
end