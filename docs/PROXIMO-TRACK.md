# Próximo Track — provisionamento multi-cloud + nuvem privada local

Documento de handoff. Objetivo: servir de entrada para outra sessão (Claude
web) desenhar o próximo track em detalhe — não é o plano detalhado em si,
é o contexto e o escopo que esse plano precisa respeitar.

## Onde isso se encaixa

O repo já tem um Track 0 (`labs/`, ver [TODO.md](../TODO.md)) cobrindo Packer
e Terraform local-first, do zero até um mini-cluster Kubernetes replicando a
stack de SRE do JZ (Bloco 5, "mini-KOB": cluster + Vault + PostgreSQL). Esse
track é a **base de conceitos** — variável, state, módulo, dependência,
`for_each`, provider. Está em andamento: Blocos 0–1 completos, Bloco 2
(Terraform core) em progresso.

Este documento descreve o **próximo track**, que vem depois da base estar
fechada. Não substitui o Track 0 nem duplica seu conteúdo — assume que quem
chegar aqui já passou pelos módulos, pelo state, pelo `for_each` como
identidade de tenant.

## Meta imediata (antes de começar o próximo track)

- Terminar os labs de Terraform que faltam no Bloco 2: **10 (módulos)** e
  **11 (state — import, drift, `moved`, `state rm`)**.
- Meta: até sexta-feira desta semana. Não é promessa, é alvo.
- Lab 10 é o mais importante dos dois pro que vem a seguir — é onde
  container+rede+volume viram módulo reutilizável, chamado duas vezes com
  inputs diferentes. É o padrão que o próximo track escala pra múltiplos
  provedores.

## O que vem depois — objetivo declarado pelo JZ

> "quero criar tenant do azure, aws, oracle, e criar um gerenciador local.
> onde acesso e provisiono a infra, tanto local no meu PC (nuvem privada),
> como também na pública... quero fazer isso, pois assim eu simulo de fato
> o que tem no ambiente da empresa... menos a parte de baremetal, mas isso
> não me importa por agora."

Traduzindo em escopo:

1. **Provisionamento de tenant em três nuvens públicas**: AWS, Azure,
   Oracle Cloud (OCI). Terraform com um provider por nuvem, reaproveitando
   o padrão de módulo do Lab 10 — mesma estrutura de módulo, backend/provider
   trocado por variável de entrada.
2. **Nuvem privada local**: o Bloco 4 do Track 0 já cobre Hyper-V
   (`hyperv-iso` + provider Terraform `taliesins/hyperv`) — isso *é* a peça
   de nuvem privada, não precisa recomeçar do zero. O que falta é o próximo
   item.
3. **Um "gerenciador local"** — camada única de acesso/provisionamento que
   fala com as quatro superfícies (Hyper-V local + AWS + Azure + OCI) sem o
   JZ precisar trocar de ferramenta/contexto por provedor. Isso ainda não
   tem forma definida — é a pergunta central pra próxima sessão de
   planejamento (ver "Perguntas em aberto").
4. **Fora de escopo por enquanto**: baremetal (Redfish/PXE/MAAS já estava
   anotado como gap conhecido no backlog do Track 0 — segue fora).

## Por que isso importa (contexto de carreira)

A descrição da vaga-alvo (`descricao-vaga-infra-automation.md`, fora deste
repo) pede explicitamente: *"experiência prática aprofundada com plataformas
de nuvem pública (AWS, Azure, GCP e OCI)"* e *"plataformas de automação de
infraestrutura self-service para provisionamento... por meio de frameworks
reutilizáveis de infraestrutura como código"*. Este track não é um desvio do
objetivo — é a continuação direta dele, na direção que a vaga pede: cobrir
múltiplas nuvens públicas e demonstrar um framework de self-service, não só
um provider.

GCP não foi mencionado pelo JZ neste escopo (citou Azure, AWS, Oracle) — vale
a próxima sessão confirmar se é omissão ou decisão consciente de deixar GCP
de fora por agora.

## Contexto que a próxima sessão de planejamento precisa herdar

- **Estilo de trabalho:** tutorial guiado, não quiz socrático. Primeira vez
  manual com ajuda, só depois automatiza. Quem roda comando de lab é o JZ,
  não a IA — a IA explica, revisa, e valida HCL/config antes de entregar
  (rodando `init`/`validate`/`plan` num diretório de teste isolado, nunca no
  ambiente real do JZ).
- **Cadência:** 5–10h/semana, sessão longa de fim de semana + blocos curtos
  durante a semana.
- **Custo:** local-first sempre que possível. Há ~US$100 de créditos Azure
  disponíveis (mencionados no backlog do Track 0). AWS e OCI têm free tier —
  a próxima sessão deve mapear os limites de cada um antes de desenhar labs
  que possam gerar cobrança.
- **Formato de entrega:** README por lab com objetivo, código, "quebre isto"
  e critério de conclusão — mesmo padrão do Track 0. Tracker único (estilo
  `TODO.md`) em vez de checklist espalhado.
- **Regra de conteúdo:** nada de comando ou HCL entregue sem ter sido
  validado antes (mesmo que só `validate`/`plan`, não `apply` — apply real
  em nuvem paga é decisão do JZ, não default).

## Perguntas em aberto (a próxima sessão deve resolver antes de montar o plano)

1. **O que é o "gerenciador local"?** Um CLI próprio? Um backend
   Terraform remoto rodando localmente (ex: self-hosted, tipo o que o
   Terraform Cloud faz, mas local)? Uma UI web fina em cima de
   `terraform apply` parametrizado? Isso determina se o próximo track é
   "só" Terraform multi-provider ou se inclui uma camada de aplicação nova.
2. **Isolamento de state por provedor/tenant:** o Lab 11 (state) e o Lab 13
   (ambientes) do Track 0 já tocam nisso para um único provider — o novo
   track precisa decidir se cada nuvem tem seu próprio backend de state ou
   se existe um backend central com workspace por tenant×provider.
3. **Credenciais:** como o "gerenciador local" autentica nas três nuvens
   sem credencial hardcoded — Vault (já usado no Bloco 5 do Track 0) é
   candidato natural pra reaproveitar.
4. **Nível de paridade entre as três nuvens:** replicar o mesmo workload
   (ex: rede + storage + 1 VM) nas três, ou cada uma testa um serviço
   diferente? Paridade ajuda a comparar provider a provider (o "de-para" que
   já existe no Bloco 4 do Track 0 pra Hyper-V→AWS→Azure).

## Como usar este documento

Colar em uma sessão nova (Claude web ou outro) junto com o pedido de montar
o plano detalhado, block por block, no mesmo formato do Track 0. Este
arquivo fica no repo como registro de decisão — não é o plano final.
