#!/bin/bash
# Save as generate_job_scripts.sh
# Usage: ./generate_job_scripts.sh

# ==========================================
# 1. 配置区域
# ==========================================

# 定义需要循环的 WP
J_VALUES=("VVLoose" "VLoose" "Loose" "Medium" "Tight") 
E_VALUES=("VVLoose" "Tight")

# 全局变量
YEAR="2024"
TAG="upart_iteration_v1"

# 配置文件路径
CONFIG_TT="TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml"
CONFIG_MM="TauES/config/FitSetup_mumu.yml"

# 生成脚本的存放目录 (可选，保持整洁)
JOB_DIR="jobs_${TAG}"
mkdir -p ${JOB_DIR}
mkdir -p ./run_logs

echo "正在生成脚本到目录: ${JOB_DIR} ..."

# ==========================================
# 2. 循环生成脚本
# ==========================================

for JET_WP in "${J_VALUES[@]}"; do
  for ELE_WP in "${E_VALUES[@]}"; do
    
    # 定义生成的脚本文件名
    SCRIPT_NAME="${JOB_DIR}/run_${TAG}_Jet${JET_WP}_Ele${ELE_WP}.sh"
    
    # 定义该 WP 组合的路径变量 (用于写入脚本内部)
    BASE_INPUT="input_${TAG}/againstjet_${JET_WP}/againstelectron_${ELE_WP}"
    BASE_OUTPUT="output_${TAG}/againstjet_${JET_WP}/againstelectron_${ELE_WP}"
    BASE_PLOTS="plots_${TAG}/againstjet_${JET_WP}/againstelectron_${ELE_WP}"
    BASE_COMBINE="higgsCombine_output_${TAG}/againstjet_${JET_WP}/againstelectron_${ELE_WP}"
    
    # 定义日志文件名
    LOG_SUFFIX="${TAG}_${JET_WP}_${ELE_WP}.log"

    # ==========================================
    # 3. 写入内容到脚本文件 (Here-Document)
    # ==========================================
    cat << EOF > "${SCRIPT_NAME}"
#!/bin/bash
# Auto-generated script for Jet=${JET_WP}, Ele=${ELE_WP}
# Tag: ${TAG}

echo "=========================================="
echo "=== Processing Jet: ${JET_WP}, Ele: ${ELE_WP} ==="
echo "=========================================="

# 确保输出目录存在
mkdir -p ${BASE_COMBINE}

echo "=== Step 1: Harvesting & MultiDimFit ==="

# MuMu datacard harvesting
cp input_test_upart_1208_v1/againstjet_Medium/againstelectron_VVLoose/ztt_mm_tes_m_vis.inputs-2024-13TeV_mumu.root ${BASE_INPUT}
python3 TauES_ID/harvestDatacards_zmm.py -y ${YEAR} -c ${CONFIG_MM} \\
    -i ${BASE_INPUT}/ \\
    -o ${BASE_OUTPUT}/${YEAR}/

# Multi-dim fit
python3 TauES_ID/makecombinedfitTES_SF.py -y ${YEAR} -c ${CONFIG_TT} \\
    -i ${BASE_INPUT}/ \\
    --input_file ${BASE_INPUT}/ztt_mt_tes_m_vis.inputs-${YEAR}-13TeV_mutau.root \\
    -o 3 \\
    --mumu_datacard_file ${BASE_OUTPUT}/${YEAR}/ztt_mm_m_vis-baseline_mumu-${YEAR}-13TeV.txt \\
    2>&1 | tee ./run_logs/step1_multidimfit_${LOG_SUFFIX}

echo "=== Step 2: FitDiagnostics + PostFit ==="

python3 TauES_ID/makecombinedfitTES_SF_postfit.py -y ${YEAR} -c ${CONFIG_TT} \\
    --indir ${BASE_OUTPUT}/ \\
    -o 3 \\
    --mumu_input_file ${BASE_OUTPUT}/${YEAR}/ztt_mm_m_vis-baseline_mumu-${YEAR}-13TeV.txt \\
    -cmm ${CONFIG_MM} \\
    --jet_wp ${JET_WP} --ele_wp ${ELE_WP} \\
    2>&1 | tee ./run_logs/step2_postfit_${LOG_SUFFIX}

echo "=== Step 3: Plotting ==="

# Run PostFit Plots
python3 python/plot/runpostfit.py \\
    --tag ${TAG} \\
    --outdirname postfit_${TAG} \\
    -c ${CONFIG_TT} \\
    -j ${JET_WP} -e ${ELE_WP} \\
    --include-cr \\
    2>&1 | tee ./run_logs/step3_plots_${LOG_SUFFIX}

# Combine pre/post-fit plots
python3 pre_post_plot_combiner.py \\
    --tag ${TAG} \\
    --img_dir output_plots_${TAG} \\
    --out_dir combined_pre_post_${TAG} \\
    --scan_dir ${BASE_PLOTS}/${YEAR}/ \\
    --jet_wp ${JET_WP} --ele_wp ${ELE_WP}

# Measurement summary plots
python3 plot_measurements.py \\
    --tag ${TAG} \\
    --inputDir output_${TAG} \\
    --jet_wp ${JET_WP} --ele_wp ${ELE_WP}

echo "=== Step 3.5: Moving HiggsCombine Files ==="
# Move files if they exist to avoid errors
if ls higgsCombine* 1> /dev/null 2>&1; then
    mv higgsCombine* ${BASE_COMBINE}/
fi
if ls impacts_DM* 1> /dev/null 2>&1; then
    mv impacts_DM* impacts/VSjet${JET_WP}_VSele${ELE_WP}//
fi

echo "=== Step 4: Correction File Generation ==="

python3 createroot_TES.py -c ${CONFIG_TT} -j ${JET_WP} -e ${ELE_WP} -f root 
python3 createroot_TES.py -c ${CONFIG_TT} -j ${JET_WP} -e ${ELE_WP} -f json

echo "=== Done: Jet=${JET_WP}, Ele=${ELE_WP} ==="
EOF

    # ==========================================
    # 4. 赋予执行权限
    # ==========================================
    chmod +x "${SCRIPT_NAME}"
    echo "Generated: ${SCRIPT_NAME}"

  done
done

# ==========================================
# 5. 生成一个总控脚本 (可选)
# ==========================================
MASTER_SCRIPT="run_all_generated_jobs.sh"
echo "#!/bin/bash" > $MASTER_SCRIPT
echo "# Run all generated scripts sequentially" >> $MASTER_SCRIPT
for f in ${JOB_DIR}/*.sh; do
    echo "echo \"Running $f ...\"" >> $MASTER_SCRIPT
    echo "./$f" >> $MASTER_SCRIPT
done
# 添加最后的 JSON 合并步骤
echo "" >> $MASTER_SCRIPT
echo "echo \"=== Merging all JSON correction files ===\"" >> $MASTER_SCRIPT
echo "python3 merge_tau_jsons.py --type both -o tau_sf/TauCorrections_${YEAR}_${TAG}.json" >> $MASTER_SCRIPT

chmod +x $MASTER_SCRIPT

echo "=========================================="
echo "所有脚本已生成完毕！"
echo "1. 单独运行某个脚本: ./${JOB_DIR}/run_...sh"
echo "2. 运行所有脚本: ./$MASTER_SCRIPT"
echo "=========================================="