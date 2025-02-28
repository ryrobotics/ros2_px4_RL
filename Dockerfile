# https://github.com/PX4/PX4-containers
FROM px4io/px4-dev-ros-melodic:2021-09-08

# setup environment
ENV ROS_DISTRO dashing

# setup ros2 keys
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# setup sources.list
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt install tmux nano htop -y

# install bootstrap tools
RUN apt-get update \
	&& apt-get install --quiet -y \
		python3-colcon-common-extensions \
		python3-colcon-mixin \
		python3-vcstool \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# install ros2 desktop, added "gazebo-ros-pkgs for collision detection
RUN apt-get install --quiet --no-install-recommends -y \
		ros-$ROS_DISTRO-desktop \
		ros-$ROS_DISTRO-launch-testing-ament-cmake \
		ros-$ROS_DISTRO-ros2bag \
		ros-$ROS_DISTRO-rosidl-generator-dds-idl \
        ros-$ROS_DISTRO-gazebo-ros-pkgs \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Install Python 3 packages needed for testing
RUN pip3 install --upgrade \
		argcomplete \
		flake8 \
		flake8-blind-except \
		flake8-builtins \
		flake8-class-newline \
		flake8-comprehensions \
		flake8-deprecated \
		flake8-docstrings \
		flake8-import-order \
		flake8-quotes \
		pytest-repeat \
		pytest-rerunfailures
		
RUN pip3 install torch pandas

# bootstrap rosdep
RUN rosdep update

# setup colcon mixin and metadata
RUN colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml \
	&& colcon mixin update \
	&& colcon metadata add default https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml \
	&& colcon metadata update
	
WORKDIR /src
# Repository forked in order to avoid by default "missing RC" failsafe when in offboard mode
RUN git clone --branch rcl_except_4 https://github.com/carlo98/PX4-Autopilot.git

WORKDIR /src/PX4-Autopilot
RUN HEADLESS=1 make px4_sitl_default gazebo
RUN rm Tools/sitl_gazebo/models/iris/iris.sdf.jinja
RUN mv iris.sdf.jinja Tools/sitl_gazebo/models/iris/
RUN rm Tools/sitl_gazebo/worlds/iris_irlock.world
RUN mv iris_irlock.world Tools/sitl_gazebo/worlds/
RUN rm Tools/sitl_gazebo/models/iris_irlock/iris_irlock.sdf
RUN mv iris_irlock.sdf Tools/sitl_gazebo/models/iris_irlock/
RUN HEADLESS=1 make px4_sitl_rtps gazebo

WORKDIR /
