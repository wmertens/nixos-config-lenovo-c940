{ stdenv, fetchgit, zlib, sparsehash, cmake, pkgconfig, git, CoreServices }:

stdenv.mkDerivation rec {
  version = "1.6.9";
  name = "afsctool-${version}";

  src = fetchgit {
    url = "https://github.com/RJVB/afsctool.git";
    rev = "refs/tags/${version}";
    sha256 = "1fv6iqz91y5ini5yrbig5aa2jnrhzblc6y41v3h2mzh2nv26ffyl";
    fetchSubmodules = false;
  };

  buildInputs = [ CoreServices zlib sparsehash cmake pkgconfig git ];

  enableParallelBuilding = true;

  buildPhase = ''
    cmake -Wno-dev .
    make
  '';

  installPhase = ''
      	mkdir -p $out/bin
    	cp afsctool $out/bin
      '';

  meta = with pkgs.lib; {
    homepage = "https://github.com/RJVB/afsctool";
    description = "Tool for managing filesystem compression on HFS+ and APFS";
    license = licenses.gpl3;
    maintainers = with maintainers; [ wmertens ];
  };
}
