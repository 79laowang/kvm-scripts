vm=$1
if [ "$vm" == "" ]; then
  echo "Enter vm name!"
  exit 1
fi

virsh destroy $vm
virsh undefine $vm
