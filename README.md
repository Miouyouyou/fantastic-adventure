Currently this project use this version of Godot :

https://github.com/Miouyouyou/godot/tree/myy_vsekai

This version include the runtime GLTF importer and VOIP
with Opus codec support.

The GLTF importation is still slow but, compiling Godot
in release_debug tremendously improved the import speed.  
The level import should be put inside a second thread again, though.

The next steps will be :
* [x] Load GLB files from the internet (We'll see about VRM later)
  * [ ] Provide a clean download interface, that provide the status of each
    download
* [x] Parse "Mozilla Spoke" levels configuration files
  and generate a level from that (Only the objects for now)
  * [x] Generate global colliders from the created objects (Only mesh colliders, which are freaking heavy...)
    * [ ] Parse colliders information from a second custom-config file, for
      building objects.
* [x] Transmit and hear voices
  * [ ] Compatibility with WebRTC (will be seriously delayed for the moment)
  * [ ] Implement some basic audio spatialization (AudioSource + linear
    distant volume fall-off)
* [ ] Put a decent mirror
* [ ] Find a way to use the GLB loader as plugin, just like the OpenXR
  plugin, and load it from the Steam version of Godot
* [ ] Use Godot with the OpenXR plugin, invoked through SteamVR and
  test the whole thing in VR
* [ ] Implement a button to change the current character mesh + skeleton
  by a downloaded GLB
* [ ] Implement IK to move around the arms of the characters according
  to the OpenXR input (only hands + head for now, since we don't
  have a Full Body Tracking hardware for now...)
* [ ] Call it 1.0... Alright, 0.1
