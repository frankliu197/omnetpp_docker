FROM ubuntu

#get update, install add-apt-repository to get java repository
RUN apt-get update 
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update

#the variable is used to prevent blt-dev from asking for geographic location
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y blt-dev 

#Used to automatically accept java8 license agreement
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections

#install dependencies
RUN apt-get install -y oracle-java8-installer
RUN apt-get install -y bison flex gcc g++ make tk-dev xvfb

#copy everything in this folder to /omnet_workspace in virtual machine
WORKDIR /omnet_workspace
ADD . /omnet_workspace

#install omnet
ENV PATH "$PATH:/omnet_workspace/omnetpp-4.6/bin"
RUN cd omnetpp-4.6 && xvfb-run ./configure && make

#run omnet
CMD ["omnetpp"]

#Good stuff about docker containers that I figured out:
#1. Each command is executed in a separate container, similar to this ./Dockerfile.sh (if it were an sh) command were executed between every line
#   Thus cd omnetpp-4.6 is useless, as after that line, it refreshes to the original directory
#2. $PWD variable default /, no matter what directory you are in
#3. uses /bin/sh interpreter thus sed and expr commands are not available and cannot be installed with apt-get. I'm using xvfb-run instead
#4. If there is any command that require user input, docker either freezes or gives you an error
#5. the interpreters bin/bash seems to not exist (not sure)
#6. executed with sudo automatically but does not recognize the sudo command

#I shall now figure out how to run docker after commiting an image and add project files to this docker image
