<#
.SYNOPSIS
    Maxim 环境检测与设置脚本
    
.DESCRIPTION
    此脚本用于检测和设置 Maxim 测试框架所需的环境和权限
    支持 Android 5.0 及以上版本
    
.USAGE
    .\setup_maxim.ps1 -packageName "com.example.app"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$packageName,
    
    [string]$maximDir = "/sdcard/maxim"
)

# 检查 ADB 是否可用
function Test-ADB {
    try {
        $adbVersion = adb version
        if ($LASTEXITCODE -ne 0) {
            Write-Error "❌ 未找到 ADB 或 ADB 未正确配置"
            exit 1
        }
        Write-Host "✅ ADB 检测通过" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ ADB 检测失败: $_"
        exit 1
    }
}

# 检查设备连接
function Test-DeviceConnected {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
    if (-not $devices) {
        Write-Error "❌ 未检测到连接的设备"
        exit 1
    }
    Write-Host "✅ 已连接设备: $($devices -replace '\t.*$','')" -ForegroundColor Green
}

# 检查 Android 版本
function Get-AndroidVersion {
    $sdkVersion = adb shell getprop ro.build.version.sdk
    $release = adb shell getprop ro.build.version.release
    Write-Host "📱 Android 版本: $release (API $sdkVersion)" -ForegroundColor Cyan
    
    if ([int]$sdkVersion -lt 21) {
        Write-Error "❌ 不支持的 Android 版本 (需要 Android 5.0+)"
        exit 1
    }
    
    return [int]$sdkVersion
}

# 创建目录并推送文件
function Initialize-MaximDirectory {
    Write-Host "🔄 正在初始化 Maxim 目录..." -ForegroundColor Yellow
    
    # 创建目录
    adb shell "mkdir -p $maximDir 2>/dev/null"
    
    # 推送必要文件
    $requiredFiles = @("framework.jar", "monkey.jar")
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "  正在推送 $file..." -NoNewline
            adb push $file "$maximDir/" > $null
            Write-Host " ✅" -ForegroundColor Green
        }
        else {
            Write-Warning "  未找到 $file，请确保它在当前目录中"
        }
    }
    
    # 设置权限
    adb shell "chmod 644 $maximDir/*"
    Write-Host "✅ Maxim 目录初始化完成" -ForegroundColor Green
}

# 检查并授予权限
function Grant-Permissions {
    param(
        [int]$sdkVersion
    )
    
    Write-Host "🔑 正在检查并授予权限..." -ForegroundColor Yellow
    
    # 基本存储权限
    $permissions = @(
        "android.permission.WRITE_EXTERNAL_STORAGE",
        "android.permission.READ_EXTERNAL_STORAGE"
    )
    
    # Android 10+ 需要额外权限
    if ($sdkVersion -ge 29) {
        $permissions += @(
            "android.permission.READ_MEDIA_IMAGES",
            "android.permission.READ_MEDIA_VIDEO"
        )
    }
    
    # Android 11+ 需要特殊处理
    if ($sdkVersion -ge 30) {
        $permissions += @(
            "android.permission.MANAGE_EXTERNAL_STORAGE"
        )
        
        # 尝试授予所有文件访问权限
        Write-Host "  正在请求所有文件访问权限..." -NoNewline
        $result = adb shell "appops set --uid $packageName MANAGE_EXTERNAL_STORAGE allow"
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅" -ForegroundColor Green
        }
        else {
            Write-Host " ⚠️ 可能需要手动授予权限" -ForegroundColor Yellow
        }
    }
    
    # 授予其他权限
    foreach ($permission in $permissions) {
        Write-Host "  正在授予 $permission..." -NoNewline
        $result = adb shell "pm grant $packageName $permission 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✅" -ForegroundColor Green
        }
        else {
            Write-Host " ❌ ($result)" -ForegroundColor Red
        }
    }
}

# 显示完成信息
function Show-CompletionMessage {
    Write-Host "\n✨ Maxim 环境设置完成！" -ForegroundColor Green
    Write-Host "\n接下来，您可以使用以下命令开始测试："
    Write-Host ""
    Write-Host "# 基本用法" -ForegroundColor Cyan
    Write-Host "adb shell CLASSPATH=$maximDir/monkey.jar:$maximDir/framework.jar \\"
    Write-Host "    exec app_process /system/bin tv.panda.test.monkey.Monkey \\"
    Write-Host "    -p $packageName \\"
    Write-Host "    --uiautomatormix \\"
    Write-Host "    --running-minutes 60 \\"
    Write-Host "    -v -v"
    Write-Host ""
    Write-Host "# 查看完整文档，请参考 README.md 文件" -ForegroundColor Yellow
}

# 主程序
Write-Host "\n🚀 Maxim 环境检测与设置工具 v1.0" -ForegroundColor Magenta
Write-Host "=" * 50

# 执行检查
Test-ADB
Test-DeviceConnected
$sdkVersion = Get-AndroidVersion
Initialize-MaximDirectory
Grant-Permissions -sdkVersion $sdkVersion

# 显示完成信息
Show-CompletionMessage
