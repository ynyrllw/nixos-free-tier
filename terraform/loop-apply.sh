#!/bin/bash
cd "$(dirname "$0")"
i=1
while true; do
    echo "=== Attempt $i $(date) ==="
    /home/ynyrllw/.local/bin/tofu apply -var-file terraform.tfvars -auto-approve -lock=false 2>&1 | tail -5
    if /home/ynyrllw/.local/bin/tofu state list 2>/dev/null | grep -q "oci_core_instance.nixos"; then
        echo "SUCCESS! Instance created!"
        /home/ynyrllw/.local/bin/tofu output
        break
    fi
    i=$((i+1))
    echo "Sleeping 60s..."
    sleep 60
done
