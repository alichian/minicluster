# start
FROM debian:trixie-slim

# initial update
RUN apt-get update && apt-get install -y curl 

RUN apt-get install -y openssh-server openssh-client 

RUN apt-get install -y munge

RUN apt-get install -y slurmctld  

#cleanup
RUN apt-get autoclean && apt-get autoremove
RUN	rm -rf /var/lib/apt/lists/*

#dirs for the runtimes
RUN mkdir -p /var/log/sshd
RUN mkdir -p /var/log/munge

#exposing the slurmctld and the ssh typical port
EXPOSE 6817 22

WORKDIR /app
 
COPY dockerfiles/admin.entrypoint.sh .
     
RUN chmod +x /app/admin.entrypoint.sh 

ENTRYPOINT ["/app/admin.entrypoint.sh"] 
