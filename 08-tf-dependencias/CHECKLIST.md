# Checklist — 08-tf-dependencias

- [ ] Criar `main.tf` com `docker_network`, `docker_volume`, `docker_container` (referência implícita)
- [ ] `terraform apply` OK
- [ ] `terraform graph > graph.dot` gerado e lido (ou visualizado no Graphviz online)
- [ ] Reescrevi usando `depends_on` explícito e comparei o grafo
- [ ] Voltei para a versão com referência de atributo (a correta)
- [ ] Conclusão sobre implícito vs `depends_on` anotada nas Notas
- [ ] Quebrei: criei `circular.tf` com dependência circular, li o erro `Cycle: ...`
- [ ] Apaguei `circular.tf` depois do teste
- [ ] Notas preenchidas no README
