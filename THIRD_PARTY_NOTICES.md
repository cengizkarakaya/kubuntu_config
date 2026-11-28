# Third-party notices and license scope

The root [MIT License](LICENSE) applies to original Kubuntu_Config code and
documentation to the extent its contributors have rights to grant that license.
It does not relicense third-party material, erase upstream notices, or establish
a license for material of uncertain provenance. The following exceptions and
dependencies are reviewed separately.

## Material in the repository

- **Arch_Config imports and adaptations:** [reference commit
  56c882a](https://github.com/cengizkarakaya/Arch_Config/tree/56c882afbd385a905b419193aa72520a688d56ea).
  No license file was found at that reference. The parity configurations in
  `dotfiles/` and adapted `scripts/yazi-rg` are excluded from the new project
  MIT grant pending confirmation of authorship, permissions and any upstream
  notices. A public repository or common account owner alone is not proof
  that all imported material can be relicensed. See [parity audit](docs/arch-parity.md).
  Preserve the existing files until provenance is reviewed; exclusion does
  not itself establish a right to redistribute them.
- **Nord palette:** the project uses Nord colors in its theme and configuration.
  [Nord upstream](https://github.com/nordtheme/nord) provides an MIT license;
  its notice is preserved verbatim in [LICENSES/Nord-MIT.txt](LICENSES/Nord-MIT.txt).
  This notice does not establish the provenance of every imported dotfile.
- **Compatibility patches:** the build helpers contain small source-matching
  fragments for Celestia and OpenSpace. Their underlying upstream source
  remains subject to its original license. A local patch does not relicense
  an upstream program.

## External software resolved or downloaded by installers

The repository contains dependency declarations and installation helpers,
not the full third-party programs, plugin trees, font archives or icon packs.
Upstream licenses continue to apply to those downloads and any redistributed
or modified copies. This list is an initial provenance review, not a complete
software bill of materials or legal clearance for every dependency.

| Component | Source and license evidence |
| --- | --- |
| Nordic GTK | [Pinned license](https://github.com/EliverLara/Nordic/blob/be5bda37ba01139650e34238336e58e065d2f406/LICENSE): GNU GPL version 3 text. |
| Nordzy icons | [Pinned COPYING](https://github.com/MolassesLover/Nordzy-icon/blob/829c47bda534d3c9f3c7d46c73a6fe9d946eca41/COPYING): GNU GPL version 3 text; the installer makes a local dark variant. |
| Nerd Fonts / FiraCode | [Upstream licensing](https://github.com/ryanoasis/nerd-fonts/blob/master/LICENSE): multiple licenses, including SIL OFL 1.1 for applicable fonts and MIT for original tooling. Review the actual release and font notices before redistribution. |
| Yazi plugins | [Pinned license](https://github.com/yazi-rs/plugins/blob/4dc7f1b/LICENSE): MIT, copyright yazi-rs. |
| Yazi Nord flavor | Manifest references `AdithyanA2005/nord` at `34970be`; its license/source could not be retrieved during this review. Do not assert a license or redistribute a vendored copy without verification. |
| Celestia | [COPYING at 1.6.4](https://github.com/CelestiaProject/Celestia/blob/1.6.4/COPYING): GNU GPL version 2 text. |
| OpenSpace | [License at v0.22.1](https://github.com/OpenSpace/OpenSpace/blob/releases/v0.22.1/LICENSE.md): MIT-style license. |

APT, Flatpak, Conda, Docker images and other official release downloads each
retain their own licensing terms, including proprietary terms where applicable.
No root project license grants rights in these packages. Verify actual release
licenses and any source/notice obligations before bundling or distributing them.

## Review policy

Do not add copied or vendored material without checking the source revision,
applicable license and attribution requirements. Preserve original notices and
document exceptions. Keep the unresolved Arch parity and Nord flavor provenance
items open until verified; do not describe this repository as fully
license-audited while they remain unresolved.
