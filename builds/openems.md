# openEMS

Native openEMS and CSXCAD must be installed through a reviewed official
supported release procedure. No complete native build recipe is supplied.
Use an isolated Python environment compatible with the native libraries;
do not automatically reproduce development-derived packages or overlay
unverified Python bindings.

The scientific launcher detects AppCSXCAD and the Python environment after
installation. Verify both Python imports, the GUI and a small electromagnetic
simulation. Preserve exact native source revisions, build flags and Python
package lists in private recovery storage.
