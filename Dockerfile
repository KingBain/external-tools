# Debian builds of HMMER and Skewer.
FROM debian:buster as debian
WORKDIR /build
RUN apt-get update && apt-get install -y build-essential wget bioperl
RUN wget https://bitbucket.org/wenchen_aafc/aodp_v2.0_release/raw/5fcd5d2dfde61cd87ad3c63b8c92babd281fc0dc/aodp-2.5.0.1.tar.gz && \
    tar -xvf aodp-2.5.0.1.tar.gz && \
    cd aodp-2.5.0.1 && \
    ./configure && \
    make && \
    mv b/aodp /build && \
    wget http://eddylab.org/software/hmmer/hmmer-3.2.1.tar.gz && \
    tar -xf hmmer-3.2.1.tar.gz && \
    cd hmmer-3.2.1 && \
    ./configure --prefix /build/hmmer && \
    make && \
    make install && \
    wget https://github.com/relipmoc/skewer/archive/0.2.2.tar.gz && \
    tar -xf 0.2.2.tar.gz && \
    cd skewer-0.2.2 && \
    make && \
    mv skewer /build

# FastQC
FROM alpine:latest as fastqc
WORKDIR /build
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip && \
    unzip fastqc_v0.11.5.zip

# Bowtie2
FROM alpine:latest as bowtie
WORKDIR /build
RUN wget https://github.com/BenLangmead/bowtie2/releases/download/v2.3.2/bowtie2-2.3.2-legacy-linux-x86_64.zip && \
    unzip bowtie2-2.3.2-legacy-linux-x86_64.zip && \
    mkdir bowtie2 && \
    cp bowtie2-2.3.2-legacy/bowtie2* bowtie2

# FLASh
FROM alpine:latest as flash
WORKDIR /build
RUN wget http://ccb.jhu.edu/software/FLASH/FLASH-1.2.11-Linux-x86_64.tar.gz && \
    tar -xvf FLASH-1.2.11-Linux-x86_64.tar.gz && \
    mv FLASH-1.2.11-Linux-x86_64/flash .

# SPAdes
FROM alpine:latest as spades
WORKDIR /build
RUN wget https://github.com/ablab/spades/releases/download/v3.11.0/SPAdes-3.11.0-Linux.tar.gz && \
    tar -xvf SPAdes-3.11.0-Linux.tar.gz && \
    mv SPAdes-3.11.0-Linux spades

#Spring
FROM debian:buster as spring
WORKDIR /build
RUN apt-get update && apt-get install -y make cmake g++ zlib1g-dev  wget
RUN wget https://github.com/shubhamchandak94/Spring/archive/refs/tags/v1.0.1.tar.gz && \
    tar -xzvf v1.0.1.tar.gz && \
    cd Spring-1.0.1 && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make


# Build
FROM python:3.8-buster
COPY --from=debian /build/aodp /usr/local/bin/
COPY --from=debian /build/hmmer /opt/hmmer
COPY --from=debian /build/skewer /usr/local/bin/
COPY --from=fastqc /build/FastQC /opt/fastqc
COPY --from=bowtie /build/bowtie2/* /usr/local/bin/
COPY --from=flash /build/flash /opt/flash
COPY --from=spades /build/spades /opt/spades
COPY --from=spring /build/Spring-1.0.1/build/spring /usr/local/bin/spring
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jre && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean
RUN chmod ugo+x /opt/fastqc/fastqc && \
    ln -fs /opt/spades/bin/spades.py /usr/local/bin/spades.py && \
    ln -fs /opt/fastqc/fastqc /usr/local/bin/fastqc && \
    for file in `ls /opt/hmmer/bin`; do ln -fs /opt/hmmer/bin/${file} /usr/local/bin/${file};  done
CMD ["python3"]
