# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.177.0/containers/cpp/.devcontainer/base.Dockerfile

# [Choice] Debian / Ubuntu version: debian-10, debian-9, ubuntu-20.04, ubuntu-18.04
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/cpp:0-${VARIANT}

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
RUN echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-15 main" | tee -a /etc/apt/sources.list
RUN apt-get update && apt-get install -y clang-15 llvm-15-dev libclang-15-dev libclang1-15 \
                      zlib1g-dev libomp-15-dev libpolly-15-dev perl libexpat1-dev npm
RUN test -f /usr/lib/x86_64-linux-gnu/libclang-15.so.1 || ln -s /usr/lib/x86_64-linux-gnu/libclang-15.so.15 /usr/lib/x86_64-linux-gnu/libclang-15.so.1
RUN cpan XML::Parser File::chdir Text::Diff Graph Graph::Reader::Dot
RUN node --version | grep -q v10 && npm install -g --unsafe-perm vsce@1.103.1 || npm install -g --unsafe-perm vsce

# Get external tools.
WORKDIR repo
RUN git clone https://github.com/zoocide/pts
