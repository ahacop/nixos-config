{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "nirisnap";
  version = "1.1.0-unstable-2026-09-17";

  src = pkgs.fetchFromGitHub {
    owner = "sergionoodles";
    repo = "nirisnap";
    rev = "d1b8f4677db7a67fb2c0348f2b02c0892f320764";
    hash = "sha256-pkgYfxuJz9lYDVvL9PaYkgNOpR6Rn35txBLDwlboEo8=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    pkg-config
    wayland-scanner
    qt6Packages.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    qt6.qtbase
    qt6.qtwayland
    kdePackages.layer-shell-qt
    wayland
  ];

  cmakeFlags = [ "-DBUILD_TESTING=OFF" ];

  # nirisnap runs these as child processes and looks them up on PATH:
  # wl-copy/wl-paste for the clipboard, tesseract for OCR, notify-send for
  # the capture-finished notification. It also runs `niri msg`, which comes
  # from the session's own niri on PATH.
  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath (
        with pkgs;
        [
          wl-clipboard
          libnotify
          (tesseract5.override { enableLanguages = [ "eng" ]; })
        ]
      )
    }"
  ];

  meta = {
    description = "Native Wayland screenshot and annotation overlay for niri";
    homepage = "https://github.com/sergionoodles/nirisnap";
    license = lib.licenses.mit;
    mainProgram = "nirisnap";
  };
}
