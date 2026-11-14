# TIO provisional ROS 2 description — visual/kinematic prototype

This `ament_cmake` package supplies the first RViz2 model for **TIO**, the
small RC-sized precursor of ROVA. It is **not** a measured CAD model and
has no inertial dynamics, actuators, sensor drivers or Gazebo physics.

## Frames and geometry

Using ROS REP-103 axes: **x forward, y left, z up**.
`base_footprint` is on the ground; `base_link` is the chassis center.
The model includes four continuous wheel joints, a lowered front hood,
`camera_pan_joint` and `camera_tilt_joint` with a camera optical frame,
a low-profile roof `lidar_link`, and `imu_link`.

Tentative dimensions in `urdf/tio.urdf.xacro` (all metres):

| Xacro property | Draft value | Meaning |
| --- | ---: | --- |
| `body_length` | 0.38 | Body length |
| `body_width` | 0.21 | Body width, without tires |
| `body_height` | 0.095 | Main body box height |
| `body_center_height` | 0.11 | Body center above floor |
| `wheel_radius` | 0.06 | Tire radius |
| `wheel_width` | 0.038 | Tire width |
| `wheelbase` | 0.27 | Axle-to-axle length |
| `wheel_track` | 0.27 | Tire center-to-center width |

Replace the Xacro properties after actual measurements. Wheel steering,
drive layout and real camera/LiDAR mounts remain **undecided**. Wheel joints
are only visualization placeholders; this package does not simulate motion.

## One-time installation on the Kubuntu/ROS workstation

The ROS 2 Dockerfile now includes `ament_cmake`, `xacro`,
`robot_state_publisher`, `joint_state_publisher` and launch tools.
Rebuild the development image **once**, then refresh the optional RViz2
viewer to ensure compatible ROS packages and shared network/IPC.

From `~/kubuntu_config`:

```bash
git pull --ff-only
bash scripts/ros2-env.sh rviz-stop
bash scripts/ros2-env.sh up
bash scripts/ros2-env.sh check
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check

bash scripts/ros2-tio.sh plan
bash scripts/ros2-tio.sh init
bash scripts/ros2-tio.sh build
```

`init` copies this package into
`~/Workspaces/Robotics/tio_ws/src/tio_description` **without overwriting**
a project that already exists. All subsequent editing should happen in
that host directory. The checked-in template in `kubuntu_config` is
not a live link to the project; project source needs its own private
backup or repository.

The `build` step runs `colcon build --symlink-install` and validates
Xacro expansion **inside the actual Lyrical development container**.
Static CI can only check XML structure and Python syntax, not the
availability of ROS packages or successful ROS launch.

## Display in RViz2

**Alacritty terminal 1** — start TIO description and TF publishers:

```bash
cd ~/kubuntu_config
bash scripts/ros2-tio.sh run
```

**Alacritty terminal 2** — run RViz2:

```bash
cd ~/kubuntu_config
bash scripts/ros2-env.sh rviz
```

In RViz2, set **Global Options → Fixed Frame = `base_footprint`**.
Use **Add → RobotModel**, change `Description Source` to `Topic`,
and select `/robot_description` (use transient-local durability if
required). Add **TF** and **Grid** displays. The default
`joint_state_publisher` publishes zero positions for the wheel and
gimbal joints. RViz2 does not need real hardware or a simulator.

In another terminal, inspect node/topic names:

```bash
bash scripts/ros2-tio.sh status
```

Stop the publishers and RViz2 using Ctrl+C in their respective
terminals. The two project source directories remain on the host.

## Next stages

After comparing this visualization with the real TIO dimensions:
define true steering kinematics, accurate camera/LiDAR models, collision
geometry, inertial data, URDF validation and Gazebo physics. Do not
treat this descriptive prototype as an engineering drawing.
