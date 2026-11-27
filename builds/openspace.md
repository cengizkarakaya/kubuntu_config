# OpenSpace

Use the official stable source release configured in
[the OpenSpace builder](../scripts/build-openspace.sh). The script defines
the APT requirements, CMake/Ninja flags, toolchain constraints and resume flow.
Use `--plan` and `--check-apt` before building.

If libmpv-dev needs a JACK provider, review the libjack-jackd2-dev solution;
never force unrelated package removals. See the documented GDAL compatibility
patch in the [astronomy guide](../docs/astronomy-simulators.md).

Verify the executable, actual OpenGL GUI and dataset operation. Record source
revision, exact compiler, dependency versions and build cache privately.
