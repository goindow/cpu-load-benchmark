#!/bin/bash

# 路径
path=$(dirname $(realpath $0))

# 脚本
cpulimit=$path/vender/cpulimit
overload=$path/cpu_overload.sh
cpuusage=$path/cpu_usage.sh

# 文件
stat=$path/balance.stat

# cpu 期望负载，可取值范围[0, 80]
expect=15
# cpu 负载均衡检查间隔，可取值范围[10, 300]
interval=30
# cpu 逻辑核数
cpu_logical_cores=$(grep "processor" /proc/cpuinfo | wc -l)

# cpu 均衡载荷
# @param $1 期望载荷
# @param $2 实际载荷
function cpu_balance_load() {
  int_actual_load=$(printf '%.0f' $2)
  test $1 -gt $int_actual_load && echo $(($1 - $int_actual_load)) || echo 0
}

# 启动均衡载荷
# @param $1 均衡载荷
function load_on() {
  test $1 -le 0 && return
  # 多进程
  for i in $(seq 1 $cpu_logical_cores); do
    nohup $cpulimit -l $1 $overload &> /dev/null &
  done
  sleep 1
}

# 关闭均衡载荷
function load_off() {
  pgrep overload | xargs kill -9 &> /dev/null
  sleep 1
}

# 负载均衡
# @param $1 期望负载
# @param $2 状态文件
function load_balance() {
  # 期望载荷
  expect_load=$1
  # 关闭均衡载荷
  load_off
  # 实际载荷
  actual_load=$($cpuusage)
  # 均衡载荷
  balance_load=$(cpu_balance_load $expect_load $actual_load)
  # 启动均衡载荷
  load_on $balance_load
  # 记录状态
  stat $2 $actual_load $balance_load
}

# 记录状态
function stat() {
  printf 'Expect: %2d  Interval: %3d  %s\n\n  Current Load: %2.0f\n  Actual Load:  %2.0f\n  Balance Load: %2.0f\n\n' $expect $interval "$(date +'%Y/%m/%d %H:%M:%S')" $($cpuusage) $2 $3 > $1
}

# 参数检查
function init() {
  [ "$2" != '' ] && [ -d $2 ] && stat=${2/%\//}/balance.stat
  [[ "$1" =~ ^[0-9]+$ ]] && [ $1 -le 80 ] && expect=$1
  [[ "$3" =~ ^[0-9]+$ ]] && [ $3 -le 300 ] && [ $3 -ge 10 ] && interval=$3
}


init $@
while true; do
  load_balance $expect $stat
  sleep $interval
done
