# cpu-load-benchmark
CPU 使用率达标辅助程序，支持多核、平衡载荷负载均衡等

## 使用场景
- 在一些政府项目中，政务网等有时候会对实例的 CPU 平均使用率进行考核，不达标将被降配，可以使用该辅助程序完成达标任务

## 支持的 OS
- CentOS
- Ubuntu

## 依赖说明（自动安装）
- gcc
- make
- cpulimit

## 文件说明
- benchmark.sh，快捷方式，通常请使用该脚本来启动/停止程序
 - -e export_load，期望负载，默认 15，取值范围了 [0, 80]
 - -i cpu_load_balance_interval，负载均衡检查间隔，默认 30 秒，取值范围 [10, 300]
- bin/cpu_load_balance.sh，核心实现，根据 CPU 逻辑核数实现期望负载的动态调整，调整周期如上参数指定，一般不推荐直接使用该脚本
- bin/cpu_overload.sh，超载程序
- bin/cpu_usage.sh，计算 CPU 整体使用率
- bin/vender/cpulimit(.tar.gz)，三方依赖，使进程在 CPU 限额下运行
- balance.pid，cpu_load_balance.sh 进程信息
- balance.stat，cpu_load_balance.sh 运行状态信息


## 使用说明
```shell
Usage: benchmark COMMAND [ARGS...]

  Auxiliary program for CPU utilization reaching the standard, 
  supporting multi-core, load balancing, etc

Commands:
  status                             Print pid
  stop                               Kill the program
  start [-e expect] [-i interval]    Run the program
      -e expect_load                 Set expected load(default 15, only in [0, 80])                    
      -i load_balance_interval       Set load balancing interval(default 30, only in [10, 300], unit second)
```

## 示例
```shell
# 启动
benchmark start                # 默认，CPU 期望整体平均使用率达到 15%，检查间隔 30s
benchmark start -e 30 -i 15    # 指定，CPU 期望整体平均使用率达到 30%，检查间隔 15s

# 停止
benchmark stop

# 状态
benchmark status

# 运行状态信息
cat balance.stat
```