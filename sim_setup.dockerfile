FROM nvcr.io/nvidia/isaac-sim:6.0.0

ENV ACCEPT_EULA=Y PRIVACY_CONSENT=Y DEBIAN_FRONTEND=noninteractive
USER root
WORKDIR /isaac-sim

# ROS 2 Humble
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl git ca-certificates \
    && locale-gen en_US.UTF-8 \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
         -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
         > /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends ros-humble-ros-base ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

# zed-isaac-sim
RUN mkdir -p extsUser && cd extsUser \
    && git clone --depth 1 https://github.com/stereolabs/zed-isaac-sim.git \
    && cd zed-isaac-sim && ./build.sh

# Python libs (leave Isaac's numpy alone)
RUN ./python.sh -m pip install --no-cache-dir matplotlib \
 && ./python.sh -m pip install --no-cache-dir --no-deps opencv-python-headless

EXPOSE 49100/tcp 47998/udp

ENTRYPOINT ["/bin/bash", "-c", "source /opt/ros/humble/setup.bash && \
  ./runheadless.sh --ext-folder /isaac-sim/extsUser/zed-isaac-sim/exts --enable sl.sensor.camera \"$@\"", "--"]
