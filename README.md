# switch-kubectl

Fast kubeconfig context switcher for teams managing multiple Kubernetes clusters.

Provides two tools:

- **switch** — switches between local kubeconfig files stored as `~/.kube/config.<context-name>`
- **vswitch** — same workflow, but kubeconfigs are stored in [HashiCorp Vault](https://www.vaultproject.io/) (`secret/kube/<name>`) instead of local files

Both tools support switching by number or partial name match, and work on Linux, macOS, and Windows.

## Install from release

### Debian / Ubuntu

```bash
# Download the .deb package from the latest release
wget https://github.com/ZombiePm/switch-kubectl/releases/latest/download/switch-kubectl_1.0.0_all.deb
sudo dpkg -i switch-kubectl_1.0.0_all.deb
```

This installs `switch-kubectl` and `vswitch-kubectl` into `/usr/local/bin/`.

### Windows

1. Download `switch-kubectl_1.0.0_windows.zip` from the [latest release](https://github.com/ZombiePm/switch-kubectl/releases/latest)
2. Extract the archive
3. Run `install.bat` — it copies `switch.bat` and `vswitch.bat` to `%USERPROFILE%\bin\`
4. If `%USERPROFILE%\bin` is not in your PATH, the installer will show the command to add it

### Manual install

```bash
# Linux/macOS — copy scripts to any directory in PATH
cp switch.sh /usr/local/bin/switch-kubectl
cp vswitch.sh /usr/local/bin/vswitch-kubectl
chmod +x /usr/local/bin/switch-kubectl /usr/local/bin/vswitch-kubectl

# Windows — copy .bat files to any directory in PATH
```

## switch — local kubeconfig switcher

Manages kubeconfigs stored as local files (`~/.kube/config.*`).

### How it works

- Active config: `~/.kube/config`
- Inactive configs: `~/.kube/config.<context-name>` (e.g. `config.my-cluster`, `config.staging`)
- On switch: current config is saved by its context name, selected config becomes active

### Usage

```bash
# List available configs
switch-kubectl

# Switch by name (partial match)
switch-kubectl staging

# Switch by number
switch-kubectl 2
```

Example output:

```
Available kubeconfig:

  1) my-cluster
  2) staging
  3) production

Active: my-cluster
```

### Windows

```cmd
switch.bat
switch.bat staging
switch.bat 2
```

## vswitch — Vault-based kubeconfig switcher

Stores kubeconfigs in HashiCorp Vault (`secret/kube/<context-name>`) instead of local files. Useful for teams that centralize secrets in Vault.

### Prerequisites

- `vault` CLI in PATH
- `VAULT_ADDR` environment variable set
- Valid Vault token (via `vault login` or `VAULT_TOKEN`)
- Vault policy with read/list/write access to `secret/kube/*`

### Usage

```bash
# Upload local configs to Vault (skips already existing)
vswitch-kubectl init

# List configs stored in Vault (* marks active)
vswitch-kubectl

# Switch by number
vswitch-kubectl 2

# Switch by name (partial match)
vswitch-kubectl prod
```

Example output:

```
Configs in Vault:

  1) my-cluster  *
  2) staging
  3) production

Active: my-cluster
```

### Windows

```cmd
vswitch.bat init
vswitch.bat
vswitch.bat 2
vswitch.bat prod
```

### Vault storage layout

Each kubeconfig is stored as a single field in Vault KV (v1):

```
secret/kube/my-cluster     → kubeconfig=<full kubeconfig YAML>
secret/kube/staging         → kubeconfig=<full kubeconfig YAML>
secret/kube/production      → kubeconfig=<full kubeconfig YAML>
```

The `init` command reads context names from existing local files and uploads them to Vault if not already present.

## Building packages

```bash
# Build .deb and Windows .zip into dist/
./build.sh
```

## License

GPL-2.0

---

## Support

| Network  | Address |
|----------|---------|
| **SOL**  | `BMvNKNK7zTRc6jQsdyUKFE6wFL6TJMKL1ZSRhW6pCpNJ` |
| **ETH**  | `0x743d66E349270355200b958FC1caC8427a9efe04` |
| **BTC**  | `bc1qset463vqdydrgpxy4m5hvke0cqvtlqztqrqw2v` |
