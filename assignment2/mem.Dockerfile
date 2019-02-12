FROM debian:stretch

RUN apt-get update && apt-get install -y gcc
COPY memsweep.c .
COPY measure-mem.sh .

CMD echo $(date +\%s),$(./measure-mem.sh)

# docker build . -f mem.Dockerfile
# docker run buildID