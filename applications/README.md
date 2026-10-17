# Application extensions disabled

This workstation deliberately installs **no optional application plugins**, editor
extensions, Yazi plugins/flavors, KiCad PCM components, Blender/FreeCAD
workbenches, Krita/GIMP add-ons, or external Whisper models. The automatic
installation manifest contains applications, not optional add-ons.

The *only* KWin script installed is **Polonium**, explicitly required for the
window-management configuration. The separately installed Nord colors, fonts
and icons are appearance assets, not application extensions.

No existing user-installed extensions are uninstalled or removed. If migrating
from an older bootstrap, check previously installed plug-ins in each app: this
repository will no longer install, configure or update them.
