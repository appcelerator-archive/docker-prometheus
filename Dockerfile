FROM appcelerator/alpine:3.6.0

ENV PROMETHEUS_VERSION 1.8.0

RUN apk update && apk upgrade && \
    apk --virtual build-deps add build-base openssl git gcc musl musl-dev make binutils patch go && \
    export GOPATH=/go && \
    go version && \
    mkdir -p /go/src/github.com/prometheus && cd /go/src/github.com/prometheus && \
    git clone https://github.com/prometheus/prometheus.git -b v${PROMETHEUS_VERSION} && \
    cd prometheus && \
    make build && \
    cp prometheus /bin/prometheus && \
    cp promtool /bin/promtool && \
    cp -pr console_libraries/ /usr/share/prometheus/ && \
    cp -pr consoles/ /usr/share/prometheus/ && \
    mkdir /etc/prometheus && \
    ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
    apk del build-deps && cd / && rm -rf /var/cache/apk/* $GOPATH

COPY config/prometheus.yml  /etc/prometheus/prometheus.yml

EXPOSE     9090
VOLUME     [ "/prometheus" ]
WORKDIR    /prometheus
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "-config.file=/etc/prometheus/prometheus.yml", \
             "-storage.local.path=/prometheus", \
             "-web.console.libraries=/usr/share/prometheus/console_libraries", \
             "-web.console.templates=/usr/share/prometheus/consoles" ]
