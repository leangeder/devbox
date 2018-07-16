# Manage auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
# To list auth
path "sys/auth" {
	capabilities = ["read"]
}

# To list policies
path "sys/policy" {
  capabilities = ["read"]
}

# Create and manage ACL policies broadly across Vault
path "sys/policy/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# To list secrets
path "secret" {
	capabilities = ["read"]
}

# Manage and manage secret engines broadly across Vault.
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# To list mounts
path "sys/mounts" {
  capabilities = ["read"]
}

# Read health checks
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Read audit info
path "sys/audit" {
	capabilities = ["read", "sudo"]
}


# Check cpapabilities of the token
path "sys/capabilities"
{
  capabilities = ["create", "update"]
}

# Check cpapabilities of the token
path "sys/capabilities-self"
{
  capabilities = ["create", "update"]
}
