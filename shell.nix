{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") { }
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.libsoup
    pkgs.glib-networking

    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-ugly
    pkgs.gst_all_1.gst-plugins-bad
  ];

  shellHook = ''
        		export LD_LIBRARY_PATH="${pkgs.libsoup.out}/lib:${pkgs.glib-networking.out}/lib"
    				export GIO_EXTRA_MODULES="${pkgs.glib-networking.out}/lib/gio/modules"
        		bash stream.sh you
        					'';
}
