# start
FROM debian:bookworm-slim

# initial update
RUN apt-get update && apt-get install -y curl

RUN apt-get install -y munge

RUN apt-get install -y slurmctld  

#cleanup
RUN apt-get autoclean && apt-get autoremove
RUN	rm -rf /var/lib/apt/lists/*

#dirs for the runtimes
RUN mkdir -p /var/log/sshd /var/log/munge /etc/munge 


EXPOSE 22 

CMD ["/usr/sbin/slurmctld", "-D" ] 
