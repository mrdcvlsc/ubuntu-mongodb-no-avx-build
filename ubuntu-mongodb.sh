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
echo "Dependencies installation"
echo "============================================================"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    liblzma-dev \
    python3 \
    python3-venv \
    python3-pip \
    ninja-build \
    git \
    libssl-dev \
    python-dev-is-python3

echo "============================================================"
echo "Download and extract MongoDB source"
echo "============================================================"

curl -L $MONGO_SOURCE_URL -o mongo-$RELEASE_MONGO_VERSION.tar.gz
tar -xzf mongo-$RELEASE_MONGO_VERSION.tar.gz
cd mongo-$RELEASE_MONGO_VERSION

echo "============================================================"
echo "Set up environment variables for clang and architecture compatibility"
echo "============================================================"

export CC=clang
export CXX=clang++
export CFLAGS="-march=x86-64 -mtune=generic -O3"
export CCFLAGS="-march=x86-64 -mtune=generic -O3"
export CXXFLAGS="-march=x86-64 -mtune=generic -O3"

echo "============================================================"
echo "Set up Python environment"
echo "============================================================"

python3 -m venv python3-venv --prompt mongo
source python3-venv/bin/activate

echo "============================================================"
echo "Install Python dependencies"
echo "============================================================"
pip install --upgrade pip
echo "------------------------------------------------------------"
python3 -m pip install setuptools
echo "------------------------------------------------------------"
python3 -m pip install wheel
echo "------------------------------------------------------------"
python3 -m pip install distlib
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'pymongo==4.3.3'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'zope-interface==5.0.0'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'sentinels==1.0.0'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'psutil==5.8.0'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'pyyaml==5.3.1'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'cheetah3==3.2.6.post1'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'requests-oauth==0.4.1'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'pykmip==0.10.0'
echo "------------------------------------------------------------"
python3 -m pip install --no-use-pep517 'regex==2021.11.10'
echo "------------------------------------------------------------"

python3 -m pip install 'poetry==1.8.3'

echo "------------------------------------------------------------"

python3 -m poetry install --no-root --sync

if uname -a | grep -q 's390x\|ppc64le'; then
    echo "-------------------cryptography-----------------------------"
    python3 -m pip uninstall -y cryptography==2.3
    python3 -m pip install cryptography==2.3
fi

echo "============================================================"
echo "Build MongoDB"
echo "============================================================"

cp ../SConstruct-Patch ./SConstruct
python3 buildscripts/scons.py MONGO_VERSION=$MONGO_VERSION_RAW install-mongod --jobs=2 --disable-warnings-as-errors --linker=gold

# Inform the user of the build location
echo "============================================================"
echo "MongoDB build complete. Binaries are located in the 'build/install/bin' directory."
echo "============================================================"

# Cleanup (optional)
deactivate
