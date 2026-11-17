# Automação de Tema Claro / Escuro para Windows

Solução nativa para alternar o tema do sistema operacional e de navegadores (Brave, Chrome, Opera, Edge, etc.) automaticamente por horário:

- **07:00** ➔ **Tema Claro** (personalizável)
- **18:00** ➔ **Tema Escuro** (personalizável)
- **Ao fazer Login / Ligar o PC** ➔ Aplica o tema correspondente ao horário imediatamente.

As tarefas rodam em segundo plano de forma invisível via `wscript.exe`, sem abrir ou piscar janelas de terminal na tela.

---

## ⚡ Guia Rápido para Usuários

Abra o **PowerShell** na pasta do projeto e use os comandos abaixo:

### 1. Instalar a Automação
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```
*Por padrão, define 07:00 para tema Claro e 18:00 para tema Escuro.*

Se quiser **horários personalizados** (exemplo: Claro às 06:00 e Escuro às 20:00):
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DayHour 6 -NightHour 20
```

### 2. Verificar o Status
Para checar se as tarefas estão ativas no Agendador do Windows:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Status
```

### 3. Alternar Manualmente (Testar na hora)
Se quiser forçar a troca de tema imediatamente sem esperar o horário:
```powershell
# Forçar tema claro agora
powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode light

# Forçar tema escuro agora
powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode dark

# Recalcular e aplicar com base no horário atual
powershell -ExecutionPolicy Bypass -File .\theme-agent.ps1 -Mode auto
```

### 4. Desinstalar
Remove todas as tarefas agendadas e limpa os arquivos instalados:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Uninstall
```

---

## 📌 Como Funciona a Instalação (Cópia Estática)

Ao executar a instalação (`setup.ps1`), os scripts são **copiados fisicamente** para a pasta:
`C:\Users\<seu-usuario>\.theme-switcher\`

* **Independência:** O Agendador de Tarefas do Windows executa essa cópia local. Isso garante que a automação continue funcionando normalmente mesmo se você mover, renomear ou excluir a pasta onde baixou o projeto.
* **Atualização do código:** Se você fizer alterações manuais nos scripts dentro desta pasta do repositório, você deve rodar `setup.ps1` (ou `make install`) novamente para atualizar a cópia instalada no Windows.

---

## 🐧 Para Desenvolvedores no WSL / Linux (Uso do Makefile)

Se você utiliza o **WSL (Ubuntu / Debian)** e prefere gerenciar o projeto diretamente pelo terminal Linux, utilize o utilitário `make`:

> **Nota:** O `Makefile` foi criado exclusivamente para quem está no terminal WSL/Linux. Ele faz a ponte chamando o `powershell.exe` do Windows por baixo dos panos.

```bash
make install           # Instala as tarefas agendadas no Windows
make status            # Consulta o estado das tarefas
make uninstall         # Remove a automação e limpa os arquivos
make sync-light        # Força o tema Claro imediatamente
make sync-dark         # Força o tema Escuro imediatamente
make sync-auto         # Sincroniza com o horário atual
make test              # Executa os testes de sintaxe e lógica
make test-integration  # Executa testes com integração no Registro do Windows
```

---

## 🌐 Configuração no Navegador

Certifique-se de que a aparência do seu navegador está definida para acompanhar o sistema operacional:

- **Brave**: `brave://settings/appearance` ➔ **Cores do Brave** ➔ Selecione **"Mesmo que o Windows"**.
- **Chrome**: `chrome://settings/appearance` ➔ Tema ➔ **"Padrão do dispositivo"**.
- **Opera**: `opera://settings/appearance` ➔ Tema ➔ **"Sistema"**.
- **Edge**: `edge://settings/appearance` ➔ Tema geral ➔ **"Padrão do sistema"**.

---

## 🧪 Testes Automatizados

O projeto inclui validações sem dependências externas para conferir a integridade antes do uso:

- **No Windows (PowerShell):**
  ```powershell
  # Testes de sintaxe e lógica de horários
  powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1

  # Testes de integração com o Registro do Windows
  powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1 -Integration
  ```

- **No WSL (Linux):**
  ```bash
  make test
  make test-integration
  ```
