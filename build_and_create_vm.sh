#!/bin/bash
# set -x otrace
# Set Variables
PACKER_TEMPLATE="server_config.json"
OVF_FILE="./output/ubuntu_22_04_java_vm.ovf"
VM_NAME="JavaVM"

echo "Username for VM is ubuntu"
read -sp "Password for the VM: " password

hashedPass=$(echo "$password" | mkpasswd --method=SHA-512 --rounds=4096 --stdin)
escapedhashPass=$(echo $hashedPass | sed 's/\//\\\//g')

echo "Updating hashedPassword in user-data file.."

# sed -i "s-password: \".*\"-password: \"$escapedhashPass\"-" ./http/user-data

# awk -v pw="$escapedhashPass" '{ if ($1 == "password:") $2 = "\"" pw "\""; print }' ./http/user-data > ./http/temp-user-data && mv ./http/temp-user-data ./http/user-data
# awk -v pw="$escapedhashPass" '{ if ($1 == "password:") $0 = gensub(/(.+password: ).+/, "\\1\"" pw "\"", 1); print }' ./http/user-data > ./http/temp-user-data && mv ./http/temp-user-data ./http/user-data
awk -v pw="$escapedhashPass" \
'{
    if ($1 == "password:") {
        match($0, /^[ \t]*/);
        leading_space = substr($0, RSTART, RLENGTH);
        print leading_space "password: \"" pw "\"";
    } else {
        print;
    }
}' ./http/user-data > ./http/temp-user-data && mv ./http/temp-user-data ./http/user-data

echo "Going to do a packer build. This might take a while.."

# Step 1: Run Packer Build
packer build -var "password=\"$password\"" "$PACKER_TEMPLATE"

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

# Set graphics controller to VMSVGA
VBoxManage modifyvm "$VM_NAME" --graphicscontroller vmsvga

# Set the amount of video memory
VBoxManage modifyvm "$VM_NAME" --vram 128

# Turn off VRDE
VBoxManage modifyvm "$VM_NAME" --vrde off

# Start the VM
VBoxManage startvm "$VM_NAME"
