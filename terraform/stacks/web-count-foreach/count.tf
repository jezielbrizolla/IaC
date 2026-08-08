variable "apps" {
  type    = set(string)
  default = ["d", "b", "c"]
}

resource "docker_container" "app" {
  for_each = var.apps
  name     = "lab09-${each.key}"
  image    = docker_image.nginx.image_id

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image]
  }
}