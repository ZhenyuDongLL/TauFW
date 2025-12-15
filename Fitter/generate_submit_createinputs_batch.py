import os

# ================= 配置区域 =================

# 1. 你的 CMSSW 绝对路径
cmssw_path = "/afs/cern.ch/user/z/zhdong/CMSSW_14_1_0_pre4/src" 

# 2. 定义你要循环的参数列表
eras = ["2024"]
vsjet_wps = [
    "VVLoose", 
    "VLoose", 
    "Loose", 
    "Medium", 
    "Tight", 
    "VTight"
    ]
vse_wps = ["VVLoose", "Tight"]

# 3. 配置文件路径 (相对于 TauFW/Fitter 的路径)
config_file = "TauES_ID/config/Default_FitSetupTES_mutau_UparT_v1.yml"

analysis_tag = "upart_iteration_v1"

# 4. Condor 日志存放目录 (会自动创建)
condor_log_dir = "condor_logs"

# 5. 生成的 .sub 文件存放目录
submit_dir = "submit_files"

# ===========================================

def main():
    # 创建必要的文件夹
    if not os.path.exists(condor_log_dir):
        os.makedirs(condor_log_dir)
    if not os.path.exists(submit_dir):
        os.makedirs(submit_dir)

    print(f"Generating .sub files in directory: {submit_dir}/ ...\n")
    
    submit_commands = []

    # 开始循环
    for era in eras:
        for vsjet in vsjet_wps:
            for vse in vse_wps:
                
                # 构造唯一的 TAG
                unique_id = f"{era}_vsjet_{vsjet}_vse_{vse}"
                job_name_for_condor = f"job_{unique_id}"
                
                submit_content = generate_submit_file_content(
                    job_name_for_condor=job_name_for_condor,
                    cmssw_path=cmssw_path,
                    era=era,
                    config=config_file,
                    vsjet=vsjet,
                    vse=vse,
                    fixed_tag=analysis_tag  # 传入固定的 tag
                )
                
                # 写入文件
                filename = f"{submit_dir}/submit_{unique_id}.sub"
                with open(filename, "w") as f:
                    f.write(submit_content)
                
                submit_commands.append(f"condor_submit {filename}")
                print(f"  -> Generated: {filename}")

    print("\n" + "="*50)
    print("Done! Please check the generated files.")
    print("To submit individual jobs, run the commands below:")
    print("-" * 50)
    
    for cmd in submit_commands:
        print(cmd)
        
    print("-" * 50)
    
    # 额外生成一个 shell 脚本，方便你一次性提交所有 (可选)
    submit_all_script = "submit_all.sh"
    with open(submit_all_script, "w") as f:
        f.write("#!/bin/bash\n")
        for cmd in submit_commands:
            f.write(f"{cmd}\n")
    os.chmod(submit_all_script, 0o755)
    print(f"Tip: You can also run './{submit_all_script}' to submit all of them at once.")
    print("="*50)

def generate_submit_file_content(job_name_for_condor, cmssw_path, era, config, vsjet, vse, fixed_tag):
    """
    生成 Condor submit 文件的文本内容
    """
    
    content = f"""
executable = run_createinputs_batch.sh
arguments  = {cmssw_path} {era} {config} {vsjet} {vse} {fixed_tag}

output     = {condor_log_dir}/{job_name_for_condor}.out
error      = {condor_log_dir}/{job_name_for_condor}.err
log        = {condor_log_dir}/{job_name_for_condor}.log

request_cpus   = 8
request_memory = 3000
+JobFlavour           = "workday"

getenv = True
should_transfer_files = YES

queue 1
"""
    return content

if __name__ == "__main__":
    main()