# switch-kubectl

Fast kubeconfig switcher. Stores configs as `~/.kube/config.<context-name>` and swaps them in/out of `~/.kube/config`.

## Usage

```bash
# List available configs
switch.sh

# Switch by name (partial match)
switch.sh prod
switch.sh staging

# Switch by number
switch.sh 2
```

### Windows

```cmd
switch.bat
switch.bat prod
switch.bat 2
```

## vswitch — Vault-based switcher

Stores kubeconfigs in HashiCorp Vault (`secret/kube/<context-name>`) instead of local files.

### Prerequisites

- `vault` CLI in PATH
- `VAULT_ADDR` environment variable set
- Valid Vault token (via `vault login` or `VAULT_TOKEN`)
- Vault policy with read/list/write on `secret/kube/*`

### Usage

```bash
# Upload local configs to Vault (skip existing)
vswitch.sh init

# List configs from Vault (* = active)
vswitch.sh

# Switch by number
vswitch.sh 2

# Switch by name (partial match)
vswitch.sh prod
```

### Windows

```cmd
vswitch.bat init
vswitch.bat
vswitch.bat 2
vswitch.bat prod
```

## How it works

- Active config: `~/.kube/config`
- Inactive configs: `~/.kube/config.<context-name>` (e.g. `config.minikube`, `config.production`)
- On switch: current config is saved by its context name, selected config becomes active

## Install

```bash
# Linux/macOS
cp switch.sh /usr/local/bin/switch-kubectl
chmod +x /usr/local/bin/switch-kubectl

# Windows — copy switch.bat somewhere in PATH
```

---

## Support

| Network  | Address |
|----------|---------|
| **SOL**  | `BMvNKNK7zTRc6jQsdyUKFE6wFL6TJMKL1ZSRhW6pCpNJ` |
| **ETH**  | `0x743d66E349270355200b958FC1caC8427a9efe04` |
| **BTC**  | `bc1qset463vqdydrgpxy4m5hvke0cqvtlqztqrqw2v` |
