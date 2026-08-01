# Terraform Lab 3 — dependências e o grafo

**~1h**

## Objetivo
Entender como o Terraform decide a ordem das coisas.

## O que escrever
- `docker_network` e `docker_volume`
- O container referenciando ambos por atributo (ex: `docker_network.app.name`)
- Um `data` source lendo algo que já existe

## Rodar
```
terraform graph > graph.dot
```
Leia o `.dot` como texto, ou cole em https://dreampuf.github.io/GraphvizOnline

## O experimento
1. Remova a referência de atributo e substitua por `depends_on` explícito. Compare o grafo.
2. Volte para a referência implícita.

**Conclusão a anotar:** dependência implícita (por referência) é a regra;
`depends_on` é a exceção — para quando existe uma dependência real que o Terraform
não consegue ver na config (ex: uma IAM policy que precisa existir antes de um
serviço conseguir usá-la, sem que haja referência de atributo entre os dois).

## Quebre isto
Crie uma dependência circular: A referencia B e B referencia A. Leia o erro.

## Critério de conclusão
Você consegue apontar no grafo por que a rede é criada antes do container.

## Notas
