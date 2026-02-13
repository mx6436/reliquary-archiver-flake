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
  gameDataRev = "cc5572bcc1305735fba96b91202f998ccc3a2a21";
  keysRev = "44e55d019b2ea962bc36086ac6341cd85ddc8247";

  baseUrl = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/${gameDataRev}/ExcelOutput";
  textMapUrl = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/${gameDataRev}/TextMap";
  keysUrl = "https://raw.githubusercontent.com/tamilpp25/Iridium-SR/${keysRev}/data";

  fetchResource =
    name: url: hash:
    fetchurl {
      inherit name url hash;
    };

  resources = {
    "AvatarConfig.json" =
      fetchResource "AvatarConfig.json" "${baseUrl}/AvatarConfig.json"
        "sha256-xGyfZ/w3T4RQOFK9GSfd0L4BQFfkrxxHN5HCNMRi7b0=";
    "AvatarConfigLD.json" =
      fetchResource "AvatarConfigLD.json" "${baseUrl}/AvatarConfigLD.json"
        "sha256-vUbEta5WhV4YAX1lu1Vya3ey0jqztIexW4KV0mVfR0g=";
    "EquipmentConfig.json" =
      fetchResource "EquipmentConfig.json" "${baseUrl}/EquipmentConfig.json"
        "sha256-9RFdFJGePRCFUMDusEOnHSIa6sy7LRt9+vYDg8O61hU=";
    "RelicSetConfig.json" =
      fetchResource "RelicSetConfig.json" "${baseUrl}/RelicSetConfig.json"
        "sha256-8Q7LhIyMo3moyT6kwYvvv8HjwVJoAz+7sTMXpr9KJB8=";
    "ItemConfig.json" =
      fetchResource "ItemConfig.json" "${baseUrl}/ItemConfig.json"
        "sha256-9aXaKY8B6Uyca0gaWRt4f8FYfZtL2iIe8O3KUnReS5I=";
    "AvatarSkillTreeConfig.json" =
      fetchResource "AvatarSkillTreeConfig.json" "${baseUrl}/AvatarSkillTreeConfig.json"
        "sha256-BN+GpoXiQ9P608uSk2vGZ8+LZQhrW94pY2/saTITzsQ=";
    "AvatarSkillTreeConfigLD.json" =
      fetchResource "AvatarSkillTreeConfigLD.json" "${baseUrl}/AvatarSkillTreeConfigLD.json"
        "sha256-9DJBB3ayCeWy55uciLpRe2LxtJio9cEUod2UG6colYQ=";
    "MultiplePathAvatarConfig.json" =
      fetchResource "MultiplePathAvatarConfig.json" "${baseUrl}/MultiplePathAvatarConfig.json"
        "sha256-ZCMIA8x/Y2pu95wYWpL2j9YVsLthjbNrvVlf5h9Vbfk=";
    "RelicConfig.json" =
      fetchResource "RelicConfig.json" "${baseUrl}/RelicConfig.json"
        "sha256-QpVp6f/EOA0/eR7AeaXdr6WLLt6B6Xf77IJTrAPaRtU=";
    "RelicMainAffixConfig.json" =
      fetchResource "RelicMainAffixConfig.json" "${baseUrl}/RelicMainAffixConfig.json"
        "sha256-EtKxp0untMcrCOrtq9T+KAS/kJNWd2qBC4vLPJzW7Is=";
    "RelicSubAffixConfig.json" =
      fetchResource "RelicSubAffixConfig.json" "${baseUrl}/RelicSubAffixConfig.json"
        "sha256-UuxusWfanSzXvOdpYNgDH3md4l9L7NfxX00lOg+Uiec=";
    "TextMapEN.json" =
      fetchResource "TextMapEN.json" "${textMapUrl}/TextMapEN.json"
        "sha256-E9aw/4NUnqvNEx3jPNqpaW4BvPwcAp8Dlfka5VhM2J0=";
    "Keys.json" =
      fetchResource "Keys.json" "${keysUrl}/Keys.json"
        "sha256-1ZYQSdpm6V500xp+MIuX1bPTkinV7jxPJKpdvHGWr80=";
  };
in

rustPlatform.buildRustPackage {
  pname = "reliquary-archiver";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "IceDynamix";
    repo = "reliquary-archiver";
    rev = "dd5b89f126ed32ed32379030aac003299b7409b1";
    hash = "sha256-Va4ngAq/iQ2+1D7roFwe7GyQzLx7VRDcpBoCDCPmWJk=";
  };

  cargoHash = "sha256-AX3+hOwMVrM63mMbDixNSmuumJYm7HOFzJXcCWmshzY=";

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

  meta = {
    description = "Tool to create a relic export from network packets of a certain turn-based anime game";
    homepage = "https://github.com/IceDynamix/reliquary-archiver";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "reliquary-archiver";
    platforms = lib.platforms.linux;
  };
}
