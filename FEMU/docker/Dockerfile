FROM ubuntu:22.04

RUN apt update && apt install -y git sudo wget python3-venv python3-pip
RUN pip3 install tomli tomli-w

WORKDIR /root

RUN git clone https://github.com/MoatLab/FEMU.git
RUN cd FEMU && mkdir build-femu

WORKDIR /root/FEMU/build-femu

RUN cp ../femu-scripts/femu-copy-scripts.sh . && ./femu-copy-scripts.sh . 
RUN ./pkgdep.sh && rm -rf /var/lib/apt/lists/*

RUN ./femu-compile.sh

RUN mkdir -p /root/images
RUN wget --no-check-certificate "https://drive.usercontent.google.com/download?id=1hhPNPJ2PZH7dFnk5pxGUwPOu9dpbcc3B&confirm=t" -O /root/images/u20s.qcow2
