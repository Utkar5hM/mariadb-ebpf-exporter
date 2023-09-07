FROM ubuntu

WORKDIR /build

RUN apt-get update && apt-get install -y git sudo 

COPY ./builder/prepare-ubuntu.sh .

RUN ./prepare-ubuntu.sh

COPY . .

RUN git clone --recursive https://github.com/aquasecurity/libbpfgo

RUN go mod tidy
RUN make main-static

CMD [ "make", "run-static"] 