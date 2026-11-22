# Ubuntu 22.04 + CUDA 12.8 + ZED SDK 5.6 (official image) + ROS 2 Humble + zed-ros2-wrapper
FROM stereolabs/zed:5.6-devel-cuda12.8-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        locales curl git ca-certificates python3-pip \
    && locale-gen en_US.UTF-8 \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
         -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
         > /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-ros-base ros-dev-tools python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

# zed-ros2-wrapper
WORKDIR /opt/zed_ws
RUN git clone --depth 1 https://github.com/stereolabs/zed-ros2-wrapper.git src/zed-ros2-wrapper \
    && . /opt/ros/humble/setup.sh \
    && rosdep init && rosdep update \
    && apt-get update \
    && rosdep install --from-paths src --ignore-src -r -y \
    && rm -rf /var/lib/apt/lists/* \
    && colcon build --symlink-install --packages-skip zed_debug \
       --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc \
 && echo "source /opt/zed_ws/install/setup.bash" >> /root/.bashrc \
 && echo '[ -f /workspace/install/setup.bash ] && source /workspace/install/setup.bash' >> /root/.bashrc

WORKDIR /workspace
CMD ["bash"]

