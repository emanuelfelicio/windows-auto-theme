# Makefile para usuários de WSL / Linux
# Permite testar, gerenciar e executar a automação do Windows diretamente do terminal Linux.
#
# NOTA SOBRE A INSTALAÇÃO ESTÁTICA:
# O comando 'make install' copia fisicamente os scripts para a pasta 'C:\Users\<usuario>\.theme-switcher'.
# As tarefas agendadas no Windows apontam para essa cópia independente.
# Portanto, caso você edite os scripts neste repositório, execute 'make install' novamente
# para que o Windows passe a utilizar a sua versão atualizada.

PWSH = powershell.exe -NoProfile -ExecutionPolicy Bypass

.PHONY: help test test-integration install uninstall status sync-light sync-dark sync-auto

help:
	@echo "Comandos disponíveis (WSL / Linux):"
	@echo "  make test              - Executa testes unitários e validação de sintaxe"
	@echo "  make test-integration  - Executa testes com integração no Registro do Windows"
	@echo "  make install           - Instala a automação no Windows (07:00 / 18:00)"
	@echo "  make uninstall         - Remove a automação e limpa os arquivos"
	@echo "  make status            - Consulta o estado das tarefas no Windows"
	@echo "  make sync-light        - Força o tema Claro imediatamente"
	@echo "  make sync-dark         - Força o tema Escuro imediatamente"
	@echo "  make sync-auto         - Sincroniza o tema com o horário atual"

test:
	$(PWSH) -File tests/run-tests.ps1

test-integration:
	$(PWSH) -File tests/run-tests.ps1 -Integration

install:
	$(PWSH) -File setup.ps1

uninstall:
	$(PWSH) -File setup.ps1 -Uninstall

status:
	$(PWSH) -File setup.ps1 -Status

sync-light:
	$(PWSH) -File theme-agent.ps1 -Mode light

sync-dark:
	$(PWSH) -File theme-agent.ps1 -Mode dark

sync-auto:
	$(PWSH) -File theme-agent.ps1 -Mode auto
