#!/bin/bash

# 路径
path=$(dirname $(realpath $0))
bin_path=$path/bin
vender_path=$bin_path/vender

# 脚本
cpulimit=$vender_path/cpulimit
balance=$bin_path/cpu_load_balance.sh

# 文件
pid=$path/balance.pid

# 默认值，cpu 期望负载，可取值范围[0, 80]
default_expect_load=15
# 默认值，cpu 负载均衡检查间隔，可取值范围[10, 300]
default_balance_interval=30

# 帮助
function usage() {
  echo usage
}

# 通知
function dialog() {
  case $1 in
    fatal) printf '%s\n' "$2" && exit 1;;
    error) printf '%s\n\n%s\n' "$2" 'For more details, see "benchmark.sh help".' && exit 1;;
    info)  printf '%s\n' "$2";;
    ok)    echo 'OK.';;
    exit)  echo 'exited.';;
  esac
  exit 0
}

# 选项
function opts() {
  while getopts 'e:i:' options; do
    case $options in
      e) expect=$OPTARG;;
      i) interval=$OPTARG;;
    esac
  done
  [[ ! "$expect" =~ ^[0-9]+$ ]] || [ $expect -gt 80 ] && expect=$default_expect_load
  [[ ! "$interval" =~ ^[0-9]+$ ]] || [ $interval -gt 300 ] || [ $interval -lt 10 ] && interval=$default_balance_interval
  return $(($OPTIND - 1))
}

# 启动
function start() {
  opts $@ || shift $?
  nohup $balance $expect $path $interval &>/dev/null &
  echo $! > $pid && dialog info "Running($!)..."
}

# 关闭
function stop() {
  # 关闭均衡载荷
  pgrep overload | xargs kill -9 &> /dev/null
  # 关闭负载均衡
  cat $pid 2> /dev/null | xargs kill -9 &> /dev/null
  rm -rf $pid && dialog info "Stopped running."
}

# 状态
function status() {
  cat $pid 2>/dev/null || dialog info "Not running."
}

# 编译 cpulimit
function init() {
  cd $path && test -x "$(command -v $cpulimit)" && return
  tar -zxf $vender_path/cpulimit.tar.gz -C $vender_path &> /dev/null || dialog fatal "Decompression failed."
  cd $vender_path/cpulimit-master
  make &> /dev/null && cp ./src/cpulimit $vender_path || dialog fatal "Compilation failed."
  cd $path && rm -rf $vender_path/cpulimit-master
}


init
case $1 in
  status)    status;;
  start)     shift && start $@;;
  stop)      stop;;
  *)         usage;;
esac
