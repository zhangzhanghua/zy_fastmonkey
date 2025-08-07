# Maxim 

> An efficient Android Monkey Tester, available for emulators and real devices
> 基于遍历规则的高性能Android Monkey，适用于真机/模拟器的APP UI压力测试


# 环境预备

## 系统要求
* 支持 Android 5.0 及更高版本 (Android 5.0+)
* 需要开启 USB 调试模式
* 建议使用 Android 10 或更高版本获得最佳体验

## 快速开始
1. 确保已安装 ADB 工具并配置好环境变量
2. 连接设备并授权 USB 调试
3. 推送必要文件到设备：
```bash
# 创建专用目录
adb shell mkdir -p /sdcard/maxim

# 推送必要文件
adb push framework.jar /sdcard/maxim/
adb push monkey.jar /sdcard/maxim/

# 设置文件权限
adb shell chmod 644 /sdcard/maxim/*
```

## 兼容性说明
- **Android 10+**: 完全支持
- **Android 9.0 (Pie)**: 完全支持
- **Android 8.x (Oreo)**: 完全支持
- **Android 7.x (Nougat)**: 完全支持
- **Android 6.0 (Marshmallow)**: 基本支持
- **Android 5.0/5.1 (Lollipop)**: 基本支持，部分功能可能受限

> 注意：对于 Android 11+ 设备，请确保已授予 `WRITE_EXTERNAL_STORAGE` 和 `READ_EXTERNAL_STORAGE` 权限。

# 命令行模式

## 基本用法
```bash
adb shell CLASSPATH=/sdcard/maxim/monkey.jar:/sdcard/maxim/framework.jar \
    exec app_process /system/bin tv.panda.test.monkey.Monkey \
    -p 你的应用包名 \
    --uiautomatormix \
    --running-minutes 60 \
    -v -v
```

## 参数说明
* `tv.panda.test.monkey.Monkey` - Monkey 入口类（固定）
* `-p 你的应用包名` - 要测试的应用包名（必填）
* `--uiautomatormix` - 混合遍历策略（推荐）
* `--running-minutes 60` - 运行时间（分钟）
* `-v -v` - 详细日志输出

## 高级用法

### 1. 使用 DFS 深度遍历策略
```bash
adb shell CLASSPATH=/sdcard/maxim/monkey.jar:/sdcard/maxim/framework.jar \
    exec app_process /system/bin tv.panda.test.monkey.Monkey \
    -p 你的应用包名 \
    --uiautomatordfs \
    --running-minutes 30
```

### 2. 设置事件间隔（毫秒）
```bash
--throttle 500  # 每个事件间隔500毫秒
```

### 3. 指定输出目录（Android 10+）
```bash
--output-directory /sdcard/maxim/results/
```

## 兼容性提示
- 对于 Android 10+ 设备，请确保应用已授予存储权限
- 如果遇到权限问题，可以尝试使用 `--grant-all-permissions` 参数
- 在 Android 11+ 上，可能需要手动授予 `MANAGE_EXTERNAL_STORAGE` 权限

## 常见问题

### 1. 命令执行无响应
- 检查设备是否已授权 USB 调试
- 确认文件路径和权限正确
- 尝试重启 adb 服务：`adb kill-server && adb start-server`

### 2. 存储权限问题
```bash
# 检查存储权限
adb shell pm list permissions -g | grep storage

# 授予存储权限
adb shell pm grant 你的应用包名 android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant 你的应用包名 android.permission.READ_EXTERNAL_STORAGE
```

### 3. 性能优化
- 增加 `--throttle` 值可降低 CPU 使用率
- 使用 `--pct-touch` 调整触摸事件比例
- 对于性能较差的设备，可以减少并发线程数

# 策略

1. 模式 Mix (基于事件概率的压力测试)
   ```
   --uiautomatormix
   直接使用底层accessibiltyserver获取界面接口 解析各控件，随机选取一个控件执行touch操作。
     同时与原monkey 其他操作按比例混合使用
     默认accessibilityserver action占比50%，其余各action分剩余的50%
     accessibilityserver action占比可配置 --pct-uiautomatormix n
   ```

2. 模式 DFS
  ```
  --uiautomatordfs
  深度遍历算法
  ```

3. 模式Troy
  ```
  --uiautomatortroy
  控件选择策略按max.xpath.selector配置的高低优先级来进行深度遍历
  ```

4. 保留原始monkey

5. 总运行时长
  --running-minutes 3  运行3分钟

6. --act-whitelist-file  /sdcard/awl.strings    定义白名单
   --act-blacklist-file

其他参数与原始monkey一致


<hr>



## 1. Requirements

- Android 5/6/7/8/9/10/11


## 2. Installation
```
adb push framework.jar /sdcard
adb push monkey.jar /sdcard
```
Optionally, push configuration file(s)
```
adb push ape.strings /sdcard
adb push awl.strings /sdcard

```
## 3. Usage 

Maxim is started from adb shell 
```
adb shell CLASSPATH=/sdcard/monkey.jar:/sdcard/framework.jar exec app_process /system/bin tv.panda.test.monkey.Monkey -p com.panda.videoliveplatform --uiautomatordfs 5000
```

### Modes
* mix mode:  `--uiautomatormix`  use AccessibilityService to resolve view tree and mix vanilla monkey events with view clicks.  About 10-20 actions per second.
  * `--pct-uiautomatormix`   ratio (percentage number)

### Timing control
* `--running-minutes  n`  run for n minutes

### Optional configuration (rules)

* `--act-whitelist-file` e.g., /sdcard/awl.strings white list for activities
* `--act-blacklist-file`
* `max.xpath.actions`  to specify special event, see example
