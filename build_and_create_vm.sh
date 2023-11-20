#!/bin/bash

# Set Variables
PACKER_TEMPLATE="server_config.json"
OVF_FILE="./output/ubuntu_22_04_java_vm.ovf"
VM_NAME="JavaVM"

echo "Going to do a packer build. This might take a while.."

# Step 1: Run Packer Build
PACKER_LOG=1 PACKER_LOG_PATH=./packer.log packer build "$PACKER_TEMPLATE"

# Step 2: Check for Success
if [ $? -eq 0 ]; then
    echo "Packer build completed successfully."
else
    echo "Packer build failed. Exiting."
    exit 1
fi

# Import the OVF file
VBoxManage import "$OVF_FILE" --vsys 0 --vmname "$VM_NAME"

# Additional VBoxManage commands to configure the VM if necessary
# VBoxManage modifyvm "$VM_NAME" --memory 2048, etc.

# Start the VM
VBoxManage startvm "$VM_NAME"
