#!/bin/bash
# Auto-generated script for Jet=Tight, Ele=Tight
# Tag: upart_iteration_v1

echo "=========================================="
echo "=== Processing Jet: Tight, Ele: Tight ==="
echo "=========================================="

# 确保输出目录存在
mkdir -p higgsCombine_output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight

echo "=== Step 1: Harvesting & MultiDimFit ==="

# MuMu datacard harvesting
cp input_test_upart_1208_v1/againstjet_Medium/againstelectron_VVLoose/ztt_mm_tes_m_vis.inputs-2024-13TeV_mumu.root input_upart_iteration_v1/againstjet_Tight/againstelectron_Tight
python3 TauES_ID/harvestDatacards_zmm.py -y 2024 -c TauES/config/FitSetup_mumu.yml \
    -i input_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/ \
    -o output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/2024/

# Multi-dim fit
python3 TauES_ID/makecombinedfitTES_SF.py -y 2024 -c TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml \
    -i input_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/ \
    --input_file input_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/ztt_mt_tes_m_vis.inputs-2024-13TeV_mutau.root \
    -o 3 \
    --mumu_datacard_file output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/2024/ztt_mm_m_vis-baseline_mumu-2024-13TeV.txt \
    2>&1 | tee ./run_logs/step1_multidimfit_upart_iteration_v1_Tight_Tight.log

echo "=== Step 2: FitDiagnostics + PostFit ==="

python3 TauES_ID/makecombinedfitTES_SF_postfit.py -y 2024 -c TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml \
    --indir output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/ \
    -o 3 \
    --mumu_input_file output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/2024/ztt_mm_m_vis-baseline_mumu-2024-13TeV.txt \
    -cmm TauES/config/FitSetup_mumu.yml \
    --jet_wp Tight --ele_wp Tight \
    2>&1 | tee ./run_logs/step2_postfit_upart_iteration_v1_Tight_Tight.log

echo "=== Step 3: Plotting ==="

# Run PostFit Plots
python3 python/plot/runpostfit.py \
    --tag upart_iteration_v1 \
    --outdirname postfit_upart_iteration_v1 \
    -c TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml \
    -j Tight -e Tight \
    --include-cr \
    2>&1 | tee ./run_logs/step3_plots_upart_iteration_v1_Tight_Tight.log

# Combine pre/post-fit plots
python3 pre_post_plot_combiner.py \
    --tag upart_iteration_v1 \
    --img_dir output_plots_upart_iteration_v1 \
    --out_dir combined_pre_post_upart_iteration_v1 \
    --scan_dir plots_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/2024/ \
    --jet_wp Tight --ele_wp Tight

# Measurement summary plots
python3 plot_measurements.py \
    --tag upart_iteration_v1 \
    --inputDir output_upart_iteration_v1 \
    --jet_wp Tight --ele_wp Tight

echo "=== Step 3.5: Moving HiggsCombine Files ==="
# Move files if they exist to avoid errors
if ls higgsCombine* 1> /dev/null 2>&1; then
    mv higgsCombine* higgsCombine_output_upart_iteration_v1/againstjet_Tight/againstelectron_Tight/
fi
if ls impacts_DM* 1> /dev/null 2>&1; then
    mv impacts_DM* impacts/VSjetTight_VSeleTight//
fi

echo "=== Step 4: Correction File Generation ==="

python3 createroot_TES.py -c TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml -j Tight -e Tight -f root 
python3 createroot_TES.py -c TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml -j Tight -e Tight -f json

echo "=== Done: Jet=Tight, Ele=Tight ==="
