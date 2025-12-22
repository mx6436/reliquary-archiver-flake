#!/bin/sh
# 将此脚本保存为 get_hashes.sh 并运行，或者直接复制粘贴到终端

BASE="https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/main/ExcelOutput"
TEXT="https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/main/TextMap"
KEYS="https://raw.githubusercontent.com/tamilpp25/Iridium-SR/refs/heads/main/data/Keys.json"

# 定义文件列表
FILES="
AvatarConfig.json
AvatarConfigLD.json
EquipmentConfig.json
RelicSetConfig.json
ItemConfig.json
AvatarSkillTreeConfig.json
AvatarSkillTreeConfigLD.json
MultiplePathAvatarConfig.json
RelicConfig.json
RelicMainAffixConfig.json
RelicSubAffixConfig.json
"

echo "正在计算 Hash，请稍候..."
echo "----------------------------------------"

for f in $FILES; do
  # 下载并计算 Hash
  HASH=$(nix-prefetch-url "$BASE/$f" --name "$f" 2>/dev/null)
  # 转换为 SRI 格式 (sha256-xxx)
  SRI=$(nix hash convert --to sri --hash-algo sha256 "$HASH")
  echo "\"$f\" = \"$SRI\";"
done

# 处理 TextMap
HASH=$(nix-prefetch-url "$TEXT/TextMapEN.json" --name "TextMapEN.json" 2>/dev/null)
SRI=$(nix hash convert --to sri --hash-algo sha256 "$HASH")
echo "\"TextMapEN.json\" = \"$SRI\";"

# 处理 Keys
HASH=$(nix-prefetch-url "$KEYS" --name "Keys.json" 2>/dev/null)
SRI=$(nix hash convert --to sri --hash-algo sha256 "$HASH")
echo "\"Keys.json\" = \"$SRI\";"

echo "----------------------------------------"