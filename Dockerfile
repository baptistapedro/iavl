FROM ubuntu:20.04 as builder

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get install -y build-essential tzdata pkg-config \
	wget clang git

RUN wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

ADD . /iavl
WORKDIR /iavl

# package myfuzz
ADD harnesses/fuzz.go ./fuzzers/
WORKDIR ./fuzzers/
RUN go mod init myfuzz
RUN go install github.com/dvyukov/go-fuzz/go-fuzz@latest github.com/dvyukov/go-fuzz/go-fuzz-build@latest
ENV GO111MODULE=off
RUN go get github.com/cosmos/iavl
RUN go get github.com/dvyukov/go-fuzz/go-fuzz-dep
RUN /root/go/bin/go-fuzz-build -libfuzzer -o fuzz.a
RUN clang -fsanitize=fuzzer fuzz.a -o fuzz_deserialize_node

FROM ubuntu:20.04
COPY --from=builder /iavl/fuzzers/fuzz_deserialize_node /

ENTRYPOINT []
CMD ["/fuzz_deserialize_node"]
