#!/bin/bash

# Ref: https://docs.voltha.org/master/overview/ubuntu_dev_env.html

# prerequisite
sudo apt update
sudo apt dist-upgrade -y

# install curl
sudo apt install curl -y

# install docker-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install build-essential docker-ce git -y


#install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod 755 /usr/local/bin/docker-compose

# install golang 1.13
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-1.13 -y

# setup go environment
mkdir -p $HOME/source
mkdir -p $HOME/go
export GO111MODULE=on
export GOPATH=$HOME/go
export DOCKER_TAG=latest
export PATH=$PATH:/usr/lib/go-1.13/bin:$GOPATH/bin
go version

# add current user to docker system access
sudo usermod -a -G docker $USER


# VOLTHA 2.x containers
cd ~/source/
git clone https://gerrit.opencord.org/voltha-go.git
cd ~/source/voltha-go
git checkout voltha-2.4
sudo make build

# VOLTHA 2.x OpenOLT ccontainer
cd ~/source/
git clone https://gerrit.opencord.org/voltha-openolt-adapter.git
cd ~/source/voltha-openolt-adapter/
git checkout voltha-2.4
sudo make build

# VOLTHA 2.x OF Agent container
cd ~/source/
git clone https://gerrit.opencord.org/ofagent-go.git
cd ~/source/ofagent-go/
git checkout voltha-2.4
sudo make docker-build

# install ONOS
cd ~/source/
git clone https://gerrit.opencord.org/voltha-onos.git
cd ~/source/voltha-onos
git checkout voltha-2.4
sudo make build

# VOLTHA 2.x OpenONU container
cd ~/source/
git clone https://gerrit.opencord.org/voltha-openonu-adapter.git
cd ~/source/voltha-openolt-adapter/
git checkout voltha-2.4
make build

# install voltha command line tool
cd ~/source/
git clone https://gerrit.opencord.org/voltctl.git
cd ~/source/voltctl
git checkout voltha-2.4
make build
make install


mkdir ~/.volt/

cat << EOF > ~/.volt/config
apiVersion: v2
server: localhost:50057
tls:
  useTls: false
  caCert: ""
  cert: ""
  key: ""
  verify: ""
grpc:
  timeout: 10s
EOF

cat << EOF > ~/.volt/command_options
device-list:
  format: table{{.Id}}\t{{.Type}}\t{{.Root}}\t{{.ParentId}}\t{{.SerialNumber}}\t{{.Address}}\t{{.AdminState}}\t{{.OperStatus}}\t{{.ConnectStatus}}\t{{.Reason}}
  order: -Root,SerialNumber

device-ports:
  order: PortNo

device-flows:
  order: Priority,EthType

logical-device-list:
  order: RootDeviceId,DataPathId

logical-device-ports:
  order: Id

logical-device-flows:
  order: Priority,EthType

adapter-list:
  order: Id

component-list:
  order: Component,Name,Id

loglevel-get:
  order: ComponentName,PackageName,Level

loglevel-list:
  order: ComponentName,PackageName,Level
EOF

cd ~/source/
git clone https://gerrit.opencord.org/bbsim.git
cd ~/source/bbsim
sudo make docker-build


echo "alias vcli='/home/sterlite/source/voltctl/voltctl'
alias vcore='cd /home/sterlite/source/voltha-go/'
alias onu='cd /home/sterlite/source/voltha-openonu-adapter/'
alias olt='cd /home/sterlite/source/voltha-openolt-adapter/'
alias codeonu='cd /home/sterlite/source/voltha-openonu-adapter/python/adapters/brcm_openomci_onu/'
alias rg='/home/sterlite/rg.sh'
alias bng='/home/sterlite/bng.sh'
alias polt='/home/sterlite/polt.sh'
alias voltha=\"docker-compose -f /home/sterlite/source/voltha-go/compose/system-test.yml $1\"
alias dsm=\"docker-compose -f /home/sterlite/source/1.13.1/docker-compose-dsm.yml $1\""

echo "export DOCKER_HOST_IP=172.17.0.1
export GO111MODULE=on
export GOPATH=$HOME/go
export DOCKER_TAG=latest
export PATH=$PATH:/usr/lib/go-1.13/bin:$GOPATH/bin
go version
export DOCKER_HOST_IP=172.17.0.1
export DOCKER_TAG=latest
export VOLTHA_HOST_IP=10.60.60.74
export ONOS_HOST_IP=10.60.60.74
export DSM_HOST_IP=0.0.0.0" >> ~/.bashrc
