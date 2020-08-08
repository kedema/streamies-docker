FROM ubuntu:latest

LABEL maintainer="https://github.com/kedema"

# Wallet link
# Select good version for your arch, actually x86_64, and set user and group id
ENV USER_ID=1000
ENV GROUP_ID=1000
ENV DEBIAN_FRONTEND noninteractive
ENV STRMS_URL=https://github.com/Streamies/Streamies/releases/download/v2.4.3/Streamies-v2.4.3-x86_64-pc-linux-gnu.zip

# Update apt lists and download basics tools
RUN apt-get update &&\
	apt-get -y install wget unzip &&\
# Download Streamies wallet
	wget --quiet $STRMS_URL -O /tmp/wallet.zip &&\
	unzip /tmp/wallet.zip -d /usr/local/bin &&\
# Clean Up
	rm -rf /tmp/*
# Define User and set permissions
RUN groupadd -r -g $GROUP_ID strms && useradd -r -u $USER_ID -g strms -m -d /home/strmsu strmsu -s /bin/bash &&\
	chown strmsu:strms /usr/local/bin/streamies* &&\
# Clean Up
        apt-get -y remove --purge wget unzip && apt-get -y clean && apt-get -y autoremove &&\ 
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch to user
USER strmsu

# Set volume for persistence need to bind with "real" folder
VOLUME ["/home/strmsu/.streamies"]

# Expose port to node connections
EXPOSE 55297

# Exec streamiesd with container start
CMD ["/usr/local/bin/streamiesd"]
