<#
.SYNOPSIS
    Gerenciador de Ciclo de Vida da Automação de Temas (Instalação, Desinstalação e Status).
.DESCRIPTION
    Script unificado responsável por instalar, desinstalar e consultar as tarefas
    agendadas no Windows Task Scheduler, compartilhando variáveis e configurações centralizadas.
.PARAMETER Uninstall
    Remove as tarefas agendadas e limpa os arquivos instalados no perfil do usuário.
.PARAMETER Status
    Consulta e exibe o estado atual das tarefas no Agendador do Windows.
.PARAMETER DayHour
    Hora do dia para ativar o tema claro (0 a 23). Padrão: 7 (07:00).
.PARAMETER NightHour
    Hora do dia para ativar o tema escuro (0 a 23). Padrão: 18 (18:00).
#>
param(
    [switch]$Uninstall,
    [switch]$Status,

    [ValidateRange(0, 23)]
    [int]$DayHour = 7,

    [ValidateRange(0, 23)]
    [int]$NightHour = 18
)

$ErrorActionPreference = "Stop"

# === Configurações Centralizadas ===
$targetDir      = Join-Path $env:USERPROFILE ".theme-switcher"
$targetScript   = Join-Path $targetDir "theme-agent.ps1"
$targetLauncher = Join-Path $targetDir "run-hidden.vbs"
$sourceScript   = Join-Path $PSScriptRoot "theme-agent.ps1"
$sourceLauncher = Join-Path $PSScriptRoot "run-hidden.vbs"
$taskNames      = @("AutoTheme_Day", "AutoTheme_Night", "AutoTheme_Logon")

# -------------------------------------------------------------
# 1. CONSULTA DE STATUS (-Status)
# -------------------------------------------------------------
if ($Status) {
    Write-Host "`n==> Verificando status das tarefas no Windows..." -ForegroundColor Cyan
    $foundAny = $false
    foreach ($task in $taskNames) {
        $taskObj = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        if ($taskObj) {
            $foundAny = $true
            Write-Host "  [OK] $task -> Estado: $($taskObj.State)" -ForegroundColor Green
        } else {
            Write-Host "  [--] $task -> Não instalada" -ForegroundColor Yellow
        }
    }

    $installedScript = Test-Path $targetScript
    $installedLauncher = Test-Path $targetLauncher
    Write-Host "  Script persistente: $(if ($installedScript) { 'Presente em ' + $targetDir } else { 'Não encontrado' })" -ForegroundColor $(if ($installedScript) { "Green" } else { "Yellow" })
    Write-Host "  Launcher invisível: $(if ($installedLauncher) { 'Presente em ' + $targetLauncher } else { 'Não encontrado' })" -ForegroundColor $(if ($installedLauncher) { "Green" } else { "Yellow" })
    exit 0
}

# -------------------------------------------------------------
# 2. DESINSTALAÇÃO (-Uninstall)
# -------------------------------------------------------------
if ($Uninstall) {
    Write-Host "`n==> Desinstalando automação de temas..." -ForegroundColor Cyan

    foreach ($task in $taskNames) {
        if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false
            Write-Host "  [OK] Tarefa '$task' removida." -ForegroundColor Green
        } else {
            Write-Host "  [--] Tarefa '$task' não estava registrada." -ForegroundColor DarkGray
        }
    }

    if (Test-Path $targetDir) {
        Remove-Item -Path $targetDir -Recurse -Force
        Write-Host "  [OK] Diretório '$targetDir' removido." -ForegroundColor Green
    }

    Write-Host "`n[SUCESSO] Desinstalação concluída com sucesso!" -ForegroundColor Green
    exit 0
}

# -------------------------------------------------------------
# 3. INSTALAÇÃO (Padrão)
# -------------------------------------------------------------
Write-Host "`n==> Instalando automação de temas..." -ForegroundColor Cyan

# Formatação dos horários
$dayTimeStr   = "{0:D2}:00" -f $DayHour
$nightTimeStr = "{0:D2}:00" -f $NightHour

# Cria pasta se necessário e copia os arquivos
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
Copy-Item -Path $sourceScript -Destination $targetScript -Force
Copy-Item -Path $sourceLauncher -Destination $targetLauncher -Force
Write-Host "  [OK] Script e Launcher copiados para: $targetDir" -ForegroundColor Green

# Definição de execução via wscript (sem flash de console)
$wscriptExe = "wscript.exe"

$actionLight = New-ScheduledTaskAction -Execute $wscriptExe -Argument "`"$targetLauncher`" -Mode light"
$actionDark  = New-ScheduledTaskAction -Execute $wscriptExe -Argument "`"$targetLauncher`" -Mode dark"
$actionAuto  = New-ScheduledTaskAction -Execute $wscriptExe -Argument "`"$targetLauncher`" -Mode auto -DayHour $DayHour -NightHour $NightHour"

$triggerLight = New-ScheduledTaskTrigger -Daily -At $dayTimeStr
$triggerDark  = New-ScheduledTaskTrigger -Daily -At $nightTimeStr
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Registro das tarefas
Register-ScheduledTask -TaskName "AutoTheme_Day"   -Action $actionLight -Trigger $triggerLight -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa matutina registrada ($dayTimeStr -> Claro)" -ForegroundColor Green

Register-ScheduledTask -TaskName "AutoTheme_Night" -Action $actionDark  -Trigger $triggerDark  -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa noturna registrada ($nightTimeStr -> Escuro)" -ForegroundColor Green

Register-ScheduledTask -TaskName "AutoTheme_Logon" -Action $actionAuto  -Trigger $triggerLogon -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa de logon registrada (Ajuste imediato ao ligar)" -ForegroundColor Green

# Execução imediata para sincronizar
Write-Host "`n==> Aplicando tema correspondente ao horário atual..." -ForegroundColor Cyan
Start-Process -FilePath $wscriptExe -ArgumentList "`"$targetLauncher`" -Mode auto -DayHour $DayHour -NightHour $NightHour"

Write-Host "`n[SUCESSO] Instalação concluída!" -ForegroundColor Green
Write-Host "  - Claro: $dayTimeStr"
Write-Host "  - Escuro: $nightTimeStr"
