#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 24 0 ${@} || exit 1

# Configure and install squid env.
sudo systemctl stop squid
sudo apt remove squid
sudo apt autoremove

cd ../downloads
wget https://www.squid-cache.org/Versions/v6/squid-$MITHRIL_SQUID_VERSION.tar.gz
tar xzf squid-$MITHRIL_SQUID_VERSION.tar.gz
cd squid-$MITHRIL_SQUID_VERSION

./configure \
    --prefix=$MITHRIL_SQUID_HOME \
    --localstatedir=$MITHRIL_SQUID_HOME/var \
    --libexecdir=$MITHRIL_SQUID_HOME/lib/squid \
    --datadir=$MITHRIL_SQUID_HOME/share/squid \
    --sysconfdir=/etc/squid \
    --with-default-user=squid \
    --with-logdir=$MITHRIL_SQUID_HOME/var/log/squid \
    --with-pidfile=$MITHRIL_SQUID_HOME/var/run/squid.pid

make
sudo make install
/opt/squid/sbin/squid -v

