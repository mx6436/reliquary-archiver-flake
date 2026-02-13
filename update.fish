#!/usr/bin/env -S nix shell nixpkgs#fish nixpkgs#nix nixpkgs#curl nixpkgs#jq --command fish

set game_data_repo "Dimbreath/turnbasedgamedata"
set keys_repo "tamilpp25/Iridium-SR"

echo "--- Fetching latest revisions ---"
set game_data_rev (curl -s "https://gitlab.com/api/v4/projects/"(string replace '/' '%2F' $game_data_repo)"/repository/branches/main" | jq -r .commit.id)
set keys_rev (curl -s "https://api.github.com/repos/$keys_repo/commits/main" | jq -r .sha)

# 定义 Excel 文件列表
set excel_files \
    AvatarConfig.json AvatarConfigLD.json EquipmentConfig.json \
    RelicSetConfig.json ItemConfig.json AvatarSkillTreeConfig.json \
    AvatarSkillTreeConfigLD.json MultiplePathAvatarConfig.json \
    RelicConfig.json RelicMainAffixConfig.json RelicSubAffixConfig.json

# 初始化 JSON 基础结构
set source_data (jq -n \
    --arg g_rev "$game_data_rev" \
    --arg k_rev "$keys_rev" \
    '{gameDataRev: $g_rev, keysRev: $k_rev, resources: {}}')

echo "--- Calculating hashes ---"

# 处理常规文件
for file in $excel_files
    set -l url "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/$game_data_rev/ExcelOutput/$file"
    echo "Processing: $file"
    set -l hash (nix-prefetch-url "$url" --type sha256 2>/dev/null | xargs nix hash convert --to sri --hash-algo sha256)
    set source_data (echo $source_data | jq --arg f "$file" --arg h "$hash" '.resources += {($f): $h}')
end

# 处理 TextMapEN.json
echo "Processing: TextMapEN.json"
set -l tm_url "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/$game_data_rev/TextMap/TextMapEN.json"
set -l tm_hash (nix-prefetch-url "$tm_url" --type sha256 2>/dev/null | xargs nix hash convert --to sri --hash-algo sha256)
set source_data (echo $source_data | jq --arg h "$tm_hash" '.resources += {"TextMapEN.json": $h}')

# 处理 Keys.json
echo "Processing: Keys.json"
set -l k_url "https://raw.githubusercontent.com/$keys_repo/$keys_rev/data/Keys.json"
set -l k_hash (nix-prefetch-url "$k_url" --type sha256 2>/dev/null | xargs nix hash convert --to sri --hash-algo sha256)
set source_data (echo $source_data | jq --arg h "$k_hash" '.resources += {"Keys.json": $h}')

# 写入文件
echo $source_data | jq . > sources.json
echo "--- Done! sources.json has been updated ---"

# 生成一个简短的版本摘要
set short_g (string sub -l 7 $game_data_rev)
set short_k (string sub -l 7 $keys_rev)

echo "--- Suggested Commit Message ---"
echo "chore: update resources (gameData@$short_g, keys@$short_k)"
