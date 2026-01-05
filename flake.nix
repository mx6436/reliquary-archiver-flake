{
  description = "IceDynamix/reliquary-archiver Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # 基础 URL 定义
        baseUrl = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/main/ExcelOutput";
        textMapUrl = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/main/TextMap";
        keysUrl = "https://raw.githubusercontent.com/tamilpp25/Iridium-SR/refs/heads/main/data/Keys.json";

        # 辅助函数：简化 fetchurl 写法
        fetchResource = name: url: hash: pkgs.fetchurl {
          inherit name url hash;
        };

        # 所有需要预取的文件列表
        resources = {
          "AvatarConfig.json"            = fetchResource "AvatarConfig.json" "${baseUrl}/AvatarConfig.json" "sha256-g/iJU8Gvh5uwtBU8XGOSbAsOS8BlvD8pDTtVogq3MnM=";
          "AvatarConfigLD.json"          = fetchResource "AvatarConfigLD.json" "${baseUrl}/AvatarConfigLD.json" "sha256-vUbEta5WhV4YAX1lu1Vya3ey0jqztIexW4KV0mVfR0g=";
          "EquipmentConfig.json"         = fetchResource "EquipmentConfig.json" "${baseUrl}/EquipmentConfig.json" "sha256-FCUjHXPylTnjhVV/FvyYtuXAvMn2BAVHJB61jf5Le0I=";
          "RelicSetConfig.json"          = fetchResource "RelicSetConfig.json" "${baseUrl}/RelicSetConfig.json" "sha256-cDcuvoLADYyGQ29WQxlD4gHgrQsvGlJCcZIyY/+C0pk=";
          "ItemConfig.json"              = fetchResource "ItemConfig.json" "${baseUrl}/ItemConfig.json" "sha256-aTR6WvFgnG12GpNOd5zctn+PrjoUWQppkVhZBVCrmjM=";
          "AvatarSkillTreeConfig.json"   = fetchResource "AvatarSkillTreeConfig.json" "${baseUrl}/AvatarSkillTreeConfig.json" "sha256-KsvZ+UJJ6EygN6x54vN1+nwFiPQmgEBSBcLt+ekPK58=";
          "AvatarSkillTreeConfigLD.json" = fetchResource "AvatarSkillTreeConfigLD.json" "${baseUrl}/AvatarSkillTreeConfigLD.json" "sha256-iu0zoD5mzvuSF6ZTIM2czYxDyGDlpnF2ZjUBbO7Kxhg=";
          "MultiplePathAvatarConfig.json"= fetchResource "MultiplePathAvatarConfig.json" "${baseUrl}/MultiplePathAvatarConfig.json" "sha256-ZCMIA8x/Y2pu95wYWpL2j9YVsLthjbNrvVlf5h9Vbfk=";
          "RelicConfig.json"             = fetchResource "RelicConfig.json" "${baseUrl}/RelicConfig.json" "sha256-gdCPW/El6cAw+KfKYqAPitbPMI+hKzOj5htw7BG9oz0=";
          "RelicMainAffixConfig.json"    = fetchResource "RelicMainAffixConfig.json" "${baseUrl}/RelicMainAffixConfig.json" "sha256-EtKxp0untMcrCOrtq9T+KAS/kJNWd2qBC4vLPJzW7Is=";
          "RelicSubAffixConfig.json"     = fetchResource "RelicSubAffixConfig.json" "${baseUrl}/RelicSubAffixConfig.json" "sha256-UuxusWfanSzXvOdpYNgDH3md4l9L7NfxX00lOg+Uiec=";
          "TextMapEN.json"               = fetchResource "TextMapEN.json" "${textMapUrl}/TextMapEN.json" "sha256-ckFvlFB83QdDzXTsexOD1aHlcnXVfSz7Jr30K+7BE8k=";
          "Keys.json"                    = fetchResource "Keys.json" "${keysUrl}" "sha256-1ZYQSdpm6V500xp+MIuX1bPTkinV7jxPJKpdvHGWr80=";
        };

      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "reliquary-archiver";
          version = "0.11.0";

          src = pkgs.fetchFromGitHub {
            owner = "IceDynamix";
            repo = "reliquary-archiver";
            rev = "v${version}";
            hash = "sha256-IJGRhxt/Hv5ubVKe9mbMShSxGmWOGgEZGrltCi1ZjIg=";
          };

          cargoHash = "sha256-yACwelMDPvgKrQrUqC5Qq2EkFYUpxSvFkgAi6ni+uCg=";

          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ wayland libpcap ];

          # 核心修复逻辑
          postPatch = ''
            # 1. 将所有预取的文件复制到源码根目录
            ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: file: "ln -s ${file} ${name}") resources)}

            # 强制将 HashMap 替换为 BTreeMap 以解决 output differs
            sed -i 's/HashMap/BTreeMap/g' build.rs

            # 2. 修改 build.rs 中的 download_as_json 函数
            # 原理：将原来联网下载的逻辑替换为直接读取当前目录下的文件
            # 我们利用 sed 将整个函数体替换掉
            sed -i '/fn download_as_json/,/^}/c\
            fn download_as_json<T: DeserializeOwned>(url: &str) -> T {\
                let filename = url.rsplit("/").next().unwrap();\
                let file = File::open(filename).expect(&format!("Failed to open local file: {}", filename));\
                ureq::serde_json::from_reader(file).expect(&format!("Failed to parse json from file: {}", filename))\
            }' build.rs
          '';

          postInstall = ''
            echo "------------------------------------------------------------"
            echo "WARNING: Capabilities cannot be set inside the Nix sandbox."
            echo "To run this tool without root, please run the following commands"
            echo "after building:"
            echo ""
            echo "  cp $out/bin/reliquary-archiver ./reliquary-archiver"
            echo "  chmod +w ./reliquary-archiver"
            echo "  sudo setcap cap_net_raw+ep ./reliquary-archiver"
            echo "------------------------------------------------------------"
          '';

          meta = with pkgs.lib; {
            description = "tool to create a relic export from network packets of a certain turn-based anime game";
            homepage = "https://github.com/IceDynamix/reliquary-archiver";
            license = licenses.mit;
            maintainers = [ ];
          };
        };
        
        # 可选：提供开发环境
        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          packages = with pkgs; [ rustc cargo rustfmt clippy ];
          shellHook = ''
            echo "Development shell active."
            echo "Remember to run: sudo setcap cap_net_raw+ep target/debug/reliquary-archiver"
          '';
        };
      }
    )
    # 2. 新增：合并 NixOS 模块定义 (注意这里是在 eachDefaultSystem 括号外面)
    // {
      nixosModules.default = { config, lib, pkgs, ... }: 
        let
          cfg = config.programs.reliquary-archiver;
          # 假设你的 packages 输出里有名为 default 的包
          # 注意：在 module 中获取特定架构的包需要一点技巧，这里简化处理
          # 更好的方式是让 module 接受 pkgs 参数并从 self.packages.${pkgs.system} 获取
          pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default; 
        in {
          options.programs.reliquary-archiver = {
            enable = lib.mkEnableOption "reliquary-archiver service";
          };

          config = lib.mkIf cfg.enable {
            # 安装包到系统
            environment.systemPackages = [ pkg ];

            # 关键：通过 security.wrappers 自动生成带权限的包装器
            security.wrappers.reliquary-archiver = {
              source = "${pkg}/bin/reliquary-archiver";
              capabilities = "cap_net_raw+ep";
              owner = "root";
              group = "root";
            };
          };
        };
    };
}
