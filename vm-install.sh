#!/bin/bash
domu_name=$1
if [ "$domu_name" == "" ]; then
   echo "enter guest name!"
   exit 1
fi

mkdir -p /kvm/$domu_name
cp ol7-ks.cfg /kvm/$domu_name

install_vnc(){
    max_vnc_port=`lsof -i -P | grep -i "listen" | grep "qemu-sys" | awk '{print $9}' | awk -F : '{print $2}' | sort | awk 'END {print}'`
    if [ "$max_vnc_port" == "" ]; then
      free_vnc_port=5901
    else
      free_vnc_port=$[max_vnc_port + 1]
    fi
    
    if which firewall-cmd >/dev/null 2>&1;then
        if firewall-cmd --list-all | grep "$free_vnc_port" ; then
          :
        else
          firewall-cmd --permanent --zone=public --add-port=$free_vnc_port/tcp
          firewall-cmd --reload
        fi
    fi
    echo
    echo "To view the installation, use vnc client to access hostname:$free_vnc_port"
    echo

    virt-install \
        --name $domu_name \
        --ram 2048 \
        --disk path=/kvm/$domu_name/$domu_name.img,size=5 \
        --vcpus 1 \
        --os-type linux \
        --os-variant rhel6 \
        --network bridge:${bridge_name} \
        --location "$IMAGE_URL" \
        --initrd-inject=/kvm/$domu_name/ol7-ks.cfg \
        --extra-args="ks=file:/ol7-ks.cfg" \
        --graphics vnc,listen=0.0.0.0,port=$free_vnc_port \
        --noautoconsole \
        --accelerate
}

install_console(){
    virt-install \
        --name $domu_name \
        --ram 2048 \
        --disk path=/kvm/$domu_name/$domu_name.img,size=5 \
        --vcpus 1 \
        --os-type linux \
        --os-variant rhel6 \
        --network bridge:${vm_bridge} \
        --location "$IMAGE_URL" \
        --initrd-inject=/kvm/$domu_name/ol7-ks.cfg \
        --extra-args="ks=file:/ol7-ks.cfg text console=tty0 console=ttyS0,115200" \
        --graphics none \
        --accelerate
}

bridge_name="virbr0"
export http_proxy=""
IMAGE_URL="https://mirrors.aliyun.com/centos/7/os/x86_64/"
install_vnc
