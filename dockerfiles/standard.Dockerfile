# star
FROM debian:bookworm-slim

# initial update
RUN apt-get update && apt-get install -y curl

# specific for our case
RUN apt-get install	pdsh

RUN apt-get install munge
# for the computaitional node (node001)
RUN apt-get install slurmd
# for the admin
# RUN apt-get install slurmctld

RUN apt-get autoclean && apt-get autoremove

##RUN	rm -rf /var/lib/apt/lists/*
