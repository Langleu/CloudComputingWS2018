FROM debian:stretch

RUN apt-get update && apt-get install -y gcc
COPY linpack.c .
COPY measure-cpu.sh .

CMD echo $(date +\%s),$(./measure-cpu.sh)

# docker build . -f cpu.Dockerfile
# docker run buildID