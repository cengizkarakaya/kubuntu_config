# Compatibility and verification matrix

Target support is not equivalent to a completed installation or recovery test.

| Component | Kubuntu 26.04 LTS | Kubuntu 26.10 |
| --- | --- | --- |
| Core bootstrap and KDE | Intended baseline; clean install unverified | Intended target; clean install unverified |
| Optional science profile | On-host validation required | On-host validation required |
| ROS 2 and RViz2 | Container and GUI tests required | Container and GUI tests required |
| NetAlertX | Runtime and ingress tests required | Runtime and ingress tests required |
| Conda recovery | New environment and numerical tests required | New environment and numerical tests required |
| Personal Restic recovery | Independent backup and staged restore required | Independent backup and staged restore required |
| Inventory and launcher portability | Private capture and restore tests required | Private capture and restore tests required |
| Astronomy source builds | Clean build and GUI tests required | Clean build and GUI tests required |

CI uses GitHub-hosted Ubuntu runners, **not** an interactive Kubuntu installation.
It tests syntax, static invariants, mocked operations and selected upstream
software installation. It cannot establish physical workstation correctness.

Record exact Git SHA, date, OS/kernel/Plasma, command results and manual
observations privately. Do not publish raw or host-specific acceptance records.
Use the [release policy](release-policy.md) for verified labels. A future
Kubuntu release is unverified until tested.
