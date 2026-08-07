# Docker Auto-Start Configuration

## Descrição

Este script configura o Docker Desktop para iniciar automaticamente sempre que você fizer login no Windows, usando o Task Scheduler. A tarefa verifica se o Docker já está rodando antes de tentar iniciar, evitando duplicação.

## Como Usar

### Pré-requisitos
- Docker Desktop instalado
- Executar como Administrador

### Execução

```powershell
# Navegue até o diretório do script
cd automation\setup\steps

# Execute o script como Administrador
.\setup-docker-autostart.ps1
```

### Preciso reiniciar agora?

**Sim!** O script é completamente automático e não inicia o Docker imediatamente. Você precisa:

1. **Reiniciar o computador** - O Docker iniciará automaticamente no login
2. Ou inicie o Docker manualmente agora se precisar usar imediatamente

A tarefa já está configurada e funcionará no próximo login.

### O que o script faz

1. **Verifica** se o Docker Desktop está instalado nos locais padrão:
   - `%LOCALAPPDATA%\Docker\Docker Desktop\Docker Desktop.exe`
   - `C:\Program Files\Docker\Docker\Docker Desktop.exe`
2. **Cria** um script wrapper (`start-docker-if-needed.ps1`) que:
   - Verifica se o processo "Docker Desktop" já está rodando
   - Verifica se o serviço "com.docker.service" já está rodando
   - Só inicia o Docker se não estiver rodando
   - Cria logs em `%TEMP%\docker-autostart.log`
3. **Remove** qualquer tarefa existente com o mesmo nome
4. **Cria** uma tarefa no Task Scheduler que:
   - Executa o script wrapper no login do usuário atual
   - Tenta reiniciar até 3 vezes se falhar (intervalo de 1 minuto)
   - Não para se o computador estiver usando bateria
   - Executa com nível de privilégio mais alto
   - Tempo limite de execução: 5 minutos

## Verificação

Para verificar se a tarefa foi criada corretamente:

```powershell
Get-ScheduledTask -TaskName "Docker Desktop Auto-Start"
```

Para ver os detalhes da tarefa:

```powershell
Get-ScheduledTaskInfo -TaskName "Docker Desktop Auto-Start"
```

### Verificar os Logs

O script wrapper cria logs em `%TEMP%\docker-autostart.log`. Para ver os logs:

```powershell
Get-Content $env:TEMP\docker-autostart.log
```

### Verificar o Script Wrapper

O script `start-docker-if-needed.ps1` é criado no mesmo diretório do script principal. Você pode executá-lo manualmente para testar:

```powershell
.\start-docker-if-needed.ps1
```

## Remoção

Se quiser remover a tarefa:

```powershell
Unregister-ScheduledTask -TaskName "Docker Desktop Auto-Start" -Confirm:$false
```

## Alternativa: Startup Folder

Se preferir usar a pasta de Startup (método mais simples mas menos robusto):

1. Pressione `Win + R`
2. Digite `shell:startup` e pressione Enter
3. Crie um atalho para `Docker Desktop.exe`
4. O caminho geralmente é: `%LOCALAPPDATA%\Docker\Docker Desktop\Docker Desktop.exe`

## Notas

- O script usa o Task Scheduler que é mais robusto que a pasta de Startup
- A tarefa é configurada para o usuário atual apenas
- O Docker Desktop será iniciado em background (minimizado)
