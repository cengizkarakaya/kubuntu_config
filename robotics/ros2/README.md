# ROS 2 Lyrical — Docker Compose development environment

For Kubuntu 26.10 + Docker Engine with the verified `ros:lyrical-ros-base`
image (Ubuntu 26.04). The core CLI Publisher/Subscriber test was completed
successfully on 14 Nov 2026. This repository stores a Compose/Dockerfile
development environment; the **custom image still needs building and testing**
on the actual Kubuntu machine.

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
  The tested pull on 14 Nov 2026 reported
  `sha256:c69a7a39142b0a19c8cc5e80a35e9087e2ae46080dfa0a59961ff72287fdc5f6`.

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
path are determined by the helper, not hard-coded to `/home/cengiz` or
accidentally resolved to `/root` by sudo.

### Interactive shell invocation fixed (14 November 2026)

The initial `bash scripts/ros2-env.sh shell` command used `bash
--interactive`, but Bash accepts `-i` (not that long option). The helper now
uses `docker compose exec dev bash -i`; the offline CI mocks the Compose call
and verifies the correct arguments. The existing Docker image and container
do not need to be rebuilt or restarted. Run `git pull --ff-only` and then
`bash scripts/ros2-env.sh shell`.
