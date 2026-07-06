# Detailed description

In this project I choose to use a minimal *debian-slim* image. Then
any particular requirements are made a part the distinction
slurm. Then the other big problem will be how the containers will
expose the right ports to : 
- communicate with the login
- communicate each others.
So in the begin just one image with ssh and munge installed. 
