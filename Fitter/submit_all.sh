#!/bin/bash

# ===================================================================
# submit_all.sh: 循环遍历 DM 列表，为每个 DM 提交一个独立的作业
# ===================================================================

# 定义你想要处理的 Decay Modes 列表
DECAY_MODES="DM0 DM1 DM10 DM11"

# 确保 condor_logs 目录存在
mkdir -p condor_logs

echo ">>> Starting submission process..."

# 循环遍历列表中的每一个 DM
for DM in ${DECAY_MODES}
do
    echo "--- Preparing and submitting job for: ${DM} ---"
    
    # 定义临时的 JDL 文件名
    TEMP_JDL_FILE="temp_${DM}.jdl"
    
    # 使用 sed 命令从模板创建临时的 JDL 文件
    # 's/DECAY_MODE_PLACEHOLDER/'${DM}'/g' 的意思是：
    # s = 替换, /旧内容/新内容/g = 全局替换
    sed 's/DECAY_MODE_PLACEHOLDER/'${DM}'/g' template.jdl > ${TEMP_JDL_FILE}
    
    echo "    Generated temporary JDL file: ${TEMP_JDL_FILE}"
    
    # 提交这个为单个 DM 定制的作业
    condor_submit ${TEMP_JDL_FILE}

    echo "    Job for ${DM} submitted."
    echo ""
done

echo ">>> All jobs have been submitted."