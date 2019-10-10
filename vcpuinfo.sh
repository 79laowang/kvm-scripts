#!/bin/bash
[ -z "$1" ] && { echo "Please enter a vm name!";exit 1; }
DOMU=$1
get_numanode(){
  if [ $1 -ge 0 ]; then
  numanodes=`lscpu  | grep 'NUMA node(s)' | awk -F ':'  '{print $2}'`
  i=0
  while [[ $i -lt $numanodes ]]; do
      nncpus=`lscpu  | grep "NUMA node$i" | awk -F ':'  '{print $2}'`
      arr_uncpus=(${nncpus//,/ })
      for cpus in "${arr_uncpus[@]}"
      do
        cpu_start=`echo $cpus | awk -F '-' '{print $1}'`
        cpu_end=`echo $cpus | awk -F '-' '{print $2}'`
        if [ $1 -ge $cpu_start -a $1 -le $cpu_end ];then
           printf "%d" $i
        fi
      done
      ((i++));
  done
  fi
}

while  [ 1 ] ; do
    DOM_STATE=`virsh list --all | awk '/'$DOMU'/ {print $NF}'`
    echo "${DOMU}: $DOM_STATE"
    virsh  numatune $DOMU
    vcpus=`virsh vcpuinfo $DOMU |  grep -E  "VCPU|CPU:" |  awk '/VCPU:/ {printf "VCPU %s ",$NF} /^CPU:/ {printf "pCPU %s\n",$NF}'`
#printf "%s %s %s %s\n" $vcpus
    printf "%s %s %s %s\n" $vcpus | while read vcpu num1 pcpu num2 ;do
        node_num=`get_numanode $num2`
        printf "%s: %2d => %s: %2d on NUMA Node:%s\n" $vcpu $num1 $pcpu $num2 $node_num
    done
    sleep 2
done
