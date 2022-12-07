#!/bin/bash

# 统计间隔
interval=${1:-1}

# cpu 时间片
function cpu_time_slot() {
  grep "cpu " /proc/stat
}

# cpu 使用时间
# aliyun 计算规则（system  + user + wait）
function cpu_used() {
  echo $1 | awk '{printf $2+$4+$6}'
}

# cpu 总时间
function cpu_total() {
  echo $1 | awk '{printf $2+$3+$4+$5+$6+$7+$8}'
}

# cpu 使用率
function cpu_usage() {
  slot1=$(cpu_time_slot)
  used1=$(cpu_used "$slot1")
  total1=$(cpu_total "$slot1")
  sleep $interval
  slot2=$(cpu_time_slot)
  used2=$(cpu_used "$slot2")
  total2=$(cpu_total "$slot2")
  usage=$(echo "($used2 - $used1) / ($total2 - $total1) * 100" | bc -l)
  printf '%.2f\n' $usage
}

cpu_usage $interval
