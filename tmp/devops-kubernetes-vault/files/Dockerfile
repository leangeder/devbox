FROM alpine:3.7

COPY vault-init /vault-init
RUN apk --no-cache add ca-certificates 

ENTRYPOINT ["/vault-init"]
