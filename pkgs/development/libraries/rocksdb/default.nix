{ stdenv
, fetchFromGitHub
, fixDarwinDylibNames
, hostPlatform, lib
, which, perl, cmake

# Optional Arguments
, snappy ? null, google-gflags ? null, zlib ? null, bzip2 ? null, lz4 ? null
, numactl ? null

# Malloc implementation
, jemalloc ? null, gperftools ? null

, enableLite ? false
, windows
}:

let
  malloc = if jemalloc != null then jemalloc else gperftools;
  tools = [ "sst_dump" "ldb" "rocksdb_dump" "rocksdb_undump" "blob_dump" ];
in
stdenv.mkDerivation rec {
  name = "rocksdb-${version}";
  version = "5.11.3";

  outputs = [ "dev" "out" "static" "bin" ];

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "rocksdb";
    rev = "v${version}";
    sha256 = "15x2r7aib1xinwcchl32wghs8g96k4q5xgv6z97mxgp35475x01p";
  };

  nativeBuildInputs = [ which perl snappy google-gflags ];
  buildInputs = [ zlib bzip2 malloc fixDarwinDylibNames ] # lz4 ];
             ++ lib.optional (hostPlatform.libc == "msvcrt") [ windows.mingw_w64_pthreads windows.mingw_w64_headers ];
  crossAttrs = {
    nativeBuildInputs = [ which perl snappy google-gflags cmake ];
  };

#  cmakeFlags = "-DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ ";
  cmakeFlags = "-DCMAKE_SYSTEM_NAME=Windows -DCMAKE_CXX_FLAGS=-std=c++11 -DCMAKE_CXX_FLAGS=-pthread";
  buildFlags = "rocksdb VERBOSE=1 -j1";

  # postPatch = ''
  #   # Hack to fix typos
  #   sed -i 's,#inlcude,#include,g' build_tools/build_detect_platform
  # '';

  # # Environment vars used for building certain configurations
  PORTABLE = "1";
  USE_SSE = "1";
  #CMAKE_CXX_FLAGS = "-std=c++11 -pthread -pthreads";
  # JEMALLOC_LIB = stdenv.lib.optionalString (malloc == jemalloc) "-ljemalloc";

  # LIBNAME = "librocksdb${stdenv.lib.optionalString enableLite "_lite"}";
  # ${if enableLite then "CXXFLAGS" else null} = "-DROCKSDB_LITE=1";

  # buildAndInstallFlags = [
  #   "USE_RTTI=1"
  #   "DEBUG_LEVEL=0"
  #   "DISABLE_WARNING_AS_ERROR=1"
  # ];

  # buildFlags = buildAndInstallFlags ++ [
  #   "shared_lib"
  #   "static_lib"
  # ] ++ tools ;

  # installFlags = buildAndInstallFlags ++ [
  #   "INSTALL_PATH=\${out}"
  #   "install-shared"
  #   "install-static"
  # ];

  # postInstall = ''
  #   # Might eventually remove this when we are confident in the build process
  #   echo "BUILD CONFIGURATION FOR SANITY CHECKING"
  #   cat make_config.mk
  #   mkdir -pv $static/lib/
  #   mv -vi $out/lib/${LIBNAME}.a $static/lib/

  #   install -d ''${!outputBin}/bin
  #   install -D ${stdenv.lib.concatStringsSep " " tools} ''${!outputBin}/bin
  # '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    homepage = http://rocksdb.org;
    description = "A library that provides an embeddable, persistent key-value store for fast storage";
    license = licenses.bsd3;
    platforms = platforms.x86_64;
    maintainers = with maintainers; [ adev wkennington ];
  };
}
