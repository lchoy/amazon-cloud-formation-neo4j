#!/bin/bash
# Instructions stolen from standard docs.
# https://neo4j.com/docs/operations-manual/current/installation/linux/debian/

echo '#########################################'
echo '####### BEGINNING NEO4J INSTALL #########'
echo '#########################################'

echo "neo4j-enterprise neo4j/question select I ACCEPT" | sudo debconf-set-selections
echo "neo4j-enterprise neo4j/license note" | sudo debconf-set-selections

wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt-get update

if [ $neo4j_edition = "community" ]; then
    sudo apt-get --yes install neo4j=$neo4j_version
else
    sudo apt-get --yes install neo4j-enterprise=$neo4j_version
fi

echo "Enabling neo4j system service"

# Intending to use systemd scripts, not vanilla ubuntu /etc/init.d startups.
sudo cp /lib/systemd/system/neo4j.service /etc/systemd/system/neo4j.service
sudo systemctl enable neo4j
echo "Starting neo4j..."
sudo systemctl start neo4j

# Install ancillary tools necessary for config/monitoring.
# python runtime needed for some aws internal tools, like cloudformation.
sudo apt-get --yes install jq awscli python python-setuptools

echo "Available system services"
ls /etc/systemd/system

# Instance metadata:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instancedata-data-retrieval
curl --silent http://169.254.169.254/latest/meta-data/public-hostname

echo ''
echo '#########################################'
echo '########## NEO4J POST-INSTALL ###########'
echo '#########################################'

# Provisioned copy of conf needs to be put in place.
if [ $neo4j_edition = "community" ]; then
    sudo cp /home/ubuntu/neo4j-community.conf /etc/neo4j/neo4j.template
else
    sudo cp /home/ubuntu/neo4j.conf /etc/neo4j/neo4j.template
fi

sudo cp /home/ubuntu/pre-neo4j.sh /etc/neo4j/pre-neo4j.sh
sudo cp -r /home/ubuntu/licensing /var/lib/neo4j
sudo chmod +x /etc/neo4j/pre-neo4j.sh

sudo cp /home/ubuntu/reset-password-aws.sh /etc/neo4j/reset-password-aws.sh
sudo chmod +x /etc/neo4j/reset-password-aws.sh

# Edit startup profile for this system service to call our pre-neo4j wrapper (which in turn
# runs neo4j).  The wrapper grabs key/values from cloud environment and dynamically re-writes
# neo4j.conf at startup time to properly configure it for network environment.
sudo sed -i 's/ExecStart=.*$/ExecStart=\/etc\/neo4j\/pre-neo4j.sh/' /etc/systemd/system/neo4j.service

echo "Daemon reload and restart"
sudo systemctl daemon-reload
sudo systemctl restart neo4j

sleep 20
echo "After re-configuration, service status"
sudo systemctl status neo4j
sudo journalctl -u neo4j -b

if [ $neo4j_edition = "community" ]; then
   # On first live startup of community, this signals that default password
   # should be reset, so we can have strong passwords without cloudformation.
   # See also reset-password-aws.sh, and pre-neo4j.sh where it is triggered.
   #
   # Important to do this **after** service restart above so that we don't
   # reset the default password during the packer install.
   sudo touch /etc/neo4j/password-reset.log   
fi

sudo chown neo4j /etc/neo4j/*

echo ''
echo '#########################################'
echo '########## NEO4J SETUP COMPLETE #########'
echo '#########################################'
