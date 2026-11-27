# Conda environment recovery (opt-in)

Use a trusted existing Miniforge installation; this tool never installs Conda itself or changes base. No integration into bootstrap or sysup.

```bash
bash scripts/conda-envs.sh plan
bash scripts/conda-envs.sh list
bash scripts/conda-envs.sh export sage
bash scripts/conda-envs.sh export fenicsx
```

Exports are private under `~/.local/state/kubuntu-config/conda/` (or XDG_STATE_HOME). Each capture records history YAML, full YAML (may include pip dependencies), and a platform-specific explicit Conda package list. The two YAML exports omit the top-level prefix. Explicit exports are not pip lockfiles, and external packages may disappear upstream. Review channel URLs, credentials, variables, paths and pip entries locally. Never publish actual host exports, even after review. Include them in an independent encrypted backup.

Only minimal, general-purpose [environment manifests](environments/README.md) belong in this public repository. They are not exact host snapshots.

```bash
# Preview; apply only a reviewed, trusted manifest to a NEW environment.
bash scripts/conda-envs.sh restore fenicsx-test conda/environments/fenicsx.env.yml --kind yaml
bash scripts/conda-envs.sh restore fenicsx-test conda/environments/fenicsx.env.yml --kind yaml --apply
bash scripts/conda-envs.sh verify fenicsx-test --profile fenicsx
# Alternative: use your own recovered private same-platform explicit package list.
bash scripts/conda-envs.sh restore sage-test /path/to/private/sage.linux-64.explicit.txt --kind explicit
```

Restore refuses existing named environments and mismatched explicit platforms. Review YAML before apply, since pip and Conda packages can execute code. Verify imports/arithmetic on the actual host; this is not a complete simulation test. Retain working environments until a new environment passes tests. No automatic upgrades, deletion or environment overwrite. See [private lock guidance](locks/README.md).
