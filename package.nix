{
  fetchFromGitHub,
  fetchurl,
  lib,
  rustPlatform,
  pkg-config,
  wayland,
  libpcap,
}:

let
  gameDataRev = "3c7d78ecdd432dd73d3fc8d6cb85033e07a69a5b";
  keysRev     = "44e55d019b2ea962bc36086ac6341cd85ddc8247";

  baseUrl     = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/${gameDataRev}/ExcelOutput";
  textMapUrl  = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/${gameDataRev}/TextMap";
  keysUrl     = "https://raw.githubusercontent.com/tamilpp25/Iridium-SR/${keysRev}/data/Keys.json";

  fetchResource = name: url: hash: fetchurl {
    inherit name url hash;
  };

  resources = {
    "AvatarConfig.json"             = fetchResource "AvatarConfig.json"             "${baseUrl}/AvatarConfig.json"              "sha256-g/iJU8Gvh5uwtBU8XGOSbAsOS8BlvD8pDTtVogq3MnM=";
    "AvatarConfigLD.json"           = fetchResource "AvatarConfigLD.json"           "${baseUrl}/AvatarConfigLD.json"            "sha256-vUbEta5WhV4YAX1lu1Vya3ey0jqztIexW4KV0mVfR0g=";
    "EquipmentConfig.json"          = fetchResource "EquipmentConfig.json"          "${baseUrl}/EquipmentConfig.json"           "sha256-FCUjHXPylTnjhVV/FvyYtuXAvMn2BAVHJB61jf5Le0I=";
    "RelicSetConfig.json"           = fetchResource "RelicSetConfig.json"           "${baseUrl}/RelicSetConfig.json"            "sha256-cDcuvoLADYyGQ29WQxlD4gHgrQsvGlJCcZIyY/+C0pk=";
    "ItemConfig.json"               = fetchResource "ItemConfig.json"               "${baseUrl}/ItemConfig.json"                "sha256-SIonwQWMUhxnJpZ3wI/+Xa++038x7nqjwlGDrW5XxzA=";
    "AvatarSkillTreeConfig.json"    = fetchResource "AvatarSkillTreeConfig.json"    "${baseUrl}/AvatarSkillTreeConfig.json"     "sha256-KsvZ+UJJ6EygN6x54vN1+nwFiPQmgEBSBcLt+ekPK58=";
    "AvatarSkillTreeConfigLD.json"  = fetchResource "AvatarSkillTreeConfigLD.json"  "${baseUrl}/AvatarSkillTreeConfigLD.json"   "sha256-iu0zoD5mzvuSF6ZTIM2czYxDyGDlpnF2ZjUBbO7Kxhg=";
    "MultiplePathAvatarConfig.json" = fetchResource "MultiplePathAvatarConfig.json" "${baseUrl}/MultiplePathAvatarConfig.json"  "sha256-ZCMIA8x/Y2pu95wYWpL2j9YVsLthjbNrvVlf5h9Vbfk=";
    "RelicConfig.json"              = fetchResource "RelicConfig.json"              "${baseUrl}/RelicConfig.json"               "sha256-gdCPW/El6cAw+KfKYqAPitbPMI+hKzOj5htw7BG9oz0=";
    "RelicMainAffixConfig.json"     = fetchResource "RelicMainAffixConfig.json"     "${baseUrl}/RelicMainAffixConfig.json"      "sha256-EtKxp0untMcrCOrtq9T+KAS/kJNWd2qBC4vLPJzW7Is=";
    "RelicSubAffixConfig.json"      = fetchResource "RelicSubAffixConfig.json"      "${baseUrl}/RelicSubAffixConfig.json"       "sha256-UuxusWfanSzXvOdpYNgDH3md4l9L7NfxX00lOg+Uiec=";
    "TextMapEN.json"                = fetchResource "TextMapEN.json"                "${textMapUrl}/TextMapEN.json"              "sha256-ckFvlFB83QdDzXTsexOD1aHlcnXVfSz7Jr30K+7BE8k=";
    "Keys.json"                     = fetchResource "Keys.json"                     "${keysUrl}"                                "sha256-1ZYQSdpm6V500xp+MIuX1bPTkinV7jxPJKpdvHGWr80=";
  };
in

rustPlatform.buildRustPackage rec {
  pname = "reliquary-archiver";
  version = "0.12.3";

  src = fetchFromGitHub {
    owner = "IceDynamix";
    repo = "reliquary-archiver";
    rev = "v${version}";
    hash = "sha256-jJUziIw6Nv+xP47HC72MQT4Z4JLZG/z0Eeu8akGNBIM=";
  };

  cargoHash = "sha256-b6mzgOD/GM7wJywOTuTch4r7/ALe+h4Kf1UYcFAomdA=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ wayland libpcap ];

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

  meta = with lib; {
    description = "Tool to create a relic export from network packets of a certain turn-based anime game";
    homepage = "https://github.com/IceDynamix/reliquary-archiver";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "reliquary-archiver";
    platforms = platforms.linux;
  };
}
