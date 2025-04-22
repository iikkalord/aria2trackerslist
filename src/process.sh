#!/bin/bash
# 参数化设计：-i 输入文件 -o 输出文件

# Initialize variables
input=""
output=""

while getopts "i:o:" opt; do
  case $opt in
    i) input=$OPTARG ;;
    o) output=$OPTARG ;;
    *) exit 1 ;;
  esac
done

# Check that input and output are set
if [[ -z "$input" || -z "$output" ]]; then
  echo "Error: Input or output file not specified."
  exit 1
fi

# 合并处理
cat "$input" | grep -Ev '^#|^$' | \
awk 'BEGIN{FS="/"} 
     # 过滤协议
     $0 ~ /^(udp|http|tcp|ws):/ && 
     # 排除高风险域名
     $3 !~ /\.(cn|ru|tk)$/ && 
     # 去重
     !seen[$0]++ {print}' | \
tr '\n' ',' | sed 's/,$//' > "$output"

# 结果校验
if [[ $(wc -c < "$output") -le 50 ]]; then
  echo "Error: Output file content is too small."
  exit 1
fi
