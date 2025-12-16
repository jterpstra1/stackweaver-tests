# Generate a random ID for the server
resource "random_id" "server" {
  byte_length = 8
}


# Create 10 resources that each take ~20 seconds to apply
# This allows testing real-time polling and status updates during apply


resource "time_sleep" "resource_1" {
  create_duration = "5s"
}

resource "null_resource" "resource_1" {
  depends_on = [time_sleep.resource_1]
  
  provisioner "local-exec" {
    command = "echo 'Resource 1 created'"
  }
}

resource "time_sleep" "resource_2" {
  create_duration = "10s"
}

resource "null_resource" "resource_2" {
  depends_on = [time_sleep.resource_2]
  
  provisioner "local-exec" {
    command = "echo 'Resource 2 created'"
  }
}

resource "time_sleep" "resource_3" {
  create_duration = "15s"
}

resource "null_resource" "resource_3" {
  depends_on = [time_sleep.resource_3]
  
  provisioner "local-exec" {
    command = "echo 'Resource 3 created'"
  }
}

resource "time_sleep" "resource_4" {
  create_duration = "20s"
}

resource "null_resource" "resource_4" {
  depends_on = [time_sleep.resource_4]
  
  provisioner "local-exec" {
    command = "echo 'Resource 4 created'"
  }
}




# Original server resource (kept for compatibility)
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

resource "local_file" "deprecated_test" {
  filename = "${path.module}/deprecated_test.txt"
  content  = "test"
}

# Output for testing StackWeaver variable integration
# This output will display the value of test_var to verify StackWeaver variables are working
output "test_var_output" {
  description = "Output showing the value of test_var to verify StackWeaver variable integration"
  value       = var.test_var
}
