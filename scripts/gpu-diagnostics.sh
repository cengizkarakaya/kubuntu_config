#!/usr/bin/env bash
set -uo pipefail
# Read-only NVIDIA/KDE diagnostics. Does not install or alter any driver.
echo '=== GPU diagnostics (read-only) ==='
printf 'Session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Kernel: '; uname -r
if command -v nvidia-smi >/dev/null 2>&1; then
  echo 'NVIDIA device and driver:'
  nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used --format=csv,noheader || echo '[WARN] nvidia-smi failed'
else echo '[WARN] NVIDIA utilities absent; inspect Ubuntu Additional Drivers'; fi
if command -v vulkaninfo >/dev/null 2>&1; then
  echo 'Vulkan device/driver summary:'
  vulkaninfo --summary 2>&1 | head -n 60
else echo '[WARN] vulkan-tools absent'; fi
if command -v glxinfo >/dev/null 2>&1; then
  echo 'OpenGL/GLX summary (may use XWayland):'
  glxinfo -B 2>&1 | head -n 32
else echo '[WARN] mesa-utils absent'; fi
if command -v ffmpeg >/dev/null 2>&1; then
  echo 'FFmpeg build-time NVENC encoder availability (NOT a live encode test):'
  ffmpeg -hide_banner -encoders 2>/dev/null | grep -E '(_nvenc|_vaapi)' || echo '[INFO] No hardware video encoder listed'
fi
echo 'These checks do not prove Blender OptiX, CUDA, monitor stability, NVENC operation or Wayland KWin effects.'
