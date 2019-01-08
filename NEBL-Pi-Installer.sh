#!/bin/bash
#NEBL-Pi Installer v0.6.0 for Neblio Core v2.0

echo "================================================================================"
echo "=================== Welcome to the Official NEBL-Pi Installer =================="
echo "This script will install all necessary dependencies to run or compile nebliod"
echo "and/or neblio-qt, download the binaries or source code, and then optionally"
echo "compile nebliod, neblio-qt or both. nebliod and/or neblio-qt will be copied to"
echo "your Desktop when done."
echo ""
echo "Note that even on a new Raspberry Pi 3, the compile process can take 30 minutes"
echo "or more for nebliod and over 45 minutes for neblio-qt."
echo ""
echo "Pass -c to compile from source"
echo "Pass -d to install nebliod"
echo "Pass -q to install neblio-qt"
echo "Pass -dq to install both"
echo "Pass -x to disable QuickSync"
echo ""
echo "You can safely ignore all warnings during the compilation process, but if you"
echo "run into any errors, please report them to info@nebl.io"
echo "================================================================================"

USAGE="$0 [-d | -q | -c | -dqc]"

NEBLIODIR=~/neblpi-source
DEST_DIR=~/Desktop/
NEBLIOD=false
NEBLIOQT=false
COMPILE=false
JESSIE=false
QUICKSYNC=true

# check if we have a Desktop, if not, use home dir
if [ ! -d "$DEST_DIR" ]; then
    DEST_DIR=~/
fi

# create ~/.neblio if it does not exist
mkdir -p ~/.neblio

# check if we are running on Raspbian Jessie
if grep -q jessie "/etc/os-release"; then
    echo ""
    echo "================================================================================"
    echo "====================== Raspbian Jessie (Outdated) Detected ====================="
    echo ""
    echo "This install script is only compatible with Raspbian Stretch."
    echo "Please upgrade to Raspbian Stretch (take a backup first!)"
    echo ""
    echo "In 30 seconds this we will open a webpage detailing how to upgrade."
    echo ""
    echo "================================================================================"
    sleep 30
    python -mwebbrowser https://www.raspberrypi.org/documentation/raspbian/updating.md
    exit
fi

while getopts ':dqcx' opt
do
    case $opt in
        c) echo "Will compile all from source"
           COMPILE=true;;
        d) echo "Will Install nebliod"
	       NEBLIOD=true;;
        q) echo "Will Install neblio-qt"
	       NEBLIOQT=true;;
        x) echo "Disabling Quick Sync and using traditional sync"
           QUICKSYNC=false;;
        \?) echo "ERROR: Invalid option: $USAGE"
            echo "-c            Compile all from source"
            echo "-d            Install nebliod (default false)"
            echo "-q            Install neblio-qt (default false)"
            echo "-dq           Install both"
            echo "-x            Disable QuickSync"
        exit 1;;
    esac
done

# get sudo
if [ "$COMPILE" = true ]; then
    sudo whoami
fi

if [ "$QUICKSYNC" = true ]; then
    echo "Will use QuickSync"
fi

# update and install dependencies
if [ "$COMPILE" = true ]; then
    sudo apt-get update -y
    sudo apt-get install build-essential -y
    sudo apt-get install libboost-all-dev -y
    sudo apt-get install libdb++-dev -y
    sudo apt-get install libminiupnpc-dev -y
    sudo apt-get install libqrencode-dev -y
    sudo apt-get install libldap2-dev -y
    sudo apt-get install libidn11-dev -y
    sudo apt-get install librtmp-dev -y
    if [ "$NEBLIOQT" = true ]; then
        sudo apt-get install qt5-default -y
        sudo apt-get install qt5-qmake -y
        sudo apt-get install qtbase5-dev-tools -y
        sudo apt-get install qttools5-dev-tools -y
    fi
fi

if [ "$COMPILE" = true ]; then
    # delete our src folder and then remake it
    sudo rm -rf $NEBLIODIR
    mkdir $NEBLIODIR
    cd $NEBLIODIR

    # clone our repo, then create some necessary directories
    git clone -b master https://github.com/NeblioTeam/neblio
    
    python neblio/build_scripts/CompileOpenSSL-Linux.py
    python neblio/build_scripts/CompileCurl-Linux.py
    export OPENSSL_INCLUDE_PATH=$NEBLIODIR/openssl_build/include/
    export OPENSSL_LIB_PATH=$NEBLIODIR/openssl_build/lib/
    export PKG_CONFIG_PATH=$NEBLIODIR/curl_build/lib/pkgconfig/
    cd neblio/wallet
fi

# start our build
if [ "$NEBLIOD" = true ]; then
    if [ "$COMPILE" = true ]; then
        make "STATIC=1" -B -w -f makefile.unix
        strip nebliod
        cp ./nebliod $DEST_DIR
    else
        cd $DEST_DIR
	wget https://github.com/NeblioTeam/neblio/releases/download/v2.0/2018-12-31---v2.0-474d812---nebliod---RPi-raspbian-stretch.tar.gz
        tar -xvf 2018-12-31---v2.0-474d812---nebliod---RPi-raspbian-stretch.tar.gz
        rm 2018-12-31---v2.0-474d812---nebliod---RPi-raspbian-stretch.tar.gz
        sudo chmod 775 nebliod
    fi
    if [ ! -f ~/.neblio/neblio.conf ]; then
        echo rpcuser=$USER >> ~/.neblio/neblio.conf
        RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        echo rpcpassword=$RPCPASSWORD >> ~/.neblio/neblio.conf
        echo rpcallowip=127.0.0.1 >> ~/.neblio/neblio.conf
    fi
fi
cd ..
if [ "$NEBLIOQT" = true ]; then
    if [ "$COMPILE" = true ]; then
        wget 'https://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.bz2'
        tar -xvf qrencode-3.4.4.tar.bz2
        cd qrencode-3.4.4/
        ./configure --enable-static --disable-shared --without-tools --disable-dependency-tracking
        sudo make install
        cd ..
        qmake "USE_UPNP=1" "USE_QRCODE=1" "RELEASE=1" \
        "OPENSSL_INCLUDE_PATH=$NEBLIODIR/openssl_build/include/" \
        "OPENSSL_LIB_PATH=$NEBLIODIR/openssl_build/lib/" \
        "PKG_CONFIG_PATH=$NEBLIODIR/curl_build/lib/pkgconfig/" neblio-wallet.pro
        make -B -w
        cp ./wallet/neblio-qt $DEST_DIR
    else
        cd $DEST_DIR
        wget https://github.com/NeblioTeam/neblio/releases/download/v2.0/2019-01-01---v2.0-474d812---neblio-Qt---RPi-raspbian-stretch.tar.gz
        tar -xvf 2019-01-01---v2.0-474d812---neblio-Qt---RPi-raspbian-stretch.tar.gz
        rm 2019-01-01---v2.0-474d812---neblio-Qt---RPi-raspbian-stretch.tar.gz
        sudo chmod 775 neblio-qt
    fi
fi

if [ "$QUICKSYNC" = true ]; then
    echo "Installing Docker for QuickSync"
    sudo curl -fsSL get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo rm get-docker.sh
    sudo apt-get install docker-ce=18.06.1~ce~3-0~raspbian # until https://github.com/moby/moby/issues/38175 is resolved

    echo "Running the Neblio QuickSync container to copy the Neblio Blockchain"
    sudo docker pull neblioteam/neblio-quicksync-rpi
    /bin/bash -c "sudo docker run -i --rm --name neblio-quicksync-rpi -v $HOME/.neblio:/root/.neblio neblioteam/neblio-quicksync-rpi"
    sudo chown ${USER}:${USER} -R $HOME/.neblio
fi

if [ "$NEBLIOQT" = true ]; then
    if [ -d ~/Desktop ]; then
        echo ""
        echo "Starting neblio-qt"
        sleep 5
        nohup $DEST_DIR/neblio-qt > /dev/null &
        sleep 5
    fi
fi

echo ""
echo "================================================================================"
echo "========================== NEBL-Pi Installer Finished =========================="
echo ""
echo "If there were no errors during download or compilation nebliod and/or neblio-qt"
echo "should now be on your desktop (if you are using a CLI-only version of Raspbian"
echo "without a desktop the binaries have been copied to your home directory instead)."
echo "Enjoy!"
echo ""
echo "================================================================================"
read -rsn1 -p"Press any key to close this window";echo
