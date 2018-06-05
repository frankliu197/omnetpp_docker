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
RUN apt-get install -y xterm
RUN apt-get install -y libswt-gtk-3-jni libswt-gtk-3-java

#copy everything in this folder to /omnet_workspace in virtual machine
WORKDIR /home/xterm
ADD . /home/xterm

#install omnet
ENV PATH "$PATH:/home/xterm/omnetpp-4.6/bin"
RUN cd omnetpp-4.6 && xvfb-run ./configure && make
