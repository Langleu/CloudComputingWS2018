FROM debian:stretch

RUN apt-get update && apt-get install -y gcc bc
COPY fork.c .
COPY measure-fork.sh .
RUN gcc -O -o fork fork.c -lm

CMD echo $(date +\%s),$(./measure-fork.sh)

# docker build . -f fork.Dockerfile
# docker run buildID