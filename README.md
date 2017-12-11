# SU-API-Vault-perl
A perl lib that interacts with Hashicorp Vault

```perl
use SU::API::Vault;

my $role_id = "6cc1395e-c53c-4aa9-9a2c-42476ab647b5"; # Just examples, you need to create these for your self
my $secret_id = "d5f7ddc5-abc5-4d3f-bcfa-2c9bfebd124e";
my $vault = new SU::API::Vault("https://vault.example.com:8200", $role_id, $secret_id);
my $secret = $vault->get_secret("example/path"); # Relative to secret/vaulttoolsecrets/

exit 0;
```
