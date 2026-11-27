# ROS 2 Lyrical — Docker Compose development environment

For Kubuntu 26.10 and Docker Engine using the upstream `ros:lyrical-ros-base` image. Validate the custom Compose image and publisher/subscriber test on each target host.

## Preparation and first start

From the `kubuntu_config` clone, as the normal desktop user:

```bash
# Optional: stop and remove only the disposable Phase-2 test container.
sudo docker stop ros2-lyrical-test
sudo docker rm ros2-lyrical-test

git pull --ff-only
docker compose version
bash scripts/ros2-env.sh plan      # validates config, no changes
bash scripts/ros2-env.sh up        # creates host workspaces, builds and starts
bash scripts/ros2-env.sh check     # verifies distro, colcon, permissions
bash scripts/ros2-env.sh shell     # enters non-root interactive Bash
```

Omit the `docker stop`/`docker rm` commands above if you previously
removed the test container. They do **not** remove the ROS image.

Host workspace structure (deliberately **outside this Git repository**):

```text
~/Workspaces/Robotics/
├── tio_ws/src/
└── rova_ws/src/
```

Container paths: `/workspaces/tio_ws`, `/workspaces/rova_ws`.
The Compose wrapper uses the host user's UID/GID when building so generated
files retain their expected host ownership. It uses a numeric container user
rather than creating a fixed UID 1000 account that could collide with Ubuntu
base-image users.

The base image provides ROS 2 Lyrical. Its ROS repository packages already
provide `python3-colcon-core` (the `colcon` command),
`python3-colcon-ros` and `python3-vcstool` (the `vcs` command). The
Dockerfile retains these **non-conflicting** package names and adds/ensures
`cmake`, `git` and compiler tools. No extra third-party APT sources, GPU tools, GUI apps or Rust toolchains
are installed at this stage. Inside `bash scripts/ros2-env.sh shell`,
`/home/rosdev/.bashrc` sources `/opt/ros/lyrical/setup.bash`.
For noninteractive `docker compose exec` commands, explicitly source it.

Example inside the container:

```bash
printf 'ROS distro: %s\n' "$ROS_DISTRO"
cd /workspaces/tio_ws
colcon list
```

There are intentionally no ROS packages yet, so `colcon list` may return
nothing. RViz2 and Gazebo are subsequent, separate development stages.

Stop the container without deleting source code or the custom image:

```bash
bash scripts/ros2-env.sh down
```

## Networking and security

- Compose default isolated bridge network; ROS discovery restricted to
  `LOCALHOST` and domain 42. This supports ROS nodes **inside one container**
  and deliberately does not support a Raspberry Pi or a separate host yet.
- No Docker socket inside the container; no Docker group membership,
  `privileged: true`, host networking, USB passthrough, NVIDIA,
  Wayland/X11 sockets or external published ports.
- The helper requests `sudo` for rootful Docker daemon operations, while
  the **workload** itself runs with the host UID/GID in the container.
- Bind mounts are writable. Only use trusted project code in these directories.
- The Dockerfile references an upstream image tag and unpinned APT packages;
  record the resolved image digest for byte-for-byte reproducibility.

## Troubleshooting

**Resolved 14 November 2026:** the first custom Dockerfile incorrectly
requested Ubuntu's `colcon` and `vcstool` packages in addition to ROS
image packages. During `apt-get install`, `vcstool` tried to overwrite
`/usr/bin/vcs` already owned by `python3-vcstool` (exit 100). The
Dockerfile now uses only `python3-colcon-core`, `python3-colcon-ros` and
`python3-vcstool`, and verifies both `colcon` and `vcs` executables.
This failure occurred inside a disposable Docker build layer, not in Kubuntu's
host APT database. After pulling the correction, retry `bash scripts/ros2-env.sh
up` normally. Do **not** use `dpkg --force-overwrite` or
`docker builder prune -a` to bypass this conflict.

If `up` fails, inspect its full output. Likely causes include package
availability in the image's Ubuntu 26.04 repositories, insufficient disk
space or container networking/DNS. Do not use `--privileged`, delete dpkg
locks, or add unsupported PPAs as a workaround.

`bash scripts/ros2-env.sh plan` does not require sudo and is the first
check after pulling changes. `ROS_UID`, `ROS_GID` and the host workspace
path are determined by the helper, not hard-coded to a particular host login or
accidentally resolved to `/root` by sudo.

### Interactive shell invocation fixed (14 November 2026)

The initial `bash scripts/ros2-env.sh shell` command used `bash
--interactive`, but Bash accepts `-i` (not that long option). The helper now
uses `docker compose exec dev bash -i`; the offline CI mocks the Compose call
and verifies the correct arguments. The existing Docker image and container
do not need to be rebuilt or restarted. Run `git pull --ff-only` and then
`bash scripts/ros2-env.sh shell`.

## Optional RViz2 + NVIDIA GPU viewer (Stage 4)

Verify the NVIDIA GPU runtime using `nvidia-smi` in a Docker test container. Validate OpenGL and RViz2 independently.

RViz2 uses a separate Compose override and image. The working `dev`
container still uses the original base Compose configuration unless the
GUI is explicitly started.

From the normal KDE Plasma Wayland desktop session:

```bash
command -v xauth  # if missing: sudo apt install --no-install-recommends xauth
echo "DISPLAY=${DISPLAY:-unset}; XAUTHORITY=${XAUTHORITY:-unset}"
bash scripts/ros2-env.sh rviz-plan
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check
bash scripts/ros2-env.sh rviz
# Later, to stop only the viewer:
bash scripts/ros2-env.sh rviz-stop
```

The opt-in `compose.rviz.yaml` creates an `rviz` service with the
`ros-lyrical-rviz2` application, `glxinfo`, XWayland and NVIDIA GPU support.
The NVIDIA runtime is requested with
`NVIDIA_DRIVER_CAPABILITIES=graphics,display,utility,compute`.
`QT_QPA_PLATFORM=xcb` routes Qt through XWayland.

The helper requires the real local `DISPLAY` and an existing Xauthority
cookie (see `xauth nlist "$DISPLAY"`). It creates a temporary
`$XDG_RUNTIME_DIR/kubuntu-ros2/rviz.xauth` file with mode 0600,
bind-mounted read-only at `/tmp/.Xauthority` inside the GUI container.
**Never publish this cookie or its contents.** This procedure does not
use a permissive X server access policy. If the cookie is unavailable,
the helper fails and prints an explanation; it will not bypass access checks.

To ensure ROS nodes can communicate between containers while keeping DDS
discovery local, the GUI service shares `dev`'s network and IPC namespaces:
`network_mode: service:dev`, `ipc: service:dev`; `dev` uses
`ipc: shareable` when the overlay is active. **The first rviz-up may
recreate dev** to enable this. All TIO/ROVA workspaces remain bind-mounted
from the host. The viewer does not receive host networking, Docker socket,
USB devices or general privileged mode.

GPU and X11 access still increase the viewer's privileges: run only
trusted applications. The `rviz-check` command requires an NVIDIA
OpenGL renderer from `glxinfo -B`, not just `nvidia-smi`.
If it reports `llvmpipe` or `could not open display`, investigate
Xauthority/GLX rather than installing another graphics driver blindly.

**Unverified until host test:** apt availability of
`ros-lyrical-rviz2` during the viewer image build, GUI rendering,
OpenGL vendor and RViz2 stability.

## Persist RViz2 preferences and configurations (Stage 4 follow-up)

RViz2 may report a missing `/home/rosdev/.rviz2/persistent_settings` on its
first run. Check whether the settings file is created after closing RViz2.
Verify hardware OpenGL and direct rendering on the target host independently.

To survive container recreation, the opt-in GUI service now binds:

```text
Host:      ~/Workspaces/Robotics/rviz2-config/
Container: /home/rosdev/.rviz2/
```

On the first `bash scripts/ros2-env.sh rviz-up` after pulling this change,
the helper creates the host configuration directory. If the old RViz2
container is still present and no host `persistent_settings` exists, it
copies that single file from the old container before Compose recreates it.
**It never overwrites an existing host file**. On import failure it stops
rather than silently losing old settings.

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/ros2-env.sh rviz-plan
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check
bash scripts/ros2-env.sh rviz
ls -la ~/Workspaces/Robotics/rviz2-config
```

The host folder is outside the public `kubuntu_config` repository and will
not be pushed to GitHub. **A bind mount persists data through container
recreation, but not disk failure or formatting.** Include the folder in a
private filesystem backup before reinstalling. For project-specific RViz
layouts, also export named `.rviz` configuration files into a separately
version-controlled robot project after checking for private paths.

## TIO robot description starter (Stage 5)

The first four-wheel TIO URDF/Xacro is supplied separately under
`robotics/tio_description/`. It is a visual/kinematic draft with **tentative
dimensions**, not a measured CAD model, and includes a lowered camera hood,
two-axis camera gimbal, partly embedded LiDAR, four wheels and TF frames.

The `dev` Dockerfile now adds optional description/launch dependencies:
`ros-lyrical-ament-cmake`, `ros-lyrical-ros2launch`,
`ros-lyrical-launch-ros`, `ros-lyrical-robot-state-publisher`,
`ros-lyrical-joint-state-publisher`, and `ros-lyrical-xacro`.
These packages are inside Docker only; do not change host APT packages.
After pulling, rebuild `dev` and refresh the separate RViz image:

```bash
bash scripts/ros2-env.sh rviz-stop
bash scripts/ros2-env.sh up
bash scripts/ros2-env.sh check
bash scripts/ros2-env.sh rviz-up
bash scripts/ros2-env.sh rviz-check
bash scripts/ros2-tio.sh plan
bash scripts/ros2-tio.sh init
bash scripts/ros2-tio.sh build
```

Then run `bash scripts/ros2-tio.sh run` in one terminal and
`bash scripts/ros2-env.sh rviz` in another. In RViz2 choose Fixed Frame
`base_footprint`, add RobotModel and set description topic
`/robot_description`. See `robotics/tio_description/README.md`.

The TIO source is copied **only once** into
`~/Workspaces/Robotics/tio_ws/src/tio_description`. The helper
refuses to overwrite an existing customized project. Build/Xacro/GUI
validation must be performed on the actual ROS machine; static CI
cannot prove these packages are available in the installed image.

## rqt + PlotJuggler and KDE Application Launcher (Stage 6)

The optional RViz2 Docker image now bundles
`ros-lyrical-rqt`, `ros-lyrical-rqt-graph`,
`ros-lyrical-rqt-console`, `ros-lyrical-rqt-image-view`,
`ros-lyrical-rqt-topic`, `ros-lyrical-rqt-plot`, and
`ros-lyrical-plotjuggler` (PlotJuggler 3).
The `ros-lyrical-plotjuggler-ros` package is **unavailable** in the ROS
Lyrical binary repo as of 14 November 2026 (upstream issue #119).
PlotJuggler runs without its ROS subscriber plugin; choose `rqt Plot`
for ROS topic time-series until a compatible plugin is separately built.
The existing headless ROS 2 `dev` image stays unchanged.
The GUI helper supports `rqt`, `rqt-graph`, `rqt-console`,
`rqt-image`, and `plotjuggler` subcommands.

Preferences for Qt/rqt/PlotJuggler are persisted at
`~/Workspaces/Robotics/ros-gui-config/` through the GUI Compose
overlay. The `rviz-up` helper creates the directory before container
startup. The existing `rviz2-config` bind remains intact.

The workstation already passed NVidia/OpenGL/RViz2 GUI tests; these
**new packages have not yet been built or launched on that machine**.
After pulling, rerun `rviz-stop`, `rviz-up`, `rviz-check`.
Install KDE Application Launcher shortcuts **only as the normal desktop user**
using `python3 scripts/install-ros2-launchers.py --check` and
`--install`. The installer preserves existing KMenuEdit Robotics/Webots,
backs up the menu and never clobbers customized entries.

See [docs/ros2-gui-launchers.md](../../docs/ros2-gui-launchers.md).
