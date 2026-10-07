{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libGL,
  fontconfig,
  ffmpeg,
  leptonica,
  libgbm,
  libxkbcommon,
  pipewire,
  tesseract,
  wayland,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wlr-utils";
  version = "1.11.1";

  src = fetchFromGitHub {
    owner = "sjourdois";
    repo = "wlr-utils";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AVlZpmUA73UcZjLALHKEz+AhGP6MwqmHgAdamENosTE=";
  };

  cargoHash = "sha256-NaBFMTTlgEkiVtWbHQCuNUmmCPLZc7088AsTwbzSG5o=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    ffmpeg
    leptonica
    libgbm
    libxkbcommon
    pipewire
    tesseract
    wayland
  ];

  postInstall = ''
    install -Dm644 -t $out/share/wlr-utils/themes docs/themes/*.toml
    install -Dm644 -t $out/share/doc/wlr-utils docs/config.toml
    install -Dm644 -t $out/lib/systemd/user \
      crates/wlr-chooser/contrib/wlr-overlayd.service \
      crates/wlr-draw/contrib/wlr-draw.service
    substituteInPlace $out/lib/systemd/user/wlr-overlayd.service \
      --replace-fail "/usr/bin/env wlr-overlayd" "$out/bin/wlr-overlayd"
    substituteInPlace $out/lib/systemd/user/wlr-draw.service \
      --replace-fail "/usr/bin/env wlr-draw" "$out/bin/wlr-draw"
  '';

  # libEGL and libfontconfig are dlopen'd at runtime.
  postFixup = ''
    for program in $out/bin/wlr-*; do
      patchelf \
        --add-needed "${libGL}/lib/libEGL.so.1" \
        --add-needed "${lib.getLib fontconfig}/lib/libfontconfig.so.1" \
        $program
    done
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=stable" ];
  };

  __structuredAttrs = true;

  meta = {
    description = "Native Wayland desktop tools for wlroots";
    homepage = "https://github.com/sjourdois/wlr-utils";
    changelog = "https://github.com/sjourdois/wlr-utils/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license =
      with lib.licenses;
      OR [
        asl20
        mit
      ];
    maintainers = with lib.maintainers; [ hexa ];
    platforms = lib.platforms.linux;
  };
})
