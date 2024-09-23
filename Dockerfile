FROM osrf/ros:humble-desktop-full
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /home/humble
# Install dependencies
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
    curl wget git cmake libgl1-mesa-glx mesa-utils python3 python3-pip \
    ros-humble-ament-cmake-python libasio-dev && \
    rm -rf /var/lib/apt/lists/*

# Install RVIZ2
RUN apt-get install -y ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-rviz-* \
    ros-humble-cv-bridge \
    ros-humble-camera-calibration-parsers \
    && rm -rf /var/lib/apt/lists/*

# Install PYTHON dependencies
RUN pip3 install transformations
# Install YoloV8
RUN pip3 install opencv-python torch torchvision torchaudio ultralytics
# Install gazebo
RUN curl -sSL http://get.gazebosim.org | bash
RUN source /opt/ros/${ROS_DISTRO}/setup.bash
 
# Create workspace
RUN source /opt/ros/humble/setup.bash && \ 
    mkdir -p /home/humble/ros_ws/src && \
    cd /home/humble/ros_ws && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    colcon build --symlink-install
# Install Tello
RUN cd /home/humble/ros_ws/src && \
    git clone https://github.com/Los-UruBots-del-Norte/tello-ros2-gazebo.git
# Install Limo
RUN cd /home/humble/ros_ws/src && \
    git clone https://github.com/Los-UruBots-del-Norte/limo_ros2.git -b tello_support && \
    mkdir -p /home/humble/ros_ws/src/limo_ros2/limo_car/log && \
    mkdir -p /home/humble/ros_ws/src/limo_ros2/limo_car/src && \
    mkdir -p /home/humble/ros_ws/src/limo_ros2/limo_car/worlds

# BUILD
RUN source /home/humble/ros_ws/install/setup.bash && \
    cd /home/humble/ros_ws/ && \
    rosdep update --rosdistro=$ROS_DISTRO && \
    sudo apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    colcon build --parallel-workers 1 --symlink-install

RUN source /opt/ros/humble/setup.bash && \
    echo source /usr/share/gazebo/setup.bash >> ~/.bashrc && \
    echo source /home/humble/ros_ws/install/setup.bash >> ~/.bashrc && \
    export GAZEBO_MODEL_PATH=${PWD}/install/tello_gazebo/share/tello_gazebo/models

RUN source ~/.bashrc