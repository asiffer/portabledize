FROM debian:12

RUN apt-get update -y
RUN apt-get install -y sudo e2fsprogs grep coreutils bc mount

COPY --chmod=755 portabledize.sh /bin/portabledize.sh

ENTRYPOINT ["/bin/portabledize.sh"]