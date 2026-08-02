output "url" {
  value = "http://localhost:${var.external_port}"
}

output "container_id" {
  value = docker_container.web.id
}
