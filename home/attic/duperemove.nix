{ stdenv, fetchFromGitHub, libgcrypt, pkgconfig, glib
, linuxHeaders ? stdenv.cc.libc.linuxHeaders, sqlite }:

stdenv.mkDerivation rec {
  pname = "duperemove";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "markfasheh";
    repo = "duperemove";
    rev = "fd2011333c1a55173669d9440655b045af0a96a6";
    sha256 = "sha256-PCvlD3hJbZSi1bCOh1WAcfCNDOAnYSv0j6dhviCRBVw=";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ libgcrypt glib linuxHeaders sqlite ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = with pkgs.lib; {
    description =
      "A simple tool for finding duplicated extents and submitting them for deduplication";
    homepage = "https://github.com/markfasheh/duperemove";
    license = licenses.gpl2;
    maintainers = with maintainers; [ bluescreen303 thoughtpolice ];
    platforms = platforms.linux;
  };
}
