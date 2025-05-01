#!/usr/bin/env bash
set -e

# Add user to run WAFRN as
adduser --disabled-password --gecos "" wafrn

# install and activate fluentd to have install and docker logs
apt update
apt install -y build-essential libcap-ng-dev pkgconf
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-noble-fluent-package5-lts.sh | sh
/opt/fluent/bin/fluent-gem install --no-document fluent-plugin-oci-logging
/opt/fluent/bin/fluent-gem install --no-document capng_c
/opt/fluent/bin/fluent-gem install --no-document oj
/opt/fluent/bin/fluent-cap-ctl --add dac_read_search -f /opt/fluent/bin/ruby
# quick hack to get this plugin running on recent ruby versions see https://github.com/oracle/fluent-plugin-oci-logging/pull/12
sed -i 's/exists/exist/g' /opt/fluent/lib/ruby/gems/3.2.0/gems/fluent-plugin-oci-logging-1.0.12/lib/fluent/plugin/os.rb || true
mv -f /fluentd.conf /etc/fluent/fluentd.conf
systemctl restart fluentd

# allow ports 80&443
iptables -I INPUT 2 -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 2 -m state --state NEW -p tcp --dport 443 -j ACCEPT
iptables -I INPUT 2 -m state --state NEW -p udp --dport 443 -j ACCEPT
netfilter-persistent save

# add local DNS config as a workaround as DNS will only be setup much later, but the instances need it
source /wafrn-cloud-config
PUBLIC_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
if [ -n "${PDS_DOMAIN_NAME}" ]; then
  echo "$PUBLIC_IP $DOMAIN_NAME $PDS_DOMAIN_NAME" >> /etc/hosts
else
  echo "$PUBLIC_IP $DOMAIN_NAME" >> /etc/hosts
fi

# install backup scripts and packages
mv /offsite.s3cfg /home/wafrn/offsite.s3cfg
mv /onsite.s3cfg /home/wafrn/onsite.s3cfg
mv /post_backup.sh /home/wafrn/post_backup.sh
chown -R wafrn:wafrn /home/wafrn
apt install -y s3cmd

# Download WAFRN installer and execute it
sudo -u wafrn bash -c 'cd /home/wafrn && wget https://raw.githubusercontent.com/gabboman/wafrn/main/install/installer.sh'
sudo -u wafrn bash -c 'cd /home/wafrn && chmod 755 /home/wafrn/installer.sh && /home/wafrn/installer.sh --unattended'

# Remove the sudo config that allowed the installer above to use sudo during installation
rm /etc/sudoers.d/200-wafrn-setup
