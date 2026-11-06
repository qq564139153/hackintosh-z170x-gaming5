<#
.SYNOPSIS
  把仓库里的 OpenCore EFI 一键同步到 macOS 系统盘（PM991 NVMe）的 ESP。

.DESCRIPTION
  1. 列出仓库 OpenCore EFI\ 下所有 EFI 源，选一个（或用 -Build 指定）
  2. 列出全部硬盘与分区，按型号锁定目标盘的 EFI 系统分区，确认后临时分配盘符
  3. 备份 ESP 上现有的 EFI 到 _esp_backup\<时间戳>\EFI
  4. robocopy /MIR 镜像同步（会删除 ESP 上多余的旧 kext/驱动）
  5. 校验 config.plist 哈希一致，最后移除盘符
  ESP 根目录的 opencore-*.txt 日志不受影响（只镜像 EFI 文件夹）。

.EXAMPLE
  .\tools\deploy-efi.ps1                 # 交互选择 EFI 源
  .\tools\deploy-efi.ps1 -Build OS_26    # 按名称直接指定
  .\tools\deploy-efi.ps1 -WhatIf         # 只显示会改什么
  .\tools\deploy-efi.ps1 -CollectLogs    # 顺便把 ESP 上的 opencore 日志移到 Documents\黑苹果log
#>
[CmdletBinding()]
param(
    [string]$Build,
    [string]$DiskModel = 'MZ9LQ128',
    [switch]$WhatIf,
    [switch]$NoBackup,
    [switch]$CollectLogs,
    [switch]$Yes,
    [switch]$Pause
)

$ErrorActionPreference = 'Stop'
$EspGuid = '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
$ApfsGuid = '{7c3457ef-0000-11aa-aa11-00306543ecac}'
$PartTypeNames = @{
    $EspGuid                                 = 'EFI 系统分区'
    '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' = 'MSR'
    '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' = '基本数据'
    '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' = 'Windows 恢复'
    $ApfsGuid                                = 'APFS'
    '{48465300-0000-11aa-aa11-00306543ecac}' = 'HFS+'
}
$RepoRoot = Split-Path $PSScriptRoot -Parent
$EfiRoot = Join-Path $RepoRoot 'OpenCore EFI'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Pause')
    foreach ($k in $PSBoundParameters.Keys) {
        if ($k -eq 'Pause') { continue }
        $v = $PSBoundParameters[$k]
        if ($v -is [switch]) { if ($v) { $argList += "-$k" } }
        else { $argList += "-$k"; $argList += "`"$v`"" }
    }
    Write-Host '需要管理员权限，正在请求提权...' -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

function Invoke-DiskPart([string[]]$Lines) {
    $tmp = [IO.Path]::GetTempFileName()
    Set-Content -Path $tmp -Value $Lines -Encoding ASCII
    try { diskpart /s $tmp | Out-Null } finally { Remove-Item $tmp -Force }
}

function Format-Size([double]$Bytes) {
    if ($Bytes -ge 1GB) { '{0:N1} GB' -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { '{0:N0} MB' -f ($Bytes / 1MB) }
    else { '{0:N0} KB' -f ($Bytes / 1KB) }
}

function Get-EfiSources {
    Get-ChildItem $EfiRoot -Recurse -Filter config.plist -File |
        Where-Object { $_.Directory.Name -eq 'OC' -and $_.Directory.Parent.Name -eq 'EFI' } |
        ForEach-Object {
            $efi = $_.Directory.Parent
            $files = @(Get-ChildItem $efi.FullName -Recurse -File)
            [pscustomobject]@{
                Name     = $efi.Parent.Name
                Path     = $efi.FullName
                RelPath  = $efi.FullName.Substring($RepoRoot.Length + 1)
                Modified = ($files | Measure-Object LastWriteTime -Maximum).Maximum
                Kexts    = @(Get-ChildItem (Join-Path $efi.FullName 'OC\Kexts') -Directory -Filter *.kext -ErrorAction SilentlyContinue).Count
                Size     = ($files | Measure-Object Length -Sum).Sum
            }
        } | Sort-Object Name
}

function Select-EfiSource {
    $sources = @(Get-EfiSources)
    if ($sources.Count -eq 0) { throw "在 $EfiRoot 下没找到任何 EFI\OC\config.plist" }
    if ($Build) {
        $hit = @($sources | Where-Object { $_.Name -eq $Build -or $_.RelPath -like "*$Build*" })
        if ($hit.Count -eq 1) { return $hit[0] }
        Write-Host "-Build '$Build' 匹配到 $($hit.Count) 个源，改为手动选择" -ForegroundColor Yellow
    }
    Write-Host "`n===== 可用 EFI 源 =====" -ForegroundColor Cyan
    for ($i = 0; $i -lt $sources.Count; $i++) {
        $s = $sources[$i]
        Write-Host ("[{0}] {1,-8} 最后修改 {2:yyyy-MM-dd HH:mm}  kext {3,2} 个  {4,8}  {5}" -f ($i + 1), $s.Name, $s.Modified, $s.Kexts, (Format-Size $s.Size), $s.RelPath)
    }
    while ($true) {
        $ans = Read-Host "选择 EFI 源编号 (1-$($sources.Count))，Q 退出"
        if ($ans -match '^[qQ]$') { throw '已取消' }
        $n = 0
        if ([int]::TryParse($ans, [ref]$n) -and $n -ge 1 -and $n -le $sources.Count) { return $sources[$n - 1] }
    }
}

function Show-Disks($TargetDisk, $TargetPart) {
    Write-Host "`n===== 本机硬盘 =====" -ForegroundColor Cyan
    foreach ($d in (Get-Disk | Sort-Object Number)) {
        $tags = @()
        if ($d.IsBoot) { $tags += '启动盘' }
        if ($d.IsSystem) { $tags += '系统盘' }
        $isTarget = $TargetDisk -and $d.Number -eq $TargetDisk.Number
        if ($isTarget) { $tags += '<<< 目标' }
        $color = if ($isTarget) { 'Green' } else { 'Gray' }
        Write-Host ("磁盘 {0}  {1}  序列号 {2}  {3}  {4}  {5}  健康 {6}  {7}" -f `
                $d.Number, $d.FriendlyName, $d.SerialNumber.Trim(), (Format-Size $d.Size), $d.BusType, $d.PartitionStyle, $d.HealthStatus, ($tags -join ' ')) -ForegroundColor $color
        foreach ($p in (Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue)) {
            $type = $PartTypeNames[[string]$p.GptType]
            if (-not $type) { $type = if ($p.GptType) { $p.GptType } else { $p.Type } }
            $letter = if ($p.DriveLetter -and $p.DriveLetter -ne [char]0) { "$($p.DriveLetter):" } else { '--' }
            $vol = $null
            if ($letter -ne '--') { $vol = Get-Volume -DriveLetter $p.DriveLetter -ErrorAction SilentlyContinue }
            $volInfo = if ($vol) { "{0} {1} 剩余 {2}" -f $vol.FileSystem, $vol.FileSystemLabel, (Format-Size $vol.SizeRemaining) } else { '' }
            $mark = if ($TargetPart -and $isTarget -and $p.PartitionNumber -eq $TargetPart.PartitionNumber) { '<<< 写入此分区' } else { '' }
            $pc = if ($mark) { 'Green' } else { 'DarkGray' }
            Write-Host ("    分区 {0}  {1,-4} {2,10}  {3,-12} {4}  {5}" -f $p.PartitionNumber, $letter, (Format-Size $p.Size), $type, $volInfo, $mark) -ForegroundColor $pc
        }
    }
}

$letter = $null
$part = $null
$exitCode = 0
try {
    $src = Select-EfiSource
    $Source = $src.Path
    if (-not (Test-Path (Join-Path $Source 'OC\config.plist'))) { throw "源 EFI 不完整：$Source" }

    $disks = @(Get-Disk | Where-Object { $_.FriendlyName -like "*$DiskModel*" })
    if ($disks.Count -ne 1) {
        Show-Disks
        throw "按型号 '$DiskModel' 找到 $($disks.Count) 块盘，需要恰好 1 块（可用 -DiskModel 指定）"
    }
    $disk = $disks[0]
    $parts = @(Get-Partition -DiskNumber $disk.Number)
    $part = $parts | Where-Object { $_.GptType -eq $EspGuid } | Select-Object -First 1
    Show-Disks $disk $part

    if ($disk.IsBoot -or $disk.IsSystem) { throw "磁盘 $($disk.Number) 是 Windows 启动/系统盘，拒绝写入" }
    if (-not ($parts | Where-Object { $_.GptType -eq $ApfsGuid })) { throw "磁盘 $($disk.Number) 上没有 APFS 分区，不像 macOS 系统盘，拒绝写入" }
    if (-not $part) { throw "磁盘 $($disk.Number) 上没有 EFI 系统分区" }
    if ($src.Size -ge $part.Size) { throw "EFI 源 $(Format-Size $src.Size) 大于 ESP 容量 $(Format-Size $part.Size)" }

    Write-Host "`n===== 本次操作 =====" -ForegroundColor Cyan
    Write-Host ("源：  [{0}] {1}  ({2}，最后修改 {3:yyyy-MM-dd HH:mm})" -f $src.Name, $src.RelPath, (Format-Size $src.Size), $src.Modified)
    Write-Host ("目标：磁盘 {0}  {1}  {2}  序列号 {3} → 分区 {4} EFI 系统分区 {5}" -f `
            $disk.Number, $disk.FriendlyName, (Format-Size $disk.Size), $disk.SerialNumber.Trim(), $part.PartitionNumber, (Format-Size $part.Size)) -ForegroundColor Green
    if (-not $WhatIf -and -not $Yes) {
        if ((Read-Host '确认写入以上磁盘？输入 Y 继续') -ne 'Y') { throw '已取消' }
    }

    if ($part.DriveLetter -and $part.DriveLetter -ne [char]0) {
        $root = "$($part.DriveLetter):\"
        Write-Host "ESP 已挂载在 $root（结束后不卸载）"
    }
    else {
        $used = (Get-PSDrive -PSProvider FileSystem).Name
        $free = [char[]]([int][char]'Z'..[int][char]'G') | Where-Object { $used -notcontains [string]$_ } | Select-Object -First 1
        if (-not $free) { throw '没有空闲盘符' }
        $letter = [string]$free
        try {
            Add-PartitionAccessPath -DiskNumber $disk.Number -PartitionNumber $part.PartitionNumber -AccessPath "${letter}:\"
        }
        catch {
            Invoke-DiskPart @("select disk $($disk.Number)", "select partition $($part.PartitionNumber)", "assign letter=$letter")
        }
        $root = "${letter}:\"
        for ($i = 0; $i -lt 20 -and -not (Test-Path $root); $i++) { Start-Sleep -Milliseconds 250 }
        if (-not (Test-Path $root)) { throw "挂载 ESP 到 $root 失败" }
        Write-Host "已临时挂载 ESP 到 $root"
    }
    $espVol = Get-Volume -DriveLetter $root[0] -ErrorAction SilentlyContinue
    if ($espVol) {
        Write-Host ("ESP 卷：{0}  已用 {1} / 共 {2}" -f $espVol.FileSystem, (Format-Size ($espVol.Size - $espVol.SizeRemaining)), (Format-Size $espVol.Size))
    }

    $dest = Join-Path $root 'EFI'

    if ($WhatIf) {
        Write-Host "`n[WhatIf] 以下为将要发生的变更（未写入）：" -ForegroundColor Cyan
        robocopy $Source $dest /MIR /L /NJH /NP /NDL /R:1 /W:1 | Out-Host
    }
    else {
        if ((Test-Path $dest) -and -not $NoBackup) {
            $bk = Join-Path $RepoRoot ("_esp_backup\{0:yyyyMMdd-HHmmss}\EFI" -f (Get-Date))
            robocopy $dest $bk /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
            if ($LASTEXITCODE -ge 8) { throw "备份失败，robocopy 退出码 $LASTEXITCODE" }
            Write-Host "已备份旧 EFI → $bk"
        }

        robocopy $Source $dest /MIR /NJH /NP /NDL /R:1 /W:1 | Out-Host
        if ($LASTEXITCODE -ge 8) { throw "同步失败，robocopy 退出码 $LASTEXITCODE" }

        $h1 = (Get-FileHash (Join-Path $Source 'OC\config.plist')).Hash
        $h2 = (Get-FileHash (Join-Path $dest 'OC\config.plist')).Hash
        if ($h1 -ne $h2) { throw 'config.plist 校验不一致！' }
        Write-Host "`n部署完成：$($src.Name) → 磁盘 $($disk.Number) ESP，config.plist 哈希一致" -ForegroundColor Green
        Write-Host '提醒：改过 NVRAM / boot-args / layout-id 的话，开机在 OpenCore 里先 Reset NVRAM。' -ForegroundColor Yellow
    }

    if ($CollectLogs) {
        $logs = @(Get-ChildItem $root -Filter 'opencore-*.txt' -File)
        if ($logs.Count -eq 0) { Write-Host '没有 opencore 日志' }
        else {
            $logDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '黑苹果log'
            New-Item -ItemType Directory -Force -Path $logDir | Out-Null
            foreach ($f in $logs) {
                if ($WhatIf) { Write-Host "[WhatIf] 移动 $($f.Name) → $logDir"; continue }
                Move-Item $f.FullName (Join-Path $logDir $f.Name) -Force
            }
            Write-Host "已处理 $($logs.Count) 个 opencore 日志 → $logDir"
        }
    }
}
catch {
    Write-Host "`n失败：$($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}
finally {
    if ($letter -and $part) {
        try {
            Remove-PartitionAccessPath -DiskNumber $part.DiskNumber -PartitionNumber $part.PartitionNumber -AccessPath "${letter}:\"
        }
        catch {
            Invoke-DiskPart @("select disk $($part.DiskNumber)", "select partition $($part.PartitionNumber)", "remove letter=$letter")
        }
        Write-Host "已移除临时盘符 ${letter}:"
    }
    if ($Pause) { Read-Host '按回车关闭' | Out-Null }
}
exit $exitCode
