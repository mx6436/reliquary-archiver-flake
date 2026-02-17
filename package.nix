{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  wayland,
  libpcap,
}:

let
  sources = lib.importJSON ./sources.json;

  baseUrl = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/${sources.gameDataRev}";

  resources = lib.mapAttrs (
    name: hash:
    let
      # 根据文件名判断 URL 路径
      url =
        if name == "TextMapEN.json" then "${baseUrl}/TextMap/${name}" else "${baseUrl}/ExcelOutput/${name}";
    in
    fetchurl { inherit name url hash; }
  ) sources.resources;
in

rustPlatform.buildRustPackage {
  pname = "reliquary-archiver";
  version = "0.13.2";

  src = fetchFromGitHub {
    owner = "IceDynamix";
    repo = "reliquary-archiver";
    rev = "57fad800649523271a29f98b4c943f45830925a5";
    hash = "sha256-61jl8z43tGfnu65IyUTDo7m8PEke/OPVeJSFNitCngc=";
  };

  cargoHash = "sha256-YMWTpUd6Oi9dqBl8YwSzOsmmxlwmlEh902Z4pTD8NjQ=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    wayland
    libpcap
  ];

  postPatch = ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "ln -s ${file} ${name}") resources)}

    sed -i 's/HashMap/BTreeMap/g' build.rs

    sed -i '/fn download_as_json/,/^}/c\
    fn download_as_json<T: DeserializeOwned>(url: &str) -> T {\
        let filename = url.rsplit("/").next().unwrap();\
        let file = File::open(filename).expect(&format!("Failed to open local file: {}", filename));\
        ureq::serde_json::from_reader(file).expect(&format!("Failed to parse json from file: {}", filename))\
    }' build.rs
  '';

  passthru.updateScript = ./update.fish;

  meta = {
    description = "Tool to create a relic export from network packets of a certain turn-based anime game";
    homepage = "https://github.com/IceDynamix/reliquary-archiver";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "reliquary-archiver";
    platforms = lib.platforms.linux;
  };
}
