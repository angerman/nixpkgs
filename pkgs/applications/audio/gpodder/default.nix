{ stdenv, fetchFromGitHub, python3, python3Packages, intltool
, glibcLocales, gnome3, gtk3, wrapGAppsHook
, ipodSupport ? false, libgpod
}:

python3Packages.buildPythonApplication rec {
  name = "gpodder-${version}";
  version = "3.10.0";

  format = "other";

  src = fetchFromGitHub {
    owner = "gpodder";
    repo = "gpodder";
    rev = version;
    sha256 = "0f3m1kcj641xiwsxan66k81lvslkl3aziakn5z17y4mmdci79jv0";
  };

  postPatch = with stdenv.lib; ''
    sed -i -re 's,^( *gpodder_dir *= *).*,\1"'"$out"'",' bin/gpodder
  '';

  nativeBuildInputs = [
    intltool
    python3Packages.wrapPython
    wrapGAppsHook
    glibcLocales
  ];

  buildInputs = [
    python3
  ];

  checkInputs = with python3Packages; [
    coverage minimock
  ];

  doCheck = true;

  propagatedBuildInputs = with python3Packages; [
    feedparser
    dbus-python
    mygpoclient
    pygobject3
    eyeD3
    podcastparser
    html5lib
    gtk3
  ] ++ stdenv.lib.optional ipodSupport libgpod;

  makeFlags = [
    "PREFIX=$(out)"
    "share/applications/gpodder-url-handler.desktop"
    "share/applications/gpodder.desktop"
    "share/dbus-1/services/org.gpodder.service"
  ];

  preBuild = ''
    export LC_ALL="en_US.UTF-8"
  '';

  installCheckPhase = ''
    LC_ALL=C PYTHONPATH=./src:$PYTHONPATH python3 -m gpodder.unittests
  '';

  meta = with stdenv.lib; {
    description = "A podcatcher written in python";
    longDescription = ''
      gPodder downloads and manages free audio and video content (podcasts)
      for you. Listen directly on your computer or on your mobile devices.
    '';
    homepage = http://gpodder.org/;
    license = licenses.gpl3;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ skeidel mic92 ];
  };
}
