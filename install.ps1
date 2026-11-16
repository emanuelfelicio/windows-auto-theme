<#
.SYNOPSIS
    Instalador da automação de tema Claro/Escuro para Windows.
.DESCRIPTION
    Copia o script para o diretório do usuário e registra 3 tarefas no Agendador do Windows:
    - DayHour (padrão 07:00): Ativa tema claro
    - NightHour (padrão 18:00): Ativa tema escuro
    - Ao fazer login: Sincroniza o tema correto com base no horário atual
.PARAMETER DayHour
    Hora do dia para ativar o tema claro (0 a 23). Padrão: 7.
.PARAMETER NightHour
    Hora do dia para ativar o tema escuro (0 a 23). Padrão: 18.
#>
param(
    [ValidateRange(0, 23)]
    [int]$DayHour = 7,

    [ValidateRange(0, 23)]
    [int]$NightHour = 18
)

$ErrorActionPreference = "Stop"

# Formatação das horas no formato HH:00
$dayTimeStr   = "{0:D2}:00" -f $DayHour
$nightTimeStr = "{0:D2}:00" -f $NightHour

$targetDir    = Join-Path $env:USERPROFILE ".theme-switcher"
$targetScript = Join-Path $targetDir "theme-agent.ps1"
$sourceScript = Join-Path $PSScriptRoot "theme-agent.ps1"

Write-Host "==> Configurando pasta em: $targetDir" -ForegroundColor Cyan
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

Copy-Item -Path $sourceScript -Destination $targetScript -Force
Write-Host "==> Script copiado para: $targetScript" -ForegroundColor Green

# Definição das ações e tarefas
$psExe = "powershell.exe"
$commonArgs = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetScript`""

$actionLight = New-ScheduledTaskAction -Execute $psExe -Argument "$commonArgs -Mode light"
$actionDark  = New-ScheduledTaskAction -Execute $psExe -Argument "$commonArgs -Mode dark"
$actionAuto  = New-ScheduledTaskAction -Execute $psExe -Argument "$commonArgs -Mode auto -DayHour $DayHour -NightHour $NightHour"

# Disparadores (Triggers)
$triggerLight = New-ScheduledTaskTrigger -Daily -At $dayTimeStr
$triggerDark  = New-ScheduledTaskTrigger -Daily -At $nightTimeStr
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Configurações adicionais (garantir execução se perder o horário e suporte à bateria)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Registro das tarefas
Write-Host "==> Registrando tarefas no Agendador do Windows..." -ForegroundColor Cyan

Register-ScheduledTask -TaskName "AutoTheme_Day"   -Action $actionLight -Trigger $triggerLight -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa matutina criada ($dayTimeStr -> Tema Claro)" -ForegroundColor Green

Register-ScheduledTask -TaskName "AutoTheme_Night" -Action $actionDark  -Trigger $triggerDark  -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa noturna criada ($nightTimeStr -> Tema Escuro)" -ForegroundColor Green

Register-ScheduledTask -TaskName "AutoTheme_Logon" -Action $actionAuto  -Trigger $triggerLogon -Settings $settings -Force | Out-Null
Write-Host "  [OK] Tarefa de logon criada (Ajuste imediato ao ligar)" -ForegroundColor Green

# Executar imediatamente para ajustar o tema atual
Write-Host "`n==> Aplicando tema correspondente ao horário atual..." -ForegroundColor Cyan
& $psExe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$targetScript" -Mode auto -DayHour $DayHour -NightHour $NightHour

Write-Host "`n[SUCESSO] Automação instalada com sucesso!" -ForegroundColor Green
Write-Host "Seu navegador (e o Windows) agora alternarão automaticamente:"
Write-Host "  - $dayTimeStr: Claro"
Write-Host "  - $nightTimeStr: Escuro"
