# Automação de Tema Claro / Escuro para Windows (Sem Ativação)

Solução nativa, sem programas pesados em segundo plano, para alternar o tema do sistema e do seu navegador (Brave, Opera, Chrome, Edge, etc.) automaticamente por horário:

- **07:00** ➔ **Tema Claro** (personalizável)
- **18:00** ➔ **Tema Escuro** (personalizável)
- **Ao fazer Login / Ligar o PC** ➔ Detecta o horário e aplica o tema correto imediatamente.

---

## 💡 Como funciona no Windows Não Ativado?

O Windows não ativado bloqueia a interface visual de "Personalização" nas *Configurações*, mas **não bloqueia** alterações diretas no Registro do Usuário (`HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`):
- `AppsUseLightTheme`: Altera navegadores Chromium, explorador de arquivos e aplicativos.
- `SystemUsesLightTheme`: Altera a barra de tarefas e o menu iniciar.

Como o navegador está configurado para seguir o tema do **"Dispositivo" / "Sistema"**, ao alterar essas chaves, o navegador muda de aparência instantaneamente.

---

## 🚀 Como Instalar

Abra o **PowerShell** no Windows (não precisa ser como Administrador) na pasta deste projeto:

### 1. Com os horários padrão (07:00 claro / 18:00 escuro):
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### 2. Com horários personalizados (exemplo: 06:00 claro e 20:00 escuro):
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DayHour 6 -NightHour 20
```

O instalador irá:
1. Copiar o script para uma pasta persistente do seu usuário (`%USERPROFILE%\.theme-switcher`).
2. Criar 3 tarefas no **Agendador de Tarefas do Windows** (Horário diurno, noturno e no Logon).
3. Aplicar imediatamente o tema adequado para o horário atual.

---

## 🌐 Configuração no Navegador

Certifique-se de que a aparência do seu navegador está definida para acompanhar o sistema operacional:
- **Brave**: `brave://settings/appearance` ➔ **Cores do Brave** ➔ Selecione **"Mesmo que o Windows"** (ou *Same as Windows*).
- **Chrome**: `chrome://settings/appearance` ➔ Tema ➔ **"Padrão do dispositivo"**.
- **Opera**: `opera://settings/appearance` ➔ Tema ➔ **"Sistema"**.

---

## 🧪 Como Testar Manualmente

Se você quiser forçar a troca para testar sem esperar o horário:

- **Forçar Tema Claro:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode light
  ```

- **Forçar Tema Escuro:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode dark
  ```

- **Sincronizar com o horário atual:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode auto
  # ou passando horários específicos:
  powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode auto -DayHour 8 -NightHour 19
  ```

---

## 🗑️ Como Desinstalar

Caso queira remover as tarefas automáticas a qualquer momento:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```
