# Próximo Track — provisionamento multi-cloud + nuvem privada local

Documento de handoff. Objetivo: servir de entrada para outra sessão (Claude
web) desenhar o próximo track em detalhe — não é o plano detalhado em si,
é o contexto e o escopo que esse plano precisa respeitar.

## Onde isso se encaixa

O repo já tem um Track 0 (`labs/`, ver [TODO.md](../TODO.md)) cobrindo Packer
e Terraform local-first, do zero até um mini-cluster Kubernetes replicando a
stack de SRE do JZ (Bloco 5, "mini-KOB": cluster + Vault + PostgreSQL). Esse
track é a **base de conceitos** — variável, state, módulo, dependência,
`for_each`, provider. Status em 2026-08-08: Blocos 0–3 completos (setup,
Packer, Terraform core, capstone), Bloco 4 (Windows/Hyper-V) em andamento
(Lab 15 em progresso).

Este documento descreve o **próximo track**, que vem depois da base estar
fechada. Não substitui o Track 0 nem duplica seu conteúdo — assume que quem
chegar aqui já passou pelos módulos, pelo state, pelo `for_each` como
identidade de tenant.

## Meta imediata (antes de começar o próximo track)

*(atualizado em 2026-08-08 — a versão anterior desta seção, sobre Labs 10/11,
já foi cumprida)*

- Terminar o Bloco 4 (Windows/Hyper-V, Labs 15–18) e o Bloco 5 (Kubernetes,
  Labs 19–22) — fecha o Track 0 inteiro.
- Lab 15 está em andamento: build de golden image Windows Server via
  `hyperv-iso`, com licença de Volume License (benefício Visual Studio
  subscription/Dell) — sem `<ProductKey>` no `Autounattend.xml` por enquanto,
  porque mídia VL normalmente já embute a KMS client setup key (não pede
  chave no setup; ativa via KMS depois — confirmado pela experiência real do
  JZ com SCCM).

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
5. **Novo eixo registrado em 2026-08-08 (ao trabalhar no Lab 17):** golden
   images para múltiplas superfícies — Linux via Hyper-V (não só Docker,
   que já é coberto nos Labs 01-14), e imagens que sirvam de base pra
   infra on-prem real (KOB, ESXi/VMware). Isso é **on-prem**, diferente do
   eixo multi-cloud público (item 1) — um terceiro eixo, não uma variação
   dele. Ainda sem forma definida: um builder Packer por plataforma
   (`hyperv-iso` pra Hyper-V, algo tipo `vsphere-iso` pra ESXi), resposta
   de instalação por OS (`Autounattend.xml` pra Windows já coberto;
   cloud-init/preseed/kickstart pra Linux, ainda não testado neste repo).
   Multi-versão Windows (2022/2025/Win11) dentro do Hyper-V já está em
   andamento no Lab 17 (mesmo padrão do Lab 04, multi-source por variável)
   — o gap real é especificamente Linux-via-Hyper-V e a camada ESXi.

**Moldura adicional (2026-08-08):** o JZ descreveu o objetivo como construir
uma **réplica pessoal do ciclo de vida completo** de um gerenciador de nuvem
corporativo — provisionar, autenticar, operar, em múltiplos provedores mais
o ambiente local — pra entender o "end to end" na prática, não só cada peça
isolada. Ele referenciou uma ferramenta interna da Dell como o tipo de coisa
que quer entender por dentro (este documento **não** descreve nem especula
sobre como essa ferramenta funciona — não é informação disponível aqui,
só o objetivo de aprendizado que ela inspira). Isso reforça por que os itens
1–3 acima precisam se comportar como uma plataforma coesa (provisionamento +
autenticação + operação), não como três labs isolados de provider.

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
3. **Credenciais — respondida em 2026-08-08:** Vault open-source, local,
   via Docker (`docker run hashicorp/vault` com volume persistente, ou o
   padrão já usado no Lab 21 dentro do K8s). Confirmado pelo JZ como
   necessário assim que o gerenciador existir. Vale usar os *secrets
   engines* dinâmicos do Vault para AWS/Azure/GCP (credencial temporária
   gerada sob demanda) em vez de token estático guardado — é mais próximo
   do padrão real de produção e vira conteúdo de lab por si só. Ainda em
   aberto: Vault standalone (fora do K8s, mais simples) vs. reaproveitar o
   Vault do Lab 21 (dentro do cluster) — decidir quando desenhar o
   gerenciador em detalhe.
4. **Nível de paridade entre as três nuvens:** replicar o mesmo workload
   (ex: rede + storage + 1 VM) nas três, ou cada uma testa um serviço
   diferente? Paridade ajuda a comparar provider a provider (o "de-para" que
   já existe no Bloco 4 do Track 0 pra Hyper-V→AWS→Azure).

## Como usar este documento

Colar em uma sessão nova (Claude web ou outro) junto com o pedido de montar
o plano detalhado, block por block, no mesmo formato do Track 0. Este
arquivo fica no repo como registro de decisão — não é o plano final.
