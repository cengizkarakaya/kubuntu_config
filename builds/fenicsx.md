# FEniCSx

Use a separate Miniforge environment, with conda-forge packages fenics-dolfinx, mpich and pyvista. See the [minimal manifest](../conda/environments/fenicsx.env.yml) and [Conda recovery guide](../conda/README.md).

Keep exact installed versions, full YAML and explicit package lists privately. No source-build recipe is implied by a Conda installation. Verify DOLFINx and MPI imports, compare restored package lists if using explicit recovery, then test a small numerical problem and multi-process MPI execution. GPU acceleration and clean-host recovery need separate validation.
