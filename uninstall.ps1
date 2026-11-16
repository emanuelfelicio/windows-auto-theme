<#
.SYNOPSIS
    Desinstalador da automação de tema Claro/Escuro.
.DESCRIPTION
    Remove as tarefas do Agendador do Windows e opcionalmente remove o script copiado.
#>

$tasks = @("AutoTheme_Day", "AutoTheme_Night", "AutoTheme_Logon")

Write-Host "==> Removendo tarefas do Agendador do Windows..." -ForegroundColor Cyan

foreach ($task in $tasks) {
    if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $task -Confirm:$false
        Write-Host "  [OK] Tarefa '$task' removida." -ForegroundColor Green
    } else {
        Write-Host "  [--] Tarefa '$task' não encontrada." -ForegroundColor Yellow
    }
}

$targetDir = Join-Path $env:USERPROFILE ".theme-switcher"
if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "==> Pasta '$targetDir' removida." -ForegroundColor Green
}

Write-Host "`n[SUCESSO] Automação desinstalada com sucesso!" -ForegroundColor Green
