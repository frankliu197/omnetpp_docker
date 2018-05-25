FROM ubuntu
RUN apt-get update 
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y blt-dev 
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN apt-get install -y oracle-java8-installer
RUN apt-get install -y bison flex gcc g++ make tk-dev xvfb

#create workspace
WORKDIR /omnet_workspace
ADD . /omnet_workspace

ENV PATH "$PATH:/omnet_workspace/omnetpp-4.6/bin"
RUN echo "$PATH"
RUN cd omnetpp-4.6 && xvfb-run ./configure && make

CMD ["omnetpp"]

#$PWD variable not set in docker
