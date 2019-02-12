FROM debian:stretch

RUN apt-get update && apt-get install -y libaio-dev bc git gcc make zlib1g-dev && git clone https://github.com/proact-de/fio-debian.git
WORKDIR /fio-debian
RUN ./configure && make && make install 

COPY measure-disk-random.sh .
CMD echo $(date +\%s),$(./measure-disk-random.sh)

# docker build . -f disk-random.Dockerfile
# docker run buildID