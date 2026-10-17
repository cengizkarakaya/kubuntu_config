# Applications and extension inventory

Canonical machine-readable inventory is addons.tsv (tab-separated). Each add-on has one of:
- APT_ATTEMPT: a related system package is requested, NOT proof the app loaded it.
- VERIFY_IN_APP: feature may be bundled, but user must verify availability.
- USER_DOWNLOAD: large model or runtime must be selected explicitly in application.
- MANUAL: source, ABI, app-specific profile or license requires application-side installation.

Use only the built-in plugin managers where available:
Krita: Settings > Configure Krita > Python Plugin Manager / Settings > Dockers.
KiCad: Plugin and Content Manager (PCM), match KiCad major version.
FreeCAD: Tools > Addon Manager (match FreeCAD version).
Blender: Edit > Preferences > Get Extensions; use trusted repositories.
Joplin: Tools > Options > Plugins (the Flatpak profile is sandboxed).
Calibre: Preferences > Plugins > Get new plugins.
Thunderbird: Add-ons and Themes > Extensions.
GIMP: plugins compiled for 2.10 do not automatically work with GIMP 3.

No package install is silently reported as an application plugin install.
Do not copy user-specific databases, Joplin profile, GIMP profiles, Calibre
libraries, thumbnails, persistent tokens, password databases or encryption keys
into a public GitHub repository.

Sensible performance defaults:
- Blender/Kdenlive/Whisper: install models and datasets only when needed.
- Avoid Electron duplicate channels; Joplin / LocalSend / Zotero / OrcaSlicer
  are Flatpaks, while KDE/graphics apps prefer native apt binaries.
- Heavy add-on dependencies are NOT all installed by default.
- GIMP 3 BIMP/Resynthesizer/Liquid Rescale need a real compatible port.
- NVIDIA CUDA for Whisper is an opt-in task: never overwrite host drivers or
  install an arbitrary CUDA stack merely to activate transcription.

Optional code editor add-ons:
bash scripts/install-vscode-extensions.sh is deliberately not automatic;
run bash scripts/install-vscode-extensions.sh after checking manifest.
