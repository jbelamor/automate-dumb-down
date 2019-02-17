FROM debian:stable

###################
# Installing shit #
###################
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install bash \
    git \
    sudo \
    python3 \
    python3-pip \
    freeradius \
    aircrack-ng \
    libssl-dev \
    libnl-dev

################
# Hostapd shit #
################
RUN mkdir /opt/automate_dumb_down && \
    cd /opt && \
    git clone https://github.com/OpenSecurityResearch/hostapd-wpe.git &&

RUN wget http://hostap.epitest.fi/releases/hostapd-2.6.tar.gz && \
    tar -zxf hostapd-2.6.tar.gz && \
    cd hostapd-2.6 && \
    patch -p1 < ../hostapd-wpe/hostapd-wpe.patch  && \
    cd hostapd && \
    make && \
    ../../hostapd-wpe/certs/bootstrap && \
    cd ../../hostapd-2.6/hostapd

#COPY hostapd-base.conf /opt/hostapd-wpe/hostapd/hostapd_dumb_down.conf

###################
# Freeradius shit #
###################
RUN mv /etc/freeradius/eap.conf /etc/freeradius/eap.conf.back
COPY radius_config_file /etc/freeradius/eap.conf

######################################
# Deploying script and starting shit #
######################################
COPY base_script.sh /opt

ENTRYPOINT ["/opt/base_script.sh"]