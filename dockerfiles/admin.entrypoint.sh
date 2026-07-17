#!/bin/bash -x

#setup Chain Authorisation and dirs used by sshd, munge and slurmctld

#for ssh 
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp -p /tmp/shared-data/slurm-rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

#for sshd
mkdir -p /run/sshd
chmod 0755 /run/sshd

#for munge
mkdir -p /var/log/munge /run/munge /etc/munge
cp -f /tmp/shared-data/munge.key /etc/munge/munge.key
chown -R munge:munge /var/log/munge /run/munge /etc/munge
chmod -R 700 /var/log/munge /var/run/munge
chmod 0755 /run/munge
chmod 400 /etc/munge/munge.key

#for slurm
mkdir -p /var/spool/slurmctld
chown -R slurm:slurm /var/spool/slurmctld
chmod 755 /var/spool/slurmctld
cp -p /tmp/shared-data/slurm.conf /etc/slurm/slurm.conf
chown slurm:slurm /etc/slurm/slurm.conf 

# Start SSH daemon in the background
echo "Starting SSH..."
/usr/sbin/sshd

#start Munge daemon in the background
su -s /bin/bash -c "/usr/sbin/munged" munge 

# Start Slurm daemon in the foreground (this keeps the container alive)
echo "Starting Slurmctld..."
exec /usr/sbin/slurmctld -D
