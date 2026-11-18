# Alternância automática do tema do dispositivo no Windows

Aplicativos e navegadores configurados para usar o tema do dispositivo acompanham a aparência do Windows. Este projeto automatiza a mudança do tema do Windows para que esses aplicativos também alternem entre claro e escuro sem ajustes manuais:

- **07:00** ➔ **Tema Claro** (personalizável)
- **18:00** ➔ **Tema Escuro** (personalizável)
- **Ao fazer Login / Ligar o PC** ➔ Aplica o tema correspondente ao horário imediatamente.

Uma única tarefa (`AutoTheme`) roda nos dois horários e no logon. Se um horário diário for perdido, `StartWhenAvailable` pode iniciar a tarefa depois; ela consulta a hora atual e escolhe o tema correto.

A tarefa roda em segundo plano de forma invisível via `wscript.exe`, sem abrir ou piscar janelas de terminal na tela.

---

## ⬇️ Download

1. Acesse a página de [**Releases**](../../releases/latest) do repositório.
2. Baixe o arquivo `win-theme-switcher-vX.X.X.zip`.
3. Extraia em qualquer pasta.
4. Abra o PowerShell na pasta extraída e execute:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1
   ```

Se estiver atualizando uma instalação anterior, remova manualmente as tarefas `AutoTheme_Day`, `AutoTheme_Night` e `AutoTheme_Logon` no Agendador do Windows antes de instalar. A versão atual registra somente `AutoTheme`.

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

## Licença e marcas

O código deste projeto é dedicado ao domínio público sob a [Unlicense](UNLICENSE). O pacote não inclui binários, logos nem imagens da Microsoft; ele usa APIs disponíveis no Windows. Windows é uma marca da Microsoft Corporation. Este projeto é independente e não é afiliado nem endossado pela Microsoft.
