# TIO / ROVA development base; no GPU, Gazebo or host device passthrough yet.
# Rebuild deliberately when updating the upstream Lyrical image and APT tools.
FROM ros:lyrical-ros-base

ARG ROS_UID=1000
ARG ROS_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        python3-colcon-core \
        python3-colcon-ros \
        python3-vcstool \
        ros-lyrical-ament-cmake \
        ros-lyrical-ros2launch \
        ros-lyrical-launch-ros \
        ros-lyrical-robot-state-publisher \
        ros-lyrical-joint-state-publisher \
        ros-lyrical-xacro \
    && command -v colcon \
    && command -v vcs \
    && bash -lc 'source /opt/ros/lyrical/setup.bash && command -v xacro && ros2 pkg prefix robot_state_publisher' \
    && rm -rf /var/lib/apt/lists/*

# Use the host's numeric UID and GID so workspace bind mounts stay writable
# without creating root-owned generated files on the host.
# Numeric USER avoids collisions with pre-existing base-image users/groups
# (some Ubuntu images already contain UID 1000). No root-owned workspace files.
RUN mkdir -p /home/rosdev \
    && printf '\n# ROS 2 Lyrical development environment\nsource /opt/ros/lyrical/setup.bash\n' > /home/rosdev/.bashrc \
    && chown -R "${ROS_UID}:${ROS_GID}" /home/rosdev

ENV HOME=/home/rosdev
USER ${ROS_UID}:${ROS_GID}
WORKDIR /workspaces
CMD ["sleep", "infinity"]
