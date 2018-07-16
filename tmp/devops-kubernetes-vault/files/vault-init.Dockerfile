FROM golang:1.10-alpine3.7

WORKDIR /go/src/app

RUN apk --no-cache add git && \
    git clone https://github.com/kelseyhightower/vault-init.git . && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o vault-init -v .

FROM alpine:3.7 

COPY --from=0 /go/src/app/vault-init /vault-init
RUN apk --no-cache add ca-certificates

ENTRYPOINT ["/vault-init"]
