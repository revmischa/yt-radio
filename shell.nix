{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") { }
}:

pkgs.mkShell {
  buildInputs = [

    pkgs.libsoup_3
    pkgs.libsoup

    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-ugly
    pkgs.gst_all_1.gst-plugins-bad
  ];

  shellHook = ''
    		bash stream.sh you
    	'';
}
