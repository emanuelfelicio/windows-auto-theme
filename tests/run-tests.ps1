<#
.SYNOPSIS
    Suíte de testes automatizados para o Theme Project.
.DESCRIPTION
    Executa testes estáticos de sintaxe e testes de lógica de horários.
    Quando a flag -Integration for especificada, executa testes de integração
    com o Registro e Agendador do Windows.
.PARAMETER Integration
    Habilita testes de integração com o sistema operacional.
#>
param(
    [switch]$Integration
)

$ErrorActionPreference = "Continue"
$passed = 0
$failed = 0

function Test-Case([string]$name, [scriptblock]$assert) {
    try {
        & $assert
        Write-Host "  [PASS] $name" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "  [FAIL] $name -> $_" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "  SUÍTE DE TESTES" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# -------------------------------------------------------------
# 1. ANÁLISE ESTÁTICA DE SINTAXE (AST Nativo do .NET)
# -------------------------------------------------------------
Write-Host "[1/2] Verificando integridade e sintaxe dos scripts (AST)..." -ForegroundColor Yellow

$scriptsToValidate = @("theme-agent.ps1", "setup.ps1")
foreach ($script in $scriptsToValidate) {
    $scriptFullPath = Join-Path $PSScriptRoot "..\$script"
    Test-Case "Sintaxe válida: $script" {
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptFullPath, [ref]$null, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            throw "Erro de sintaxe na linha $($parseErrors[0].Extent.StartLineNumber): $($parseErrors[0].Message)"
        }
    }
}

Test-Case "Launcher silencioso: run-hidden.vbs íntegro" {
    $vbsPath = Join-Path $PSScriptRoot "..\run-hidden.vbs"
    if (-not (Test-Path $vbsPath)) {
        throw "Arquivo run-hidden.vbs não encontrado no diretório do projeto."
    }
    $vbsContent = Get-Content $vbsPath -Raw
    if ($vbsContent -notmatch "WScript\.Shell" -or $vbsContent -notmatch "theme-agent\.ps1") {
        throw "Conteúdo de run-hidden.vbs inválido."
    }
}

# -------------------------------------------------------------
# 2. VALIDAÇÃO DA LÓGICA DE HORÁRIOS
# -------------------------------------------------------------
Write-Host "`n[2/2] Validando regras lógicas e limites de horários..." -ForegroundColor Yellow

# Função pura auxiliar que reproduz fielmente a lógica de decisão do theme-agent
function Resolve-Theme([int]$hour, [int]$dayHour = 7, [int]$nightHour = 18) {
    if ($dayHour -lt $nightHour) {
        $isDay = ($hour -ge $dayHour -and $hour -lt $nightHour)
    } else {
        $isDay = ($hour -ge $dayHour -or $hour -lt $nightHour)
    }
    if ($isDay) { return "light" } else { return "dark" }
}

Test-Case "Limite da Manhã: 07:00 com padrão 07h/18h deve ser 'light'" {
    $result = Resolve-Theme -hour 7 -dayHour 7 -nightHour 18
    if ($result -ne "light") { throw "Esperado 'light', obtido '$result'" }
}

Test-Case "Limite Anterior: 06:00 com padrão 07h/18h deve ser 'dark'" {
    $result = Resolve-Theme -hour 6 -dayHour 7 -nightHour 18
    if ($result -ne "dark") { throw "Esperado 'dark', obtido '$result'" }
}

Test-Case "Final da Tarde: 17:00 com padrão 07h/18h deve ser 'light'" {
    $result = Resolve-Theme -hour 17 -dayHour 7 -nightHour 18
    if ($result -ne "light") { throw "Esperado 'light', obtido '$result'" }
}

Test-Case "Limite da Noite: 18:00 com padrão 07h/18h deve ser 'dark'" {
    $result = Resolve-Theme -hour 18 -dayHour 7 -nightHour 18
    if ($result -ne "dark") { throw "Esperado 'dark', obtido '$result'" }
}

Test-Case "Madrugada: 00:00 e 03:00 devem ser 'dark'" {
    foreach ($h in @(0, 3)) {
        $result = Resolve-Theme -hour $h -dayHour 7 -nightHour 18
        if ($result -ne "dark") { throw "Esperado 'dark' às $h:00, obtido '$result'" }
    }
}

Test-Case "Horários Customizados: 09h às 21h (às 20h deve ser 'light')" {
    $result = Resolve-Theme -hour 20 -dayHour 9 -nightHour 21
    if ($result -ne "light") { throw "Esperado 'light', obtido '$result'" }
}

Test-Case "Turno Noturno Invertido: 22h às 06h (às 23h deve ser 'light')" {
    $result = Resolve-Theme -hour 23 -dayHour 22 -nightHour 6
    if ($result -ne "light") { throw "Esperado 'light', obtido '$result'" }
}

Test-Case "Turno Noturno Invertido: 22h às 06h (às 14h deve ser 'dark')" {
    $result = Resolve-Theme -hour 14 -dayHour 22 -nightHour 6
    if ($result -ne "dark") { throw "Esperado 'dark', obtido '$result'" }
}

# -------------------------------------------------------------
# 3. TESTES DE INTEGRAÇÃO COM O SISTEMA OPERACIONAL (Opcional via -Integration)
# -------------------------------------------------------------
if ($Integration) {
    Write-Host "`n[INTEGRAÇÃO] Executando testes contra o Registro e Agendador do SO..." -ForegroundColor Magenta

    # Teste de Registro usando Chave Sandbox segura
    $sandboxPath = "HKCU:\Software\ThemeSwitcher_TestSandbox"
    Test-Case "Registro do Windows: Criação, escrita DWORD e remoção de chave Sandbox" {
        try {
            # 1. Cria chave isolada
            if (-not (Test-Path $sandboxPath)) {
                New-Item -Path $sandboxPath -Force | Out-Null
            }

            # 2. Grava valores DWord de teste
            Set-ItemProperty -Path $sandboxPath -Name "TestThemeValue" -Value 0 -Type DWord
            $val0 = (Get-ItemProperty -Path $sandboxPath -Name "TestThemeValue").TestThemeValue
            if ($val0 -ne 0) { throw "Falha na escrita de DWORD 0 no Registro" }

            Set-ItemProperty -Path $sandboxPath -Name "TestThemeValue" -Value 1 -Type DWord
            $val1 = (Get-ItemProperty -Path $sandboxPath -Name "TestThemeValue").TestThemeValue
            if ($val1 -ne 1) { throw "Falha na escrita de DWORD 1 no Registro" }
        } finally {
            # 3. Limpeza garantida (Teardown)
            if (Test-Path $sandboxPath) {
                Remove-Item -Path $sandboxPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Teste de disponibilidade dos cmdlets do Agendador de Tarefas
    Test-Case "Agendador de Tarefas: Cmdlets Win32 disponíveis no ambiente" {
        $requiredCmdlets = @("Get-ScheduledTask", "Register-ScheduledTask", "Unregister-ScheduledTask", "New-ScheduledTaskTrigger", "New-ScheduledTaskAction", "New-ScheduledTaskSettingsSet")
        foreach ($cmd in $requiredCmdlets) {
            if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
                throw "Cmdlet obrigatório '$cmd' não encontrado neste ambiente Windows."
            }
        }
    }

    Test-Case "setup.ps1: registra no Agendador a tarefa auto com dois horários e logon" {
        $integrationTaskName = "ThemeSwitcher_Integration_$([guid]::NewGuid().ToString('N'))"
        $integrationDirectory = Join-Path $env:TEMP $integrationTaskName
        $setupPath = Join-Path $PSScriptRoot "..\setup.ps1"
        try {
            & $setupPath -ScheduledTaskName $integrationTaskName -InstallDirectory $integrationDirectory -SkipInitialSync -DayHour 7 -NightHour 18
            $task = Get-ScheduledTask -TaskName $integrationTaskName
            $triggerCount = $task.Triggers.Count
            $dailyStartBoundaries = @($task.Triggers | Where-Object { $_.CimClass.CimClassName -eq "MSFT_TaskDailyTrigger" } | ForEach-Object StartBoundary)
            $logonTriggerCount = @($task.Triggers | Where-Object { $_.CimClass.CimClassName -eq "MSFT_TaskLogonTrigger" }).Count
            $actionArguments = $task.Actions[0].Arguments

            if ($triggerCount -ne 3) { throw "Esperados 3 gatilhos, obtidos $triggerCount." }
            if ($logonTriggerCount -ne 1) { throw "Esperado 1 gatilho de logon, obtidos $logonTriggerCount." }
            if (($dailyStartBoundaries -join " ") -notmatch "T07:00:00" -or ($dailyStartBoundaries -join " ") -notmatch "T18:00:00") {
                throw "Os gatilhos diários registrados não contêm os horários 07:00 e 18:00."
            }
            if (-not $task.Settings.StartWhenAvailable) { throw "StartWhenAvailable não foi ativado." }
            if ($actionArguments -notmatch "-Mode auto" -or $actionArguments -match "-Mode (light|dark)") {
                throw "A ação registrada não está configurada para executar em modo auto."
            }
            if ($actionArguments -notmatch [regex]::Escape((Join-Path $integrationDirectory "run-hidden.vbs"))) {
                throw "A tarefa registrada não aponta para o launcher instalado pelo setup.ps1."
            }
            if (-not (Test-Path (Join-Path $integrationDirectory "theme-agent.ps1")) -or
                -not (Test-Path (Join-Path $integrationDirectory "run-hidden.vbs"))) {
                throw "setup.ps1 não copiou os arquivos para o diretório de instalação isolado."
            }
        } finally {
            $registeredTask = Get-ScheduledTask -TaskName $integrationTaskName -ErrorAction SilentlyContinue
            if ($registeredTask) {
                Unregister-ScheduledTask -InputObject $registeredTask -Confirm:$false
            }
            if (Test-Path $integrationDirectory) {
                Remove-Item -Path $integrationDirectory -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Teste de Broadcast Win32 (SendMessageTimeout via user32.dll)
    Test-Case "Broadcast Win32: Compilação P/Invoke e envio de WM_SETTINGCHANGE" {
        $signature = @"
using System;
using System.Runtime.InteropServices;
public class Win32ThemeNotifierIntegrationTest {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult
    );
}
"@
        if (-not ("Win32ThemeNotifierIntegrationTest" -as [type])) {
            Add-Type -TypeDefinition $signature -Language CSharp
        }
        $result = [UIntPtr]::Zero
        $ret = [Win32ThemeNotifierIntegrationTest]::SendMessageTimeout(
            [IntPtr]0xffff,
            0x001A,
            [UIntPtr]::Zero,
            "ImmersiveColorSet",
            2,
            200,
            [ref]$result
        )
        if ($ret -eq [IntPtr]::Zero) {
            throw "SendMessageTimeout retornou zero (falha no envio do broadcast)."
        }
    }
} else {
    Write-Host "`n[DICA] Para executar os testes de integração com o Registro e Agendador do SO, utilize:" -ForegroundColor DarkGray
    Write-Host "       powershell.exe -ExecutionPolicy Bypass -File tests/run-tests.ps1 -Integration" -ForegroundColor DarkGray
}

# -------------------------------------------------------------
# RESULTADO FINAL
# -------------------------------------------------------------
Write-Host "`n-------------------------------------------------------"
Write-Host "Resultado dos Testes: $passed passaram, $failed falharam." -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "-------------------------------------------------------`n"

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
