# Local speech-to-text with NVIDIA Parakeet V3 through onnx-asr. The
# derivation follows upstream's nix/package.nix, which supports only
# Whisper.cpp on x86_64-linux. This copy swaps pywhispercpp for onnx-asr
# in the Python environment, and the postPatch lets the Nix install mode
# accept the onnx-asr backend. The model downloads from Hugging Face into
# ~/.cache/huggingface on the first start of the service.
{ pkgs, lib }:
let
  python = pkgs.python313.withPackages (
    ps: with ps; [
      sounddevice
      numpy
      soxr
      soundfile
      evdev
      pyperclip
      pyudev
      pulsectl
      rich
      jsonschema
      dbus-python
      pygobject3
      pycairo
      onnx-asr
      huggingface-hub
    ]
  );
  # Fallbacks only: they must match the host's running systemd and audio
  # server, so the wrapper appends them after the session PATH.
  hostTools = lib.makeBinPath (
    with pkgs;
    [
      systemd
      pulseaudio
    ]
  );
in
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hyprwhspr";
  version = "1.49.2";

  src = pkgs.fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rSWO9gANWp0rflzJamdPVqB2zYouh2mp0qzezIAfEw4=";
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
    wrapGAppsHook4
    gobject-introspection
  ];

  # GTK 4 and the layer-shell library draw the recording overlay.
  buildInputs = with pkgs; [
    gtk4
    gtk4-layer-shell
    glib
  ];

  postPatch = ''
    substituteInPlace lib/src/installation.py \
      --replace-fail "normalize_backend(backend) in ('cpu', 'pywhispercpp')" \
                     "normalize_backend(backend) == 'onnx-asr'"
  '';

  dontBuild = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/hyprwhspr" "$out/bin"
    cp -r bin lib config share LICENSE requirements*.txt "$out/lib/hyprwhspr/"
    echo '${builtins.toJSON { inherit (finalAttrs) version; }}' > "$out/lib/hyprwhspr/release.json"

    # The noctwhspr bar widget runs <root>/config/hyprland/hyprwhspr-tray.sh
    # and looks for <root> in /usr/lib/hyprwhspr by default. This copy of the
    # plugin points <root> at a directory that holds the wrapped tray script,
    # which carries the environment that the bare script does not have.
    mkdir -p "$out/lib/hyprwhspr-widget/config/hyprland" "$out/share/noctalia/plugins"
    ln -s "$out/bin/hyprwhspr-tray" "$out/lib/hyprwhspr-widget/config/hyprland/hyprwhspr-tray.sh"
    cp -r config/noctalia/plugin "$out/share/noctalia/plugins/noctwhspr"
    substituteInPlace \
      "$out/share/noctalia/plugins/noctwhspr/plugin.toml" \
      "$out/share/noctalia/plugins/noctwhspr/widget.luau" \
      --replace-fail '"/usr/lib/hyprwhspr"' "\"$out/lib/hyprwhspr-widget\""
    runHook postInstall
  '';

  preFixup = ''
    makeWrapper "$out/lib/hyprwhspr/bin/hyprwhspr" "$out/bin/hyprwhspr" \
      "''${gappsWrapperArgs[@]}" \
      --set HYPRWHSPR_INSTALL_METHOD nix \
      --set HYPRWHSPR_NIX_ROOT "$out/lib/hyprwhspr" \
      --set HYPRWHSPR_BACKEND_ENV ${python} \
      --unset HYPRWHSPR_GENERATION \
      --unset PYTHONPATH \
      --prefix PATH : ${
        lib.makeBinPath (
          with pkgs;
          [
            python
            bash
            coreutils
            procps
            wl-clipboard
            wtype
            libnotify
            glib
            alsa-utils
            gawk
            gnugrep
            gnused
          ]
        )
      } \
      --suffix PATH : ${hostTools}
    makeWrapper "$out/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh" "$out/bin/hyprwhspr-tray" \
      --set HYPRWHSPR_ROOT "$out/lib/hyprwhspr" \
      --set HYPRWHSPR_INSTALL_METHOD nix \
      --set HYPRWHSPR_BACKEND_ENV ${python} \
      --prefix PATH : "$out/bin:${
        lib.makeBinPath (
          with pkgs;
          [
            python
            bash
            coreutils
            procps
            libnotify
            glib
            alsa-utils
            gawk
            gnugrep
            gnused
          ]
        )
      }" \
      --suffix PATH : ${hostTools}
  '';

  meta = {
    description = "Linux desktop speech-to-text, set up here for Parakeet V3 on the CPU";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = lib.licenses.mit;
    mainProgram = "hyprwhspr";
    platforms = lib.platforms.linux;
  };
})
