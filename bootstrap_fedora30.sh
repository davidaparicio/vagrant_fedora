#!/usr/bin/env bash

BACKGROUND_PIC="/usr/share/backgrounds/fedora-workstation/paisaje.jpg"
LOCKSCREEN_PIC="/usr/share/backgrounds/fedora-workstation/winter-in-bohemia.png"

if [ -x "$(command -v gdm)" ]; then
  echo "GUI already installed"
else
  sudo dnf grouplist
  sudo dnf groupinfo gnome-desktop
  #https://www.reddit.com/r/Fedora/comments/a6c60d/my_notes_on_a_minimal_desktop_install_of_fedora_29/
  sudo dnf install -y @gnome-desktop
  #sudo dnf install -y @workstation-product-environment
  sudo systemctl get-default
  sudo systemctl set-default graphical.target
  #SET UI configuration
  sudo timedatectl set-timezone Europe/Paris
fi
#LETS UPDATE
dnf check-update > /dev/null 2>&1
retval=$?
if [ $retval -eq 0 ]; then
  echo "All package are already up-to-date"
else
  echo "Return code was not zero but $retval"
  echo "Let's update the Vagrant Box"
  sudo dnf update -y
  sudo dnf autoremove -y
fi
if [ -x "$(command -v terminator)" ]; then
  echo "Tools already installed"
else
  sudo dnf install -y terminator tmux vim htop
  cat "  [[default]]
    scrollback_infinite = True" >> ~/.config/terminator/config
  sudo dnf install -y util-linux util-linux-user zsh
  sudo chsh -s $(which zsh) vagrant
  #sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  sudo dnf install -y pcp-system-tools #enable dstat -cdngy 3
  # Add minimize, maximize buttons for GNOME 3
  sudo dnf install -y gnome-tweak-tool
  gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
  gsettings set org.gnome.shell favorite-apps "['terminator.desktop', 'firefox.desktop', 'org.gnome.Nautilus.desktop']"
  # https://fedora.pkgs.org/29/fedora-i386/fedora-workstation-backgrounds-1.1-4.fc29.noarch.rpm.html
  # gnome-backgrounds gnome-backgrounds-extras | f29-backgrounds-gnome f29-backgrounds-extras-gnome
  # default: fedora-workstation-backgrounds + gnome-backgrounds 3.1Mo f29-backgrounds-gnome 42Mo
  # 42Mo size / https://www.omgubuntu.co.uk/2017/04/fix-gnome-wallpaper-inconsistency
  dnf repoquery -l fedora-workstation-backgrounds
  sudo dnf install -y fedora-workstation-backgrounds
  gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_PIC"
  gsettings set org.gnome.desktop.screensaver picture-uri "file://$LOCKSCREEN_PIC"
  # Install Prezto — Instantly Awesome Zsh
  rm -f ~/.zshrc
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
  #setopt EXTENDED_GLOB
  #for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  #  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
  #done
  # Install fonts
  git clone https://github.com/powerline/fonts.git "${HOME}/myfonts" --depth=1
  cd "${HOME}/myfonts" && ./install.sh
  cd .. && rm -rf "${HOME}/myfonts"
  # FREEZE KERNEL VERSION
  cat /proc/version
  #sudo grubby --default-kernel
  sudo grubby --info=ALL
  #sudo dnf install -y kernel-4.20.13-200.fc29.x86_64
  #sudo dnf mark install kernel-4.20.13-200.fc29.x86_64
  #sudo grubby --set-default /boot/vmlinuz-4.20.13-200.fc29.x86_64
  # VIRTUALBOX GUEST ADDITIONS FEDORA
  sudo systemctl status vboxservice
  # dnf list installed | grep -i virtualbox
  #sudo rpm -qa | grep -i virtualbox
  # # virtualbox-guest-additions-6.0.6-1.fc30.x86_64 | https://fedora.pkgs.org/30/fedora-updates-x86_64/virtualbox-guest-additions-6.0.6-1.fc30.x86_64.rpm.html
  # # rpm -ql virtualbox-guest-additions-6.0.6-1.fc30.x86_64
  #sudo dnf update 'kernel*'
  #sudo dnf install make gcc dkms bzip2 perl kernel-headers kernel-devel
  #sudo export KERN_DIR=/usr/src/kernels/`uname -r`
  #sudo mount -r /dev/cdrom /media
  #cd /media
  #sudo ./VBoxLinuxAdditions.run 
  #xrandr --output XWAYLAND0 --mode 2560x1600
fi
if [ -x "$(command -v docker)" ]; then
  echo "Docker already installed"
else
  echo "Install docker"
  #curl -fsSL get.docker.com | CHANNEL=test sh ##https://github.com/docker/for-linux/issues/430#issuecomment-443882230
  ## https://www.reddit.com/r/Fedora/comments/9u8k66/docker_fedora_29/
  sudo dnf config-manager \
  --add-repo \
  https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf install -y docker-ce 
  sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo bash -c 'cat << EOF > /etc/docker/daemon.json
  {
      "storage-driver": "devicemapper",
      "storage-opts": [
          "dm.thinpooldev=/dev/mapper/vg_docker-thinpool",
          "dm.use_deferred_removal=true",
          "dm.use_deferred_deletion=true"
      ],
      "insecure-registries" : ["172.30.0.0/16"]
  }
  EOF'
  sudo systemctl start docker
  #docker run hello-world
fi
if [ -x "$(command -v molecule)" ]; then
  echo "Molecule already installed"
  echo "Think to update molecule"
else
  echo "Install molecule"
  sudo dnf install -y epel-release
  sudo dnf install -y gcc python-pip python-devel openssl-devel libselinux-python
  pip install --user --upgrade pip
  pip install --user --upgrade molecule
  pip install --user --upgrade apache-libcloud
  pip install --user --upgrade docker
fi
if [ -x "$(command -v oc)" ]; then
  echo "OpenShiftCLI already installed"
else
  echo "Install OpenShiftCLI"
  #https://developer.fedoraproject.org/deployment/openshift/about.html
  sudo dnf install -y origin-clients
  #https://medium.com/@fabiojose/working-with-oc-cluster-up-a052339ea219
  #echo "{ 'insecure-registries': ['172.30.0.0/16'] }" | sudo tee /etc/docker/daemon.json
  # Flush firewall rules iptables -F
  #systemctl restart docker && oc cluster up
fi
