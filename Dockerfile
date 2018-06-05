# By: frankliu197 
# 
# This creates the docker image for omnetpp4.6
# If you don't need a docker image with the omnetpp GUI, you can delete all blocks of code
# that has been commented with a double hashtag (##)
# 
# Dependencies: docker
# If you have an IBM processor please read the comment with 3 hashtags
# 
# To use this program, run:
#   docker build -t <name of your image> .
#   docker run -it --rm -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix <name of your image>
#   omnetpp
# 
# You will install these dependencies:
#   Used to install other required software: software-properties-common
#   Used to run and install omnetpp: blt-dev bison flex gcc g++ make tk-dev xvfb
#   Used for the GUI of omnetpp: xterm java8
#   Dependencies of java8: libswt-gtk-3-jni libswt-gtk-3-java
#

#Use ubuntu base image
FROM ubuntu

#update repositories
RUN apt-get update 

##Install apt-get-repository
RUN apt-get install -y software-properties-common

##add java's repository
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update

#install blt-dev. This dependency will ask for your geographic location thus ENV=noninteractive
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y blt-dev 

##Install java8, the first line is used to automatically accept java8 license agreement
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN apt-get install -y oracle-java8-installer

#install other required dependencies
RUN apt-get install -y bison flex gcc g++ make tk-dev xvfb

##install other GUI related dependencies
RUN apt-get install -y xterm libswt-gtk-3-jni libswt-gtk-3-java

#add everything in this folder to the work directory in the virtual machine. 
#The work directory can be changed as you like
ARG WD="/home/user"
WORKDIR $WD
ADD . $WD

###For an IBM Power 8 Processor, you will need to uncomment the next few lines as well
#RUN export LD_LIBRARY_PATH=$WD/omnetpp-4.6/lib:$LD_LIBRARY_PATH
#RUN export HOSTNAME
#RUN export HOST
#ENV CXXFLAGS "-fPIC"
#ENV CFLAGS "-fPIC"

#install omnet
ENV PATH "$PATH:$WD/omnetpp-4.6/bin"
RUN cd omnetpp-4.6 && xvfb-run ./configure && make
