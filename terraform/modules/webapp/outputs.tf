output "url" {
  value = "http://localhost:${var.port}"
}

output "container_id" {
  value = docker_container.app.id
}
