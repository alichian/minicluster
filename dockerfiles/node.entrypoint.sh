#!/bin/bash -x

#setup Chain Authorisation and dirs used by sshd, munge and slurmctld

#for ssh 
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat /tmp/shared-data/slurm-rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

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
mkdir -p /var/spool/slurmd
chown -R slurm:slurm /var/spool/slurmd
chmod 755 /var/spool/slurmd
cp -p /tmp/shared-data/slurm.conf /etc/slurm/slurm.conf
cp /tmp/shared-data/cgroup.conf   /etc/slurm/cgroup.conf
chown slurm:slurm /etc/slurm/slurm.conf /etc/slurm/cgroup.conf

# Start SSH daemon in the background
echo "Starting SSH..."
/usr/sbin/sshd

#start Munge daemon in the background
su -s /bin/bash -c "/usr/sbin/munged" munge 

# Start Slurm daemon in the foreground (this keeps the container alive)
echo "Starting Slurmd..."
exec /usr/sbin/slurmd -D
