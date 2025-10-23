#!/bin/bash

# ===================================================================
# run_dm_job.sh: 在 Condor 节点上为单个 DM 执行 createinputs
# ===================================================================

# --- 从 Condor JDL 文件接收参数 ---
# $1: Decay Mode (例如 DM0, DM1)
# $2: 你的 CMSSW release 的绝对路径
# $3: 你想存放最终 ROOT 文件的 EOS 目录的绝对路径
DECAY_MODE=$1
CMSSW_PATH=$2
EOS_OUTPUT_DIR=$3

echo "========================================="
echo "--- Condor Job Starting ---"
echo "Job running on host: $(hostname)"
echo "OS release: $(cat /etc/redhat-release)"
echo "-----------------------------------------"
echo "CMSSW Release Path: ${CMSSW_PATH}"
echo "Decay Mode to Process: ${DECAY_MODE}"
echo "Final Output Directory on EOS: ${EOS_OUTPUT_DIR}"
echo "========================================="

# --- 1. 设置 CMSSW 环境 ---
# 这是在 Condor 工作节点上必须执行的关键步骤
echo ""
echo ">>> Setting up CMSSW environment..."
source /cvmfs/cms.cern.ch/cmsset_default.sh
# 切换到你的 CMSSW release 目录
cd ${CMSSW_PATH}
# 设置 CMSSW 环境变量 (等同于 cmsenv)
eval `scramv1 runtime -sh`
# 返回到作业的初始工作目录
cd -
echo "CMSSW_BASE is now: $CMSSW_BASE"
echo "Environment setup complete."

# --- 2. 运行 Python 脚本 ---
# 进入包含你脚本的目录
cd ${CMSSW_PATH}/TauFW/Fitter

# 定义一个此作业专用的日志文件
LOG_FILE="condor_job_output_${DECAY_MODE}.log"
echo ""
echo ">>> Running createinputsTES.py for ${DECAY_MODE}..."
echo "    Log file will be: ${LOG_FILE}"

# 执行你的命令，并将所有输出（标准输出和错误输出）重定向到日志文件
python3 TauES/createinputsTES.py \
    -y 2024 \
    -c TauES_ID/config/Default_FitSetupTES_mutau_DM_mt65pt_3pt.yml \
    -d ${DECAY_MODE} \
    -j Medium \
    -e VVLoose > ${LOG_FILE} 2>&1

# 记录命令的退出状态
CMD_STATUS=$?
if [ ${CMD_STATUS} -ne 0 ]; then
    echo "!!! ERROR: Python script failed with exit code ${CMD_STATUS}."
fi

# --- 3. 处理并复制输出文件 ---
echo ""
echo ">>> Processing output..."

# 从日志文件中找到输出的 ROOT 文件名
# 这个 grep 命令是根据你之前的日志输出定制的，非常可靠
OUTPUT_BASENAME=$(grep "outputfile Name:" ${LOG_FILE} | head -n 1 | awk -F'/' '{print $NF}' | awk '{print $1}')
LOCAL_OUTPUT_PATH="input_dzytest_upart_v3/againstjet_Medium/againstelectron_VVLoose/rebinning/${OUTPUT_BASENAME}"

# 检查文件是否真的被创建了
if [ -f "${LOCAL_OUTPUT_PATH}" ]; then
    echo "    Output file found: ${LOCAL_OUTPUT_PATH}"
    echo "    Copying to EOS directory: ${EOS_OUTPUT_DIR}"
    
    # 确保 EOS 上的目标目录存在
    # mkdir -p ${EOS_OUTPUT_DIR}
    
    # 复制文件
    cp ${LOCAL_OUTPUT_PATH} ${EOS_OUTPUT_DIR}/
    
    # 检查复制是否成功
    if [ $? -eq 0 ]; then
        echo "    Successfully copied to ${EOS_OUTPUT_DIR}/${OUTPUT_BASENAME}"
    else
        echo "!!! ERROR: Failed to copy output file to EOS!"
    fi
else
    echo "!!! CRITICAL ERROR: Output ROOT file was not found at ${LOCAL_OUTPUT_PATH}!"
    echo "!!! This likely confirms that running with -d alone produces no output."
    echo "--- Displaying last 20 lines of log file for debugging ---"
    tail -n 20 ${LOG_FILE}
fi

echo ""
echo "--- Condor Job Finished ---"