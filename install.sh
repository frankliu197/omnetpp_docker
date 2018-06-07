#!/bin/bash
#
# @author frankliu197
# 
# Run this install file with sudo . install.sh
# 
# This installation file will follow through steps 2 - 4 of the INSTALL.txt on MacOS, Mandrake, Debian and RedHat Distributions
# 
#

set -e

#Contains important messages from each section of the code to print at the end as an important message
message="IMPORTANT: "

#check if sudo was used to execute this program sudo -n true || { echo "You need sudo permissions to execute this program"; exit 2; }

###
# Find the OS of the computer and set its package manager and dependencies accordingly
# variables: pm (package manager), OS, dependencies (array)
# methods: lowercase() - Sets the first string to lowercase
###

readonly windows=windows
readonly debian=debian
readonly mac=mac
readonly redhat=redhat
readonly mandrake=mandrake

lowercase(){
  echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
if [ "$OS" == "windowsnt" ]; then
  OS=$windows
  echo "Error: This is for a Linux installation. "
  exit 101
elif [ "$OS" == "darwin" ]; then
  OS=$mac
  pm=brew
  exit 102
elif [ -f /etc/redhat-release ]; then
  OS=$redhat
  pm=yum
  dependencies=(bison flex tcl-devel tk-devel qt-devel libxml2-devel zlib-devel \
      doxygen graphviz openmpi-devel libpcap-devel)
elif [ -f /etc/SuSE-release ]; then
  OS=$mandrake
  pm=zypper
  dependencies=(bison flex tcl-devel tk-devel libqt5-qtbase-devel libxml2-devel zlib-devel \
      doxygen graphviz libwebkitgtk-3_0-0)
elif [ -f /etc/debian_version ]; then
  OS=$debian
  pm=apt-get
  dependencies=(bison flex qt5-default libqt5opengl5-dev tcl-dev tk-dev libxml2-dev \
      zlib1g-dev default-jre doxygen graphviz libwebkitgtk-1.0)
else
  echo "Please manually install omnetpp"; exit 1
fi

readonly OS
readonly pm
readonly dependencies

###
# Set Path varibles and test if these files exist 
###
OMNET=omnetpp-4.6
BIN=$OMNET/bin
MAC_BIN=$OMNET/tools/macosx/bin
DEFAULT_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" #cd to the directory the script is in cd "$(dirname "$0")" 

test -d "$OMNET" || { echo "$OMNET folder not found"; exit 3; }
test -d "$BIN" || { echo "$BIN folder not found"; exit 3; }
test "$OS" == "$mac" && ! -d "$MAC_BIN" && { echo "Are you sure you installed Omnetpp for Mac?"; exit 4; } 

###
# Install Dependencies
###
if [ "$OS" == "$debian" ]; then
  #Update package managers for Debian. Note that apt-get update almost always returns an error thus set +e 
  echo Currently excecuting apt-get update...
  set +e
  sudo apt-get -qq update -y
  set -e
fi

#install each dependency in the list and if installed, add the dependency name to ins
ins=()
for dep in "${dependencies[@]}"; do
  #checks if the dependency is installed
  if [ -z $(which $dep) ]; then
    echo Currently installing $dep...
    sudo $pm -qq install -y $dep
    ins+="$dep"
    echo $dep has been installed
  fi
done
    
#print message of depencies installed (this is based on the array ins)
#Format: We have installed dependencies: ins[0], ins[1] ... and ins[n] to your computer.
if [ -n "$ins" ]; then
  message="$message\nWe have installed dependencies: "
    
  #aka: for i in range: 0 to n-2
  for i in "${ins[@]::${#ins[@]}-1}"; do
    message="$message $i, "
  done

  message="$message ${ins[${#ins[@]} - 1]}."
  message="$message to your computer."
fi


function unistall_dependencies {
  #Uninstalls all the dependencies in the array dependencies if the user wishes to
  #param: NONE
  #return: 0 (No meaning)

  #loops through all the dependencies and adds all unistalled dependencies to ins
  ins()
  for dep in "${dependencies[@]}"; do
    if [ -n $(which $dep) ]; then
      sudo apt-get -qq --purge remove $dep
      echo Unistalling $dep...
      ins+=$dep
    fi
  done
    
  #print message of depencies uninstalled (this is based on the array ins)
  #Format: We have uninstalled dependencies: ins[0], ins[1] ... and ins[n] to your computer.
  if [ -n "$ins" ]; then
    message="$message\nWe have uninstalled dependencies: "
      
    #means for i in 0 to n - 2
    for i in "${ins[@]::${#ins[@]}-1}"; do
      message="$message $i, "
    done
    message="$message ${ins[${#ins[@]} - 1]}."
    message="$message from your computer."
  fi
}


###
# Adds path to bin if it is not contained in bin. 
#
# Methods:
#   NOTE: all the paths here should be relative, and you should use the defined variables above e.g. $BIN
#   path_contains       returns 1 or 0 depending on whether or not the current path contains $1
#   refresh_path        does a fresh refresh of path
#   check_path          adds $1 to path if necessary
#   add_path            adds $1 to path (helper method of check_path)
###

test "$OS" == "$mac" && . setenv

function path_contains {
  [[ ":$PATH:" == *":$PWD/$1:"* ]];
}

function refresh_path {
  #the script must be interactive for source ~/.bashrc to work, and set +e must be written (unknown reasons)
  export PATH=$DEFAULT_PATH
  set -i
  set +e
  source /etc/profile
  test -f ~/.bash_profile && source ~/.bash_profile
  test -f ~/.bash_login && source ~/.bash_login
  test -f ~/.profile && source ~/.profile
  test -f ~/.bashrc && source ~/.bashrc
  set +i
  set -e
}

function add_path {
  #Note that the path added in must be escaped or an error will occur with sourcing the file
  echo -e "\nRequired for omnetpp installation" >> ~/.bashrc
  echo -e "export PATH=\$PATH:$(echo $PWD| sed -e 's/[\& ]/\\&/g')/$1" >> ~/.bashrc
  message="$message \nAdded $PWD/$1 to your PATH through .bashrc."
}

function check_path {
  if ! path_contains $1; then
    #$1 is not in path but check if it is already written in bashrc or other files
    refresh_path
    if ! path_contains $1; then
      add_path $1
      refresh_path
    fi    
  elif refresh_path && ! path_contains $1; then
    #path contains $1 but it is only added temporary
    read -p "You have added $1 to your path temporary. Would you like to add it pernamently [y/n]: " o
    while true; do
      if [ $o = y ]; then
        add_path $1
        refresh_path
        break
      elif [ $o = n ]; then
        #due to refresh path, the temporary path is now gone. Readd it
        export PATH=\$PATH:$(echo $PWD| sed -e 's/[\& ]/\\&/g')/$1
        message="$message\nSince you added $1 to your path temporarily, you need to add it to your path everytime you start omnet.\nYou can run this script again to pernamently add $BIN to path."
        break
      else
        read -p 'Please type in y for yes and n for no [y/n]: ' o
      fi
    done
  fi
}

check_path $BIN
test "$OS" == "$mac" && check_path $MAC_BIN

###
# Final Step: Configure Omnet
###
echo Configuring omnet....
cd omnetpp-4.6
./configure
make
cd ..

###
# Show all the installation messages
###
message="\n$message\nSucessfully installed. You may run omnet with $ omnetpp from terminal"
echo -e $message
