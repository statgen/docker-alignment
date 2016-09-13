FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libncurses-dev \
    unzip \
    zlib1g-dev

RUN curl -L https://github.com/lh3/bwa/archive/v0.7.15.zip > /root/bwa.zip
RUN unzip /root/bwa.zip -d /root
RUN rm /root/bwa.zip
RUN make -C /root/bwa-0.7.15
RUN ln -s /root/bwa-0.7.15/bwa /usr/bin/bwa
RUN curl -L https://github.com/samtools/htslib/archive/1.3.1.zip > /root/htslib.zip
RUN unzip /root/htslib.zip -d /root
RUN rm /root/htslib.zip
RUN make -C /root/htslib-1.3.1
RUN curl -L https://github.com/samtools/samtools/archive/1.3.1.zip > /root/samtools.zip
RUN unzip /root/samtools.zip -d /root
RUN rm /root/samtools.zip
RUN make HTSDIR=/root/htslib-1.3.1 -C /root/samtools-1.3.1
RUN ln -s /root/samtools-1.3.1/samtools /usr/bin/samtools
RUN curl -L https://github.com/GregoryFaust/samblaster/archive/v.0.1.22.zip > /root/samblaster.zip
RUN unzip /root/samblaster.zip -d /root
RUN make -C /root/samblaster-v.0.1.22
RUN ln -s /root/samblaster-v.0.1.22 /usr/bin/samblaster
