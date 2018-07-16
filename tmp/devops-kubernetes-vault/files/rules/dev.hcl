# Manage auth methods broadly across Vault
path "auth/*" {
	capabilities = ["read", "list"]
}

# List, read key/value secrets
path "secret/dev/*" {
	capabilities = ["read", "list"]
}

# List, read key/value secrets
path "secret/aws/amazon/testing/*" {
	capabilities = ["read", "list"]
}

# Manage and manage secret engines broadly across Vault.
path "sys/mounts/*" {
	capabilities = ["read", "list"]
}

# Read health checks
path "sys/health" {
	capabilities = ["read"]
}
