#!/bin/bash

set -xe

if [ $(id -u) -eq 0 ] ; then
    echo "run this script as normal user - not with sudo or as root"
    exit
fi

git pull

sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  wget build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev python3-venv

if ! (which rpi-imager) ; then
    sudo wget https://downloads.raspberrypi.org/imager/imager_latest_amd64.deb
    sudo apt install ./imager_latest_amd64.deb
fi

mkdir -p $HOME/.local/bin

pip install -U pip
pip install -U pipx

pipx install pipenv

if ! ( cat $HOME/.bashrc | grep bash_pyenvlocal ) ; then
    cp ./bash_pyenvlocal $HOME/.bash_pyenvlocal
    echo ". $HOME/.bash_pyenvlocal" >> $HOME/.bashrc
fi 

if [ ! -d $HOME/.pyenv ] ; then
    wget https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer
    bash pyenv-installer
fi

. $HOME/.bash_pyenvlocal


pipenv install
