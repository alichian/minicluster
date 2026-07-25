# star
FROM debian:bookworm-slim

# initial update
RUN apt-get update && apt-get install -y curl

RUN apt-get install -y openssh-server openssh-client

RUN apt-get install -y munge

RUN apt-get install -y slurmd  

#cleanup
RUN apt-get autoclean && apt-get autoremove
RUN	rm -rf /var/lib/apt/lists/*

#dirs for the runtimes
RUN mkdir -p /var/log/sshd
RUN mkdir -p /var/log/munge

#exposing the slurmd and the ssh typical port
EXPOSE 6818 22

WORKDIR /app
 
COPY dockerfiles/node.entrypoint.sh .

RUN chmod +x /app/node.entrypoint.sh 

ENTRYPOINT ["/app/node.entrypoint.sh"]
