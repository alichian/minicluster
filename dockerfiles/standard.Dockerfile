# star
FROM debian:bookworm-slim

# initial update
RUN apt-get update && apt-get install -y curl

RUN apt-get install munge
# for the computaitional node (node001)
# RUN apt-get install -y slurmd
# for the admin
# RUN apt-get install slurmctld

RUN apt-get autoclean && apt-get autoremove

#move the munge key 

RUN	rm -rf /var/lib/apt/lists/*

EXPOSE 8022

CMD ["/bin/bash"] 
