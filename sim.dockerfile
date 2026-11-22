# Isaac Sim 6.0 (Ubuntu 24.04) + zed-isaac-sim. No ROS: the ZED extension streams straight to the ZED SDK.
FROM nvcr.io/nvidia/isaac-sim:6.2.0.1

ENV ACCEPT_EULA=Y PRIVACY_CONSENT=Y DEBIAN_FRONTEND=noninteractive
USER root
WORKDIR /isaac-sim

RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates wget tar build-essential python3 libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p extsUser
#RUN cd /isaac-sim/extsUser \
#    && git clone --depth 1 https://github.com/stereolabs/zed-isaac-sim.git \
#    && cd zed-isaac-sim && ./build.sh

RUN ./python.sh -m pip install --no-cache-dir matplotlib \
 && ./python.sh -m pip install --no-cache-dir --no-deps opencv-python-headless

EXPOSE 49100/tcp 47998/udp
ENTRYPOINT ["/bin/bash", "-c", "./runheadless.sh --ext-folder /isaac-sim/extsUser/zed-isaac-sim/exts --enable sl.sensor.camera \"$@\"", "--"]

