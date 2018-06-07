#!/bin/bash
#
# Startup/unistall omnet script.
# To start this script run sudo ./configure.sh in the folder that contains the folder omnetpp4-6
# Note that the unistall script is not used.
#
# @author frankliu197
# 

set -e

#Contains important messages from each section of the code to print at the end as an important message
message="IMPORTANT: "

#check if sudo was used to execute this program
sudo -n true || { echo "You need sudo permissions to execute this program"; exit 2; }

lowercase(){
  echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

#find the operating system type, and set the variables, package manager, and dependencies
OS=`lowercase \`uname\``

if [ "${OS}" == "windowsnt" ]; then
  OS=Windows
  echo "Error: This is for a Linux installation. "
  exit 101
elif [ "{$OS}" == "darwin" ]; then
  OS=Mac
  echo "Error: This is for a Linux installation. " 
  exit 102
elif [ -f /etc/redhat-release ]; then
  OS=RedHat
  pm=yum
  dependencies=(bison flex tcl-devel tk-devel qt-devel libxml2-devel zlib-devel \
      doxygen graphviz openmpi-devel libpcap-devel)
elif [ -f /etc/SuSE-release ]; then
  OS=Mandrake
  pm=zypper
  dependencies=(bison flex tcl-devel tk-devel libqt5-qtbase-devel libxml2-devel zlib-devel \
      doxygen graphviz libwebkitgtk-3_0-0)
elif [ -f /etc/debian_version ]; then
  OS=Debian
  pm=apt-get
  dependencies=(bison flex qt5-default libqt5opengl5-dev tcl-dev tk-dev libxml2-dev \
      zlib1g-dev default-jre doxygen graphviz libwebkitgtk-1.0)
else
  echo "Please manually install omnetpp" exit 1
fi

#add path variables
OMNET=omnetpp-4.6
BIN=$OMNET/bin
DEFAULT_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" #cd to the directory the script is in cd "$(dirname "$0")" 

#Test if and this script is in the right directory
test -d "$OMNET" || { echo "$OMNET folder not found"; exit 3; }
test -d "$BIN" || { echo "$BIN folder not found"; exit 3; }

#Creating an array of dependencies for omnetpp-4.6
#This array is referenced in install and unistall dependencies
#To add a new dependency, add its name to this list
#dependencies=(tk-dev blt-dev bison flex)

#Methods to call when installing or unistalling the program
#The array will be looped through and every element will be called as if it were a method in this script
install=(install_dependencies add_bin configure_omnet install_message)
#unistall=(uninstall_dependencies remove_bin unistall_message)

#Set the operation the user choose to either install or unistall,
#based on the user input, i or u
#read -p 'Would you like to install or unistall omnetpp [i/u]: ' o
#while true; do
#  if [ $o = i ]; then
    option=( "${install[@]}" ) 
#    break
#  elif [ $o = u ]; then
#    option=( "${unistall[@]}" )
#    break
#  else
#    read -p 'Please type in i for install or u for unistall [i/u]: ' o
#  fi
#done

function install_dependencies {
  #Installs all the dependencies in the array dependencies
  #param: NONE
  #return: 0

  echo Currently excecuting apt-get update...
  
  if [ "{$OS}" == "Debian" ]; then
    #apt-get update will almost always return an error thus set +e to prevent the script from exiting
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
}

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


function path_contains_bin? {
  #checks if the current path contains $bin
  #Param: none
  #return 0 or 1 for true or false
  [[ ":$PATH:" == *":$PWD/$BIN:"* ]];
}

function refresh_path {
  #will do a full refresh of path
  #Param: none
  #Return: 0

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

function add_path_to_bashrc {
  #adds oment/bin into your path in bashrc
  #Param: None
  #Return: 0

  #Note that the path added in must be escaped or an error will occur with sourcing the file
  echo -e "\n#Adds omnet/bin to your path" >> ~/.bashrc
  echo -e "export PATH=\$PATH:$(echo $PWD| sed -e 's/[\& ]/\\&/g')/$BIN" >> ~/.bashrc
  message="$message \nAdded $PWD/$BIN to your PATH through .bashrc. Run source ~/.bashrc for changes to take affect."
}

function add_bin {
  #General function when installing
  #Checks if it is necessary to add $BIN to your path and adds it there if it is
  #Param: NONE
  #Return: 0
  

  if ! path_contains_bin?; then
    #this means that path does contain $BIN. Refresh path (in case the user added $BIN to one of the files and forgot to source it
    #If path still doesn't exists, add $BIN to path
    refresh_path
    if ! path_contains_bin?; then
      add_path_to_bashrc
      refresh_path
    else
      message="$message\nYou have already added $BIN to your path, but you need to refresh terminal for changes to take effect."
    fi
  elif refresh_path && ! path_contains_bin?; then
    #this means that path does contain $BIN but after refreshing it doesn't.
    #Thus the user added $BIN to path temporarily

    #Ask and add (if necessary) if the user wants to add $BIN to path pernamently, y for yes and n for no
    o=' ' #reset the o value
    read -p "You have added $BIN to your path temporary. Would you like to add it pernamently [y/n]: " o
    while true; do
      if [ $o = y ]; then
        add_path_to_bashrc
        refresh_path
        break
      elif [ $o = n ]; then
        message="$message\nSince you added $BIN to your path temporarily, you need to add it to your path everytime you start omnet.\nYou can run this script again to pernamently add $BIN to path."
        break
      else
        read -p 'Please type in y for yes and n for no [y/n]: ' o
      fi
    done
  fi
}

function force_delete_path {
  #Searches for path in files .profile, .bashrc and .bash_profile and delete or substite it with something else
  #Param: the input of sed -i
  #Return: 0

  files=(~/.profile ~/.bashrc ~/.bash_profile)
  for file in "$files"; do
    test -f $file && sed -i "$1" $file
  done
}

function remove_bin {
  #Removes bin from path
  #Param: None
  #Return: 0, but may not succeed. If it doesn't. a string explaination is added to $message

  refresh_path

  #removes omnet/bin from path
  if path_contains_bin? ; then

    #escape pwd
    new_pwd=$(echo $PWD| sed -e 's/[\& ]/\\\\&/g')
    
    #make backup files
    mkdir ~/backup_omnet
    echo "Backup files in ~/baskup_omnet for .bashrc .bash_profile and .profile. Delete if no problems exists" >> ~/backup_omnet/README

    #note that sed does not seem to support x? regex thus (x|) or \(x\|\) when escaped
    Q=\(\"\|\) #Q for may contain quotation

    #if bashrc exists, make a backup and replace everything added in the function add_bin_to_path
    if [ -f ~/.bashrc ]; then
      cp ~/.bashrc ~/backup_omnet
      sed -i '\@^\s*#Adds omnet/bin to your path\s*$@d' ~/.bashrc
      sed -i "\@^\s*export PATH=\$PATH:$new_pwd/$BIN\(/\|\)\s*\$@d" ~/.bashrc
    fi

    #Test if path is removed if not, try finding path using different regexs
    refresh_path
    if path_contains_bin? ; then
      #create backup files to the other three files
      test -f ~/.bash_profile && cp ~/.bashrc ~/backup_omnet
      test -f ~/.profile && cp ~/.profile ~/backup_omnet
      test -f ~/.bash_login && cp ~/.bash_login ~/backup_omnet

      #get the directory relative to ~
      dir=$(echo $PWD | sed "s@/[a-z0-9 -]*@@1")
      dir=$(echo $dir | sed "s@/[a-z0-9 -]*@@1")
      dir="~$dir"
      new_dir=$(echo $dir| sed -e 's/[\& ]/\\\\&/g')
    
      #cd back to this script again
      cd "$(dirname "$0")"

      #same as the other regex, export absolute path on own line
      force_delete_path "\@^\s*export PATH=\$PATH:$new_pwd/$BIN\(/\|\)\s*\$@d"
      force_delete_path "\@^\s*export PATH=\$PATH:$new_dir/$BIN\(/\|\)\s*\$@d"

      #checks if it is exported with another path (assumes omnet at the end of path) 
      force_delete_path "s@:$new_pwd/$BIN\(/\|\)\s*\$@@" 
      force_delete_path "s@:$new_dir/$BIN\(/\|\)\s*\$@@"

      #same as above but assumes amnet in the middle of path
      force_delete_path "s@:$new_pwd/$BIN\(/\|\):\s*\$@:@" 
      force_delete_path "s@:$new_dir/$BIN\(/\|\):\s*\$@:@"

      #same as above but assmes it is in at the beginning
      force_delete_path "s@$new_pwd/$BIN\(/\|\):\s*\$@@" 
      force_delete_path "s@$new_dir/$BIN\(/\|\):\s*\$@@"

      refresh_path
      if path_contains_bin? ; then
        message="$message\nCould not remove $BIN from PATH. Please manually delete it. Look at backup file at ~/bashup_omnet if terminal crashes."
      fi
    else 
      message="$message\nRemoved $BIN from .bashrc. Look at backup file at ~/bashup_omnet if terminal crashes."
    fi
  fi
}

function configure_omnet {
  #this will configure and compile omnet code
  #Param: NONE
  #Return: 0
  echo Configuring omnet....
  cd omnetpp-4.6
  ./configure
  make
  cd ..
}

function install_message {
  #adds install related messages into $message

  #Gives different messages based on whether the message please source ~/.bashrc exists
  if [[ "$message" == *"source ~/.bashrc"* ]]; then
    message="\n$message\nSucessfully installed. You may run omnet with $ omnetpp from terminal after reseting your terminal or running $ source ~/.bashrc"
  else
    message="\n$message\nSuccessfully installed, You may run omnet with $ omnetpp from terminal"
  fi
}

function unistall_message {
  #adds unistall related messages into $message
  message="\n\n$message\n\nSuccessfully unistalled. You may need to reset terminal for changes to take effect.\n Please choose which projects you would like to keep and then rm -rf $OMNET manually."
}

#Will loop through every element in the option array and call it as a method
for arg in "${option[@]}"; do
  eval $arg
done

#echos all the message of this installation
echo -e $message
