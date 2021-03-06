#!/bin/bash
#
# @author frankliu197
# 
# Run this uninstall file with sudo . uninstall.sh
# 
# It will unistall all the dependencies if you choose to unistall it 


read -p 'Note that this might now work if you do not use a Debian distribution. Press any button to continue or CTRL-c to cancel.' o
#Contains important messages from each section of the code to print at the end as an important message
message="IMPORTANT: "

#check if sudo was used to execute this program
#sudo -n true || { echo "You need sudo permissions to execute this program"; exit 2; }

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
# Set Path variables and test if these files exist 
###
OMNET=omnetpp-4.6
BIN=$OMNET/bin
MAC_BIN=$OMNET/tools/macosx/bin
DEFAULT_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" #cd to the directory the script is in cd "$(dirname "$0")" 

test -d "$OMNET" || { echo "$OMNET folder not found"; exit 3; }
test -d "$BIN" || { echo "$BIN folder not found"; exit 3; }
test "$OS" == "$mac" && ! -d "$MAC_BIN" && { echo "Are you sure you installed Omnetpp for Mac?"; exit 4; } 

###
# uninstall Dependencies
###
unins=() #List of unistalled dependencies
nc=()    #List of installed dependencies
for dep in "${dependencies[@]}"; do
  if [ -n $(which $dep) ]; then
    echo Unistalling $dep...
    sudo $pm -qq --purge remove $dep 
    if [ $? -eq 0 ]; then
      unins+="$dep "
    else
      nc+="$dep "
    fi
  fi
done
  
#print message of depencies uninstalled (this is based on the array ins)
#Format: We have uninstalled dependencies: ins[0], ins[1] ... and ins[n] to your computer.
if [ -n "$unins" ]; then
  message="$message\nWe have uninstalled dependencies: "
    
  #means for i in 0 to n - 2
  for i in "${unins[@]::${#unins[@]}-1}"; do
    message="$message $i, "
  done
  message="$message ${unins[${#unins[@]} - 1]}."
  message="$message from your computer."
fi

#print the another message for the dependencies that have not been uninstalled
if [ -n "$nc" ]; then
  message="$message\nDependencies: "
    
  #means for i in 0 to n - 2
  for i in "${nc[@]::${#nc[@]}-1}"; do
    message="$message $i, "
  done
  message="$message ${nc[${#nc[@]} - 1]}."
  message="$message still remain.\n Use sudo $pm remove ${nc[@]} to remove them."
fi

###
# Removes path to bin if it is not contained in bin. 
#
# Methods:
#   NOTE: all the paths here should be relative, and you should use the defined variables above e.g. $BIN
#   path_contains       returns 1 or 0 depending on whether or not the current path contains $1
#   refresh_path        does a fresh refresh of path
#   check_path          removes $1 to path if necessary
#   force_remove_path   removes $1 to path (helper method of check_path)
###


function path_contains {
  [[ ":$PATH:" == *":$PWD/$1:"* ]];
}

function refresh_path {
  #the script must be interactive for source ~/.bashrc to work, and set +e must be written (unknown reasons)
  export PATH=$DEFAULT_PATH
  set -i
  source /etc/profile
  test -f ~/.bash_profile && source ~/.bash_profile
  test -f ~/.bash_login && source ~/.bash_login
  test -f ~/.profile && source ~/.profile
  test -f ~/.bashrc && source ~/.bashrc
  set +i
}

function force_delete_path {
  #Searches for path in files .profile, .bashrc and .bash_profile and delete or substite it with something else
  files=(~/.profile ~/.bashrc ~/.bash_profile ~/.bash_login)
  for file in "$files"; do
    test -f $file && sed -i "$1" $file
  done
}

function check_path {
  refresh_path

  #note that sed does not seem to support x? regex thus (x|) or \(x\|\) when escaped
  Q='\(\"\|\)' #Q for may contain quotation

  if path_contains $1; then

    ### Removes $1 from path as it was added in the install script
    #escape pwd
    new_pwd=$(echo $PWD| sed -e 's/[\& ]/\\\\&/g')
    
    #make backup files
    DATE=`date +%Y%m%d%H%M%S`
    BACKUP=~/backup_omnet$DATE
    mkdir $BACKUP
    echo "Backup files in $BACKUP for .bashrc .bash_profile and .profile. Delete if no problems exists" >> $BACKUP/README

    #Remove path like how it would be added in the install script
    if [ -f ~/.bashrc ]; then
      cp ~/.bashrc $BACKUP
      sed -i '\@^\s*#Required for omnetpp installation\s*$@d' ~/.bashrc
      sed -i "\@^\s*export PATH=$Q\$PATH:$new_pwd/$1\(/\|\)$Q\s*\$@d" ~/.bashrc
    fi
    refresh_path

    ### completely forces $1 path from the environment.
    if path_contains $1; then
      #create backup files to the other three files
      test -f ~/.bash_profile && cp ~/.bashrc $BACKUP
      test -f ~/.profile && cp ~/.profile $BACKUP
      test -f ~/.bash_login && cp ~/.bash_login $BACKUP

      #get the directory relative to ~
      dir=$(echo $PWD | sed "s@/[a-z0-9 -]*@@1")
      dir=$(echo $dir | sed "s@/[a-z0-9 -]*@@1")
      dir="~$dir"
      new_dir=$(echo $dir| sed -e 's/[\& ]/\\\\&/g')
    
      #cd back to this script again
      cd "$(dirname "$0")"

      #same as the other regex, which exports absolute path on own line
      force_delete_path "\@^\s*export PATH=$Q\$PATH:$new_pwd/$1\(/\|\)$Q\s*\$@d"
      force_delete_path "\@^\s*export PATH=$Q\$PATH:$new_dir/$1\(/\|\)$Q\s*\$@d"

      ###THIS PLACE IS WHERE IT BECOMES SLIGHTLY UNSAFE ALTHOUGH SHOULD BE FOOLPROOF ALMOST ALL THE TIME###
      #checks if it is exported with another path (assumes omnet at the end of path) 
      force_delete_path "s@:$new_pwd/$1\(/\|\)\s*\$@@" 
      force_delete_path "s@:$new_dir/$1\(/\|\)\s*\$@@"
      force_delete_path "s@:$new_pwd/$1\(/\|\)\"\s*\$@\"@" 
      force_delete_path "s@:$new_dir/$1\(/\|\)\"\s*\$@\"@"

      #same as above but assumes amnet in the middle of path
      force_delete_path "s@:$new_pwd/$1\(/\|\):@:@" 
      force_delete_path "s@:$new_dir/$1\(/\|\):@:@"

      #same as above but assmes it is in at the beginning
      force_delete_path "s@$new_pwd/$1\(/\|\):@@" 
      force_delete_path "s@$new_dir/$1\(/\|\):@@"
      force_delete_path "s@\"$new_pwd/$1\(/\|\):@\"@" 
      force_delete_path "s@\"$new_dir/$1\(/\|\):@\"@"

      #if the line is only export PATH=$PATH, delete it
      force_delete_path "\@^\s*export PATH=$Q\$PATH$Q\s*\$@d"

      refresh_path
      if path_contains $1; then
        message="$message\nCould not remove $1 from PATH. Please manually delete it. Look at backup file at $BACKUP if terminal crashes."
      fi
    else 
      message="$message\nRemoved $1 from PATH. Look at backup file at $BACKUP if terminal crashes."
    fi
  fi
}

check_path $BIN

###
# Display Unistall Message
###
message="\n\n$message\n\nSuccessfully unistalled. Please choose which projects you would like to keep and then rm -rf this folder"
echo -e $message
