vault {
  address                = "http://192.168.178.40:8200/"
  namespace              = "cluster-1"
  renew_token            = false
  vault_agent_token_file = "/root/token"

  ssl {
    enabled = false
    verify  = false
  }
}
