# General-purpose environment manifests

| Environment | Minimal manifest | Purpose |
| --- | --- | --- |
| FEniCSx | [fenicsx.env.yml](fenicsx.env.yml) | DOLFINx, MPICH and PyVista |
| SageMath | [sage.env.yml](sage.env.yml) | SageMath and JupyterLab |

These are curated, unpinned package requests. The solver selects compatible builds. They are not full exports, platform locks or statements of the installed versions on any machine. Keep actual exports outside Git. Review platform compatibility and test a new environment before replacing a working one.

See [Conda recovery](../README.md) for explicit opt-in procedures.
