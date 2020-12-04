Currently this project depends on https://github.com/godot-extended-libraries/gltf for importing GLTF on the fly.

The GLTF importation is still slow (~5 seconds) but, compiling Godot
in release_debug tremendously improved the import speed.

The next steps will be :
* Load GLB files from the internet (We'll see about VRM later)
  * Provide a clean download interface, that provide the status of each
    download
* Parse "Mozilla Spoke" levels configuration files
  and generate a level from that
  * Generate global colliders from the created objects
    * Parse colliders information from a second custom-config file, for
      building objects.
* Setup a server with audioconferencing (WebRTC)
  * Use CoTURN for the TURN server
  * Implement some basic audio spatialization (AudioSource + linear
    distant volume fall-off)
* Put a decent mirror
* Find a way to use the GLB loader as plugin, just like the OpenXR
  plugin, and load it from the Steam version of Godot
* Use Godot with the OpenXR plugin, invoked through SteamVR and
  test the whole thing in VR
* Implement a button to change the current character mesh + skeleton
  by a downloaded GLB
* Implement IK to move around the arms of the characters according
  to the OpenXR input (only hands + head for now, since we don't
  have a Full Body Tracking hardware for now...)
* Call it 1.0... Alright, 0.1
