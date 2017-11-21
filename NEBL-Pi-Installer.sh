#!/bin/bash
#NEBL-Pi Installer v0.1

echo "================================================================================"
echo "=================== Welcome to the Ofiicial NEBL-Pi Installer =================="
echo "This script will install all necessary dependencies to compile nebliod and/or"
echo "neblio-qt, download the source code, and then compile nebliod, neblio-qt or"
echo "both. nebliod and/or neblio-qt will be copied to your Desktop when done."
echo ""
echo "Note that even on a new Raspberry Pi 3, the compile process can take 30 minutes"
echo "or more for nebliod and over 45 minutes for neblio-qt."
echo ""
echo "Pass -d to build nebliod"
echo "Pass -q to build neblio-qt"
echo "Pass -dq to build both"
echo ""
echo "You can safely ignore all warnings during the compilation process, but if you"
echo "run into any errors, please report them to info@nebl.io"
echo "================================================================================"

USAGE="$0 [-d | -q | -dq]"

NEBLIODIR=~/neblpi-source
NEBLIOD=false
NEBLIOQT=false

while getopts ':dq' opt
do
    case $opt in
        d) echo "Will Build nebliod"
	   NEBLIOD=true;;
        q) echo "Will Build neblio-qt"
	   NEBLIOQT=true;;
        \?) echo "ERROR: Invalid option: $USAGE"
	    echo "-d            Build nebliod (default false)"
	    echo "-q            Build neblio-qt (default false)"
	    echo "-dq           Build both"
            exit 1;;
    esac
done

# update and install dependencies
sudo apt-get update -y
sudo apt-get install build-essential -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install libdb++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libqrencode-dev -y
if [ "$NEBLIOQT" = true ]; then
    sudo apt-get install qt5-default -y
    sudo apt-get install qt5-qmake -y
    sudo apt-get install qtbase5-dev-tools -y 
    sudo apt-get install qttools5-dev-tools -y
fi
sudo aptitude install libssl1.0-dev -y

# delete our src folder and then remake it
sudo rm -rf $NEBLIODIR
mkdir $NEBLIODIR
cd $NEBLIODIR

# make sure git is installed and clone our repo, then create some necessary directories
sudo apt-get install git -y
git clone https://github.com/NeblioTeam/neblio
cd neblio/src
mkdir obj
cd obj
mkdir zerocoin
cd ..
cd leveldb
chmod 755 *
cd ..

# start our build
if [ "$NEBLIOD" = true ]; then
    make -B -w -f makefile.unix
    strip nebliod
    cp ./nebliod ~/Desktop/
fi
cd ..
if [ "$NEBLIOQT" = true ]; then
    qmake "USE_UPNP=1" "USE_QRCODE=1" neblio-qt.pro
    make -B -w
    cp ./neblio-qt ~/Desktop/
fi
echo ""
echo "================================================================================"
echo "========================== NEBL-Pi Installer Finished =========================="
echo ""
echo "If there were no errors during compilation nebliod and/or neblio-qt should now"
echo "be on your desktop. Enjoy!"
echo ""
echo "================================================================================"
