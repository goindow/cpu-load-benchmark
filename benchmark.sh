#!/bin/bash

# 路径
path=$(dirname $(readlink -f $0))
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

function os() {
  os='Unknown'
  test -x "$(command -v yum)" && os='CentOS'
  test -x "$(command -v apt-get)" && os='Ubuntu'
  echo $os
}

# 适配安装器
function adapter() {
  test 'CentOS' == $os && echo "$(command -v yum) install -y"
  test 'Ubuntu' == $os && echo "$(command -v apt-get) install -y"
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

# 操作确认
# $1 操作提示
# $2 错误输入次数，默认 3 次
# @return $?, 0 - 确认操作、1 - 取消操作
function ensure() {
  chances=${2:-3}
  while test $chances -gt 0; do
    read -p "$1, are you sure? [Y/n]: " input
    case $input in
        [yY][eE][sS]|[yY])
          return 0
        ;;
        [nN][oO]|[nN])
          return 1
        ;;
        *)
          chances=$(($chances - 1))
          test $chances -le 0 && echo "exited." && exit 1
          echo "Invalid input...($chances chances left)"
        ;;
    esac
  done
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

function install_make() {
  $(adapter) make
}

function install_gcc() {
  $(adapter) gcc
}

function check_dependencies() {
  dependencies=(gcc make)
  # 待安装集合
  for dependence in ${dependencies[@]}; do
    test ! -x "$(command -v $dependence)" && list+=($dependence)
  done
  test ${#list[@]} -eq 0 && return
  # 缺失必要依赖
  echo -e "Lack of necessary dependencies:\n\n \033[33m${list[@]}\033[0m\n"
  test 'Unknown' == $os && dialog fatal "Unknown os, please manually install dependencies first. If already installed, add to the PATH."
  ensure 'Install the above dependencies' || dialog exit
  # 安装
  for dependence in ${list[@]}; do
    install_$dependence
  done
}

function compile_cpulimit()  {
  tar -zxf $vender_path/cpulimit.tar.gz -C $vender_path &> /dev/null || dialog fatal "Decompression failed."
  cd $vender_path/cpulimit-master
  make &> /dev/null && cp ./src/cpulimit $vender_path || dialog fatal "Compilation failed."
  cd $path && rm -rf $vender_path/cpulimit-master
}

function init() {
  cd $path && test -x "$(command -v $cpulimit)" && return
  check_dependencies
  compile_cpulimit
}


init
case $1 in
  status)    status;;
  start)     shift && start $@;;
  stop)      stop;;
  *)         usage;;
esac
