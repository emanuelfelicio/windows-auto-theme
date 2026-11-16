<#
.SYNOPSIS
    Gerencia a alternância de tema Claro/Escuro no Windows via Registro.
.DESCRIPTION
    Modifica as chaves HKCU correspondentes ao tema do sistema e dos aplicativos,
    contornando a restrição de personalização do Windows não ativado.
.PARAMETER Mode
    'light', 'dark' ou 'auto'. Padrão: 'auto'.
.PARAMETER DayHour
    Hora de início do tema claro (0 a 23). Padrão: 7 (07:00).
.PARAMETER NightHour
    Hora de início do tema escuro (0 a 23). Padrão: 18 (18:00).
#>
param(
    [ValidateSet('light', 'dark', 'auto')]
    [string]$Mode = 'auto',

    [ValidateRange(0, 23)]
    [int]$DayHour = 7,

    [ValidateRange(0, 23)]
    [int]$NightHour = 18
)

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

function Set-ThemeValues([int]$value) {
    # 0 = Escuro, 1 = Claro
    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $value -Type DWord
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $value -Type DWord
}

if ($Mode -eq 'auto') {
    $hour = (Get-Date).Hour
    
    # Determina se a hora atual está dentro do intervalo diurno
    if ($DayHour -lt $NightHour) {
        $isDay = ($hour -ge $DayHour -and $hour -lt $NightHour)
    } else {
        # Suporte caso o horário diurno cruze a meia-noite (caso incomum, mas previne bugs)
        $isDay = ($hour -ge $DayHour -or $hour -lt $NightHour)
    }

    if ($isDay) {
        $Mode = 'light'
    } else {
        $Mode = 'dark'
    }
}

if ($Mode -eq 'light') {
    Set-ThemeValues 1
} elseif ($Mode -eq 'dark') {
    Set-ThemeValues 0
}
