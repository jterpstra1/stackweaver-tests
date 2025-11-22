# Generate a random ID for the server
resource "random_id" "server" {
  byte_length = 8
}

# Simulate a server deployment
resource "null_resource" "server" {
  triggers = {
    server_id   = random_id.server.hex
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Deploying server ${random_id.server.hex}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroying server ${self.triggers.server_id}'"
  }
}