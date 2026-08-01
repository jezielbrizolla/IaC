# Terraform Lab 4 — count vs for_each e lifecycle

**~1h · essencial**

## Objetivo
O experimento que ensina de vez por que `for_each` quase sempre ganha.

## Experimento 1 — count
1. Crie 3 containers a partir de uma lista `["a", "b", "c"]` usando `count`.
2. `apply`.
3. Agora **remova o do meio** (`"b"`) da lista.
4. `plan` — **não aplique ainda**. Leia com atenção: o Terraform quer
   **destruir e recriar** o terceiro, porque com `count` a identidade é o **índice**.
   Ao remover o índice 1, tudo depois dele "escorrega" uma posição.

## Experimento 2 — for_each
1. Refaça com `for_each = toset(["a", "b", "c"])`.
2. `apply`, remova o `"b"`, `plan`.
3. Agora **só o `"b"` é destruído**. Com `for_each` a identidade é a **chave**.

Anote a diferença com suas palavras. Isso cai na prova e, mais importante,
é a diferença entre um deploy tranquilo e um incidente em produção.

## Experimento 3 — lifecycle
- `create_before_destroy = true` — veja a ordem inverter no plan
- `prevent_destroy = true` — tente `destroy` e leia o erro
- `ignore_changes = [labels]` — mude o label e veja o plan ficar vazio

## Critério de conclusão
Você consegue explicar, sem consultar, quando `count` ainda é a escolha certa —
dica: quando são realmente "N cópias idênticas e intercambiáveis", sem identidade própria.

## Notas
