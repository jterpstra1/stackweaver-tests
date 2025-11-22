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

resource "time_sleep" "wait_2_minutes" {
  create_duration = "2m"
}

# Make another resource depend on the sleep,
# this will give us time to see the run state in the UI
resource "null_resource" "after_wait" {
  depends_on = [time_sleep.wait_2_minutes]
  
  provisioner "local-exec" {
    command = "echo 'Waited 2 minutes!'"
  }
}