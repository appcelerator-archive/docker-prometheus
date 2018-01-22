FROM appcelerator/alpine:3.7.0

ENV PROMETHEUS_VERSION 2.1.0

ENV GOLANG_VERSION 1.9.2
ENV GOLANG_SRC_URL https://storage.googleapis.com/golang/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SRC_SHA256 665f184bf8ac89986cfd5a4460736976f60b57df6b320ad71ad4cef53bb143dc

RUN apk update && apk upgrade && \
    apk --virtual build-deps add build-base openssl git gcc musl musl-dev make binutils patch go && \
    echo "Installing Go" && \
    export GOROOT_BOOTSTRAP="$(go env GOROOT)" && \
    wget -q "$GOLANG_SRC_URL" -O golang.tar.gz && \
    echo "$GOLANG_SRC_SHA256  golang.tar.gz" | sha256sum -c - && \
    tar -C /usr/local -xzf golang.tar.gz && \
    rm golang.tar.gz && \
    cd /usr/local/go/src && \
    ./make.bash && \
    export GOPATH=/go && \
    export PATH=/usr/local/go/bin:$PATH && \
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
    apk del build-deps && cd / && rm -rf /var/cache/apk/* /usr/local/go $GOPATH

COPY config/prometheus.yml  /etc/prometheus/prometheus.yml

EXPOSE     9090
VOLUME     [ "/prometheus" ]
WORKDIR    /prometheus
ENTRYPOINT [ "/sbin/tini", "--", "/bin/prometheus" ]
CMD        [ "-config.file=/etc/prometheus/prometheus.yml", \
             "-storage.local.path=/prometheus", \
             "-web.console.libraries=/usr/share/prometheus/console_libraries", \
             "-web.console.templates=/usr/share/prometheus/consoles" ]
