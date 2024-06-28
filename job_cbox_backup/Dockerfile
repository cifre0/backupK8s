FROM ubuntu:latest

USER root

# update and install package
RUN apt-get update
RUN apt-get install -y curl

# Install kubectl
RUN curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# install mc_client
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -s -o $HOME/minio-binaries/mc
RUN chmod +x $HOME/minio-binaries/mc
RUN export PATH=$PATH:$HOME/minio-binaries
ENV PATH="$PATH:$HOME/minio-binaries"
