# Private explicit Conda package snapshots

Actual host lockfiles are deliberately not tracked. Generate them with the [Conda recovery tool](../README.md) and protect the private state directory with an independent encrypted backup.

Explicit lists pin Conda artifact URLs for a specific platform; they do not guarantee future availability or constitute pip lockfiles. Inspect channel provenance, architecture and microarchitecture compatibility. Preserve the full YAML as a separate record. If pip and Conda report overlapping packages (for example rpy2), inspect package ownership and dependency compatibility in a new environment before applying pip requirements. Do not blindly overlay them.

An exact list comparison and an import smoke test are useful but do not establish numerical correctness, parallel execution or clean-machine recovery.
