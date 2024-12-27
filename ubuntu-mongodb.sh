#!/bin/bash

# run with: chmod +x ubuntu-mongodb.sh

# exit immediately on error
set -e

# MongoDB version and source information
MONGO_VERSION_RAW="8.0.4"
# MONGO_VERSION_RAW="7.0.16"

RELEASE_MONGO_VERSION="r$MONGO_VERSION_RAW"
MONGO_SOURCE_URL="https://github.com/mongodb/mongo/archive/refs/tags/$RELEASE_MONGO_VERSION.tar.gz"

echo "============================================================"
echo "Installing Python 3.10.x"
echo "============================================================"

sudo add-apt-repository ppa:deadsnakes/ppa
echo "---------------------py01-----------------------------------"
sudo apt-get update
echo "---------------------py02-----------------------------------"
sudo apt-get upgrade
echo "---------------------py03-----------------------------------"
sudo apt-get install python3.10
echo "---------------------py04-----------------------------------"
sudo apt-get install python3.10-venv
echo "---------------------py04.5---------------------------------"
sudo apt-get install python3-dev
echo "---------------------py04.7---------------------------------"
sudo apt-get install python3.10-dev
# echo "---------------------py05-----------------------------------"
# sudo apt-get install python3.10-pip
echo "---------------------py06-----------------------------------"
sudo apt-get install python-dev-is-python3

echo "============================================================"
echo "Dependencies installation"
echo "============================================================"

sudo apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    liblzma-dev \
    ninja-build \
    git \
    libssl-dev

echo "============================================================"
echo "Install Clang"
echo "============================================================"

wget https://apt.llvm.org/llvm.sh

echo "------------------------------------------------------------"

chmod +x llvm.sh

echo "------------------------------------------------------------"

sudo ./llvm.sh

echo "------------------------------------------------------------"

clang -v

echo "============================================================"
echo "Download and extract MongoDB source"
echo "============================================================"

curl -L $MONGO_SOURCE_URL -o mongo-$RELEASE_MONGO_VERSION.tar.gz
tar -xzf mongo-$RELEASE_MONGO_VERSION.tar.gz
cd mongo-$RELEASE_MONGO_VERSION

echo "============================================================"
echo "Set up Python environment"
echo "============================================================"

python3.10 -m venv python3-venv --prompt mongo
source python3-venv/bin/activate

echo "============================================================"
echo "Install Python dependencies"
echo "============================================================"

echo "---------------------py07-----------------------------------"

echo "Using python version:"
python --version

echo "---------------------py08-----------------------------------"

echo "Using python version:"
python3 --version

echo "---------------------py09-----------------------------------"

echo "Using python version:"
python3.10 --version

echo "------------------------------------------------------------"
python3.10 -m pip install --upgrade pip
echo "------------------------------------------------------------"
python3.10 -m pip install setuptools
echo "------------------------------------------------------------"
python3.10 -m pip install wheel
echo "------------------------------------------------------------"
python3.10 -m pip install distlib
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'pymongo==4.3.3'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'zope-interface==5.0.0'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'sentinels==1.0.0'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'psutil==5.8.0'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'pyyaml==5.3.1'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'cheetah3==3.2.6.post1'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'requests-oauth==0.4.1'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'pykmip==0.10.0'
echo "------------------------------------------------------------"
python3.10 -m pip install --no-use-pep517 'regex==2021.11.10'
echo "------------------------------------------------------------"

python3.10 -m pip install 'poetry==1.8.3'

echo "------------------------------------------------------------"

python3.10 -m poetry install --no-root --sync

if uname -a | grep -q 's390x\|ppc64le'; then
    echo "-------------------cryptography-----------------------------"
    python3.10 -m pip uninstall -y cryptography==2.3
    python3.10 -m pip install cryptography==2.3
fi

echo "============================================================"
echo "Set up environment variables for clang and architecture compatibility"
echo "============================================================"

export CC=clang
export CXX=clang++
export CFLAGS="-march=x86-64 -mtune=generic -O2"
export CCFLAGS="-march=x86-64 -mtune=generic -O2"
export CXXFLAGS="-march=x86-64 -mtune=generic -O2"

CC=clang
CXX=clang++
CFLAGS="-march=x86-64 -mtune=generic -O2"
CCFLAGS="-march=x86-64 -mtune=generic -O2"
CXXFLAGS="-march=x86-64 -mtune=generic -O2"

echo "============================================================"
echo "Build MongoDB"
echo "============================================================"

cp ../SConstruct-Patch ./SConstruct

echo "------------------------------------------------------------"

python3.10 -m pip install cxxfilt

echo "------------------------------------------------------------"

python3.10 buildscripts/scons.py MONGO_VERSION=$MONGO_VERSION_RAW install-mongod --force-jobs --jobs=8 --disable-warnings-as-errors --linker=gold

echo "============================================================"
echo "MongoDB build complete. Binaries are located in the 'build/install/bin' directory."
echo "============================================================"

# Cleanup (optional)
deactivate
