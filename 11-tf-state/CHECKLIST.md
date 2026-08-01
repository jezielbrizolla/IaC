# Checklist — 11-tf-state

- [ ] Base aplicada (`docker_container.app`)
- [ ] `terraform state list` / `state show` explorados
- [ ] Container `orfao` criado fora do Terraform
- [ ] `terraform import docker_container.orfao <id>` rodou
- [ ] Ajustei a config até `terraform plan` ficar vazio para `orfao`
- [ ] Testei também o bloco `import {}` + `-generate-config-out`
- [ ] Drift: `docker stop orfao` → `terraform plan` detectou
- [ ] Testei `-refresh-only` e entendi a diferença
- [ ] Renomeei `app` → `web`, vi o plan querer destruir/criar
- [ ] Resolvi com `terraform state mv`
- [ ] Resolvi (de novo, do zero) com bloco `moved {}`
- [ ] `terraform state rm docker_container.orfao` — confirmei que o container continua vivo
- [ ] Sei explicar a diferença entre `state rm` e `destroy`
- [ ] Limpeza final: `docker rm -f orfao` + `terraform destroy`
- [ ] Notas preenchidas no README
