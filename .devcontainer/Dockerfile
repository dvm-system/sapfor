# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.177.0/containers/cpp/.devcontainer/base.Dockerfile

# [Choice] Debian / Ubuntu version: debian-10, debian-9, ubuntu-20.04, ubuntu-18.04
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/cpp:0-${VARIANT}

RUN apt-get update && \
    apt-get install -y clang-11 llvm-11-dev libclang-11-dev \
                       zlib1g-dev libomp-11-dev perl libexpat1-dev npm
RUN cpan XML::Parser File::chdir Text::Diff Graph Graph::Reader::Dot
RUN node --version | grep -q v10 && npm install -g --unsafe-perm vsce@1.103.1 || npm install -g --unsafe-perm vsce

# Get external tools.
WORKDIR repo
RUN git clone https://github.com/zoocide/pts
