# Celestia

Use the official stable source release configured in
[the Celestia builder](../scripts/build-celestia-stable.sh). Preview with
`--plan` before building; do not use experimental releases automatically.

The script defines the APT build requirements, Autotools handling and configured
installation prefix. Review the actual upstream release and source digest.
Verify the installed executable and a real GUI launch. Record exact source
revision, compiler, flags and dependency versions in private recovery storage.
See [astronomy guide](../docs/astronomy-simulators.md).
