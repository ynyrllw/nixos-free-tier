#!/bin/bash
set -e

echo "=== Oracle Cloud Resource Cleanup Script ==="
echo "This will delete compute instances, custom images, and VCN resources."
echo ""

TENANCY_OCID="${OCI_TENANCY_OCID:-}"
REGION="${OCI_REGION:-eu-zurich-1}"

if [ -z "$TENANCY_OCID" ]; then
  echo "Error: OCI_TENANCY_OCID not set"
  exit 1
fi

echo "Using tenancy: $TENANCY_OCID"
echo "Using region: $REGION"
echo ""

if [ "$1" != "--force" ]; then
  read -p "Delete ALL resources in this tenancy? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
fi

echo ""
echo "=== Deleting Running Compute Instances ==="
for inst in $(oci compute instance list --compartment-id "$TENANCY_OCID" --lifecycle-state RUNNING --query "data[].id" --raw-output 2>/dev/null); do
  echo "Terminating instance: $inst"
  oci compute instance terminate --instance-id "$inst" --preserve-boot-volume false --force 2>/dev/null || true
done

echo "Waiting for instances to terminate..."
sleep 30

echo ""
echo "=== Cleaning Terminated Instances ==="
for inst in $(oci compute instance list --compartment-id "$TENANCY_OCID" --lifecycle-state TERMINATED --query "data[*].id" --raw-output 2>/dev/null | tr -d '[]",'); do
  if [ -n "$inst" ]; then
    echo "Terminating instance (cleanup): $inst"
    oci compute instance terminate --instance-id "$inst" --preserve-boot-volume false --force 2>/dev/null || true
  fi
done

echo ""
echo "=== Deleting Custom Images ==="
for img in $(oci compute image list --compartment-id "$TENANCY_OCID" --lifecycle-state AVAILABLE --query "data[?\"display-name\" contains 'nixos' || \"display-name\" contains 'NixOS']".id --raw-output 2>/dev/null); do
  echo "Deleting image: $img"
  oci compute image delete --image-id "$img" --force 2>/dev/null || true
done

echo ""
echo "=== Deleting VCNs ==="
for vcn in $(oci network vcn list --compartment-id "$TENANCY_OCID" --query "data[?\"display-name\" contains 'nixos' || \"display-name\" contains 'NixOS']".id --raw-output 2>/dev/null); do
  echo "Deleting VCN: $vcn"
  
  echo "  Deleting subnets..."
  for subnet in $(oci network subnet list --vcn-id "$vcn" --query "data[].id" --raw-output 2>/dev/null); do
    oci network subnet delete --subnet-id "$subnet" --force 2>/dev/null || true
  done
  
  echo "  Deleting internet gateways..."
  for ig in $(oci network internet-gateway list --vcn-id "$vcn" --query "data[].id" --raw-output 2>/dev/null); do
    oci network internet-gateway delete --ig-id "$ig" --force 2>/dev/null || true
  done
  
  echo "  Deleting route tables..."
  for rt in $(oci network route-table list --vcn-id "$vcn" --query "data[].id" --raw-output 2>/dev/null); do
    oci network route-table delete --rt-id "$rt" --force 2>/dev/null || true
  done
  
  echo "  Deleting security lists..."
  for sl in $(oci network security-list list --vcn-id "$vcn" --query "data[].id" --raw-output 2>/dev/null); do
    oci network security-list delete --security-list-id "$sl" --force 2>/dev/null || true
  done
  
  echo "  Deleting VCN..."
  oci network vcn delete --vcn-id "$vcn" --force 2>/dev/null || true
done

echo ""
echo "=== Deleting Buckets ==="
for bucket in $(oci os bucket list --compartment-id "$TENANCY_OCID" --query "data[?\"name\" contains 'nixos' || \"name\" contains 'NixOS']".name --raw-output 2>/dev/null); do
  echo "Deleting bucket: $bucket"
  for obj in $(oci os object list --bucket-name "$bucket" --query "data[].name" --raw-output 2>/dev/null); do
    oci os object delete --bucket-name "$bucket" --object-name "$obj" --force 2>/dev/null || true
  done
  oci os bucket delete --name "$bucket" --force 2>/dev/null || true
done

echo ""
echo "=== Cleanup Complete ==="
