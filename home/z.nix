{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  name = "z-${version}";

  version = "1.9";

  src = fetchurl {
    url = "https://github.com/rupa/z/archive/v${version}.tar.gz";
    sha256 = "19vhvvhj5bg5pgfsrhcwpmcac8z63vn0ijm4ghlh43kpcm7hx1p2";
  };

  phases = "unpackPhase installPhase";

  installPhase = ''
    mkdir -p $out/{libexec,share/man/man1}
    cp z.sh $out/libexec
    cp z.1 $out/share/man/man1
  '';

  # TODO profile.d

  meta = with lib; {
    description = "Jump between directories in bash. `source libexec/z.sh` to make it work";
    homepage = https://github.com/rupa/z;
    maintainers = with maintainers; [ wmertens ];
    platforms = with platforms; linux ++ darwin;
  };
}
