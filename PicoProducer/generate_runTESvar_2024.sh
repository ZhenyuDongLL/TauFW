job="clean"

for tes in $(seq 0.97 0.01 1.03); do
    tes_str=$(printf "%.3f" $tes)
    tes_id=$(echo $tes_str | sed 's/\./p/')
    echo "pico.py $job -y 2024 -c mutau_inclusive -t _TES${tes_id} -s DY TT -E tes=${tes_str} > clean_${tes_str}.log 2>&1 &"
done
