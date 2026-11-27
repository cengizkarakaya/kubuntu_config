# SageMath

Use a separate Miniforge environment, with conda-forge packages sage and jupyterlab. See the [minimal manifest](../conda/environments/sage.env.yml) and [Conda recovery guide](../conda/README.md).

Keep actual versions and exports privately. No source-build recipe is implied. An explicit package list does not include pip dependencies; inspect overlap and ownership before installing pip packages. Verify arithmetic, dependencies and any required notebook functionality in a new environment before replacing the original.
