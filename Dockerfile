FROM alpine:latest
RUN apk add --no-cache nftables
CMD ["sleep", "infinity"]