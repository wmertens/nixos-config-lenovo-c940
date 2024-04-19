{ stdenv, fetchurl, which, m4, python
, protobuf, boost, zlib, curl, openssl, icu, jemalloc, libtool
, v8
}:

stdenv.mkDerivation rec {
  name = "rethinkdb-${version}";
  version = "2.2.4";

  src = fetchurl {
    url = "http://download.rethinkdb.com/dist/${name}.tgz";
    sha256 = "0zs07g7arrrvm85mqbkffyzgd255qawn64r6iqdws25lj1kq2qim";
  };

  postPatch = stdenv.lib.optionalString stdenv.isDarwin ''
    # Remove the dependence on bundled libraries
    sed -i '/must_fetch_list/ s/ v8//' configure

    # Don't use the default command line args
    rm configure.default

    # very meta
    substituteInPlace mk/support/pkg/re2.sh --replace "-i '''" "-i"
  '';

  preConfigure = ''
    export ALLOW_WARNINGS=1
    patchShebangs .
  '';

  configureFlags = stdenv.lib.optionals (!stdenv.isDarwin) [
    "--with-jemalloc"
    "--lib-path=${jemalloc}/lib"
  ]
  ++ stdenv.lib.optional (stdenv.isDarwin) "--dynamic=all";

  buildInputs = [ protobuf boost zlib curl openssl icu ]
    ++ stdenv.lib.optional (!stdenv.isDarwin) jemalloc
    ++ stdenv.lib.optional stdenv.isDarwin libtool
    ++ stdenv.lib.optional stdenv.isDarwin v8;

  nativeBuildInputs = [ which m4 python ];

  enableParallelBuilding = true;

  meta = {
    description = "An open-source distributed database built with love";
    longDescription = ''
      RethinkDB is built to store JSON documents, and scale to
      multiple machines with very little effort. It has a pleasant
      query language that supports really useful queries like table
      joins and group by, and is easy to setup and learn.
    '';
    homepage    = http://www.rethinkdb.com;
    license     = stdenv.lib.licenses.agpl3;
    platforms   = stdenv.lib.platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ thoughtpolice bluescreen303 ];
  };
}
