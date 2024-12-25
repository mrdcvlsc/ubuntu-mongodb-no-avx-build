#!/bin/bash

# run with: chmod +x ubuntu-mongodb.sh

# exit immediately on error
set -e

# MongoDB version and source information
MONGO_VERSION="r8.0.4"
MONGO_VERSION_RAW="8.0.4"
MONGO_SOURCE_URL="https://github.com/mongodb/mongo/archive/refs/tags/$MONGO_VERSION.tar.gz"

# Dependencies installation
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
    libssl-dev

# Download and extract MongoDB source
curl -L $MONGO_SOURCE_URL -o mongo-$MONGO_VERSION.tar.gz
tar -xzf mongo-$MONGO_VERSION.tar.gz
cd mongo-$MONGO_VERSION

# Set up Python environment
python3 -m venv python3-venv --prompt mongo
source python3-venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
python3 -m pip install 'poetry==1.8.3'
python3 -m poetry install --no-root --sync

# Set up environment variables for clang and architecture compatibility
export CC=clang
export CXX=clang++
export CFLAGS="-march=x86-64 -mtune=generic -O3"
export CCFLAGS="-march=x86-64 -mtune=generic -O3"
export CXXFLAGS="-march=x86-64 -mtune=generic -O3"

# Build MongoDB
python3 buildscripts/scons.py MONGO_VERSION=$MONGO_VERSION_RAW install-mongod --jobs=2 --disable-warnings-as-errors --linker=gold

# Inform the user of the build location
echo "MongoDB build complete. Binaries are located in the 'build/install/bin' directory."

# Cleanup (optional)
deactivate
