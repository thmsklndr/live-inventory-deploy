# Central configuration and deployment of the RPis
## Deployment Host machine

### Prerequisite

Ubuntu Linux (tested on 20.04 and 21.10). On Windows options are a WSL or a virtual machine.

### Preparation

```
$ sudo apt install wget build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev python3-venv
```

#### pip for local python package management

```bash
$ mkdir -p $HOME/.local/bin
```

```bash
$ export PATH=$HOME/.local/bin:$PATH
$ echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
```
```
pip install -U pip
pip install -U pipx

pipx install pipenv
```

#### pyenv

```
$ wget https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer
$ bash pyenv-installer
``` 

Add the following lines to your `~/.bashrc` file:


```
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"    # if `pyenv` is not already on PATH
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
```

## AWS

### Installation

pipx install --verbose git+https://github.com/aws/aws-cli.git@v2

### Access credentials

MIssING
### General


* To find your AWS account ID using the AWS CLI
```bash
aws sts get-caller-identity --query Account --output text
```

### ECR

#### Login
```
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-central-1.amazonaws.com
```

### IOT

```bash
$ mosquitto_pub -h ab35t74ns0kdw-ats.iot.eu-central-1.amazonaws.com -p 8883 -t test -m hello --cafile certs/AmazonRootCA1.pem --cert certs/8e1d1e359f0e074c70721d0ba58f91ac293648f26e9895344a3a2507effb2434-certificate.pem.crt --key certs/8e1d1e359f0e074c70721d0ba58f91ac293648f26e9895344a3a2507effb2434-private.pem.key -d 
```

* getting the mqtt endpoint (based on the account details in ~/.aws/):

```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

## Deployment to RPi

### SSH


* create ssh key-pair if none available
```
$ thomas@ventoux:~/.ssh$ ssh-keygen -t ed25519 -a 100 -C COMMENT
```

* add identity to RPi root account
```
ssh-add <identity>
ssh-copy-id pi@192.168.178.230
ssh pi@192.168.178.230
sudo -i
cat /home/pi/.ssh/authorized_keys >> /root/.ssh/authorized_keys
```

### ansible

Prepare the pipenv environment once:
```
$ cd live-inventory-deploy
$ pipenv install
```

Start the pipenv shell
```
$ pipenv shell
```

### Required local files

The target RPis will be listed in the `hosts` file. Just copy the `hosts.tmpl` and add the actual IPs for each unit.

Secondly, local organization specific variables have to be defined. Change into the `vars/` dir and copy the vars-local.tmpl file:

```bash
~/projects/live-inventory-deploy$ cd vars/
~/projects/live-inventory-deploy/vars$ cp vars-local.tmpl vars-local.yml
```

ansible-playbook provision.yml -e target=raspberries -e env=dev

## Raspberry Pi Configuration

* install the rpi imager: https://www.raspberrypi.com/software/
```
cd /tmp
wget https://downloads.raspberrypi.org/imager/imager_latest_amd64.deb
apt install ./imager_latest_amd64.deb
```
* create SD card
  * Ubuntu 20.04 64bit
  * a base configuration can be given but is not really applied to the installed system!
  * the pi user is created though. Just give a very simple password to be able to login
* configure the network
```bash
parted -l
# check which partition is the sd card data partition (ext4)
mount /dev/sdb2 /mnt/
vi /mnt/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
vi /mnt/etc/netplan/50-cloud-init.yaml
umount /mnt
```

```bash
root@ubuntu:~$ cat /mnt/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}

root@ubuntu:~$ cat /etc/netplan/50-cloud-init.yaml 
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.1.1/24
      #gateway4: 192.168.1.1
  wifis:
    renderer: networkd
    wlan0:
      access-points:
        "SSID":
           password: "__passphrase__"
      dhcp4: true
      #optional: true
```
* boot the rpi with the new sd card
* after login change the keyboard layout:
```
$ dpkg-reconfigure keyboard-configuration
$ service keyboard-setup restart
```
* reboot

The Balluff unit is configured to have the IP 192.168.1.2
