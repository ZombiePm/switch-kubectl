# Kubectl Version Switcher

A lightweight utility to easily switch between different kubectl configuration files. This tool automatically manages your kubeconfig files by rotating between saved configurations.

## 📋 Overview

This tool helps Kubernetes administrators and developers who work with multiple clusters by providing a simple way to switch between different kubectl configurations. It works by maintaining timestamped backups of your config files and rotating between them.

## 🖥️ Supported Platforms

- **Windows**: `switch.bat`
- **Linux/macOS**: `switch.sh`

## 🚀 Quick Start

### Prerequisites

- `kubectl` installed and configured
- For Windows: Command Prompt or PowerShell
- For Linux/macOS: Bash shell

### Installation

1. Clone this repository:
```bash
git clone https://github.com/ZombiePm/switch-kubectl.git
cd switch-kubectl
```

2. Make the script executable (Linux/macOS only):
```bash
chmod +x switch.sh
```

## 📖 How It Works

The tool operates by:
1. Renaming your current `config` file to `config.<timestamp>`
2. Finding the oldest timestamped config file
3. Renaming that file back to `config` (making it active)
4. Displaying the current kubectl context

## 💡 Usage Examples

### Windows
```cmd
# Navigate to the script directory
cd \path\to\switch-kubectl

# Run the batch file
switch.bat
```

Or add to PATH and run from anywhere:
```cmd
# Add to PATH (temporary)
set PATH=%PATH%;C:\path\to\switch-kubectl

# Now you can run from any directory
switch.bat
```

### Linux/macOS
```bash
# Navigate to the script directory
cd /path/to/switch-kubectl

# Run the script
./switch.sh
```

Or make it globally available:
```bash
# Copy to a directory in your PATH
sudo cp switch.sh /usr/local/bin/kube-switch
sudo chmod +x /usr/local/bin/kube-switch

# Now run from anywhere
kube-switch
```

## 🛠️ Advanced Usage

### Setting Up Multiple Configurations

1. **Save your first configuration:**
```bash
# Manually rename your current config
mv ~/.kube/config ~/.kube/config.dev-cluster
```

2. **Add a second configuration:**
```bash
# Copy or move another kubeconfig
cp ~/Downloads/prod-config ~/.kube/config.prod-cluster
```

3. **Create the active config:**
```bash
# One of your configs should be named simply "config"
cp ~/.kube/config.dev-cluster ~/.kube/config
```

4. **Start switching:**
```bash
./switch.sh  # or switch.bat on Windows
```

### Custom Configuration Directory

#### Windows (switch.bat)
Edit line 5 in `switch.bat`:
```batch
set "CONFIG_DIR=C:\custom\path\.kube"
```

#### Linux/macOS (switch.sh)
Edit line 4 in `switch.sh`:
```bash
config_dir="/custom/path/.kube"
```

## 🔧 How to Prepare Your Config Files

Before using the switcher, organize your kubeconfig files:

```bash
# In your ~/.kube directory, you should have files like:
config              # Currently active configuration
config.20260129143022  # Previous configuration (timestamped backup)
config.dev-cluster     # Development cluster config
config.prod-cluster    # Production cluster config
config.staging-cluster # Staging cluster config
```

## ⚠️ Important Notes

1. **First Run**: On first execution, there will be no timestamped files to switch to
2. **Backup Strategy**: The tool creates timestamped backups automatically
3. **Current Context**: After switching, it displays the active kubectl context
4. **Permissions**: Ensure you have read/write permissions to your `.kube` directory

## 🎯 Typical Workflow

1. Set up multiple named config files in `~/.kube/`
2. Make one active by naming it `config`
3. Run the switcher to rotate between configurations
4. Each run moves to the next chronological configuration

## 📁 File Structure Example

```
~/.kube/
├── config                 # Active configuration
├── config.20260129143022  # Backup from previous switch
├── config.dev-cluster     # Development environment
├── config.prod-cluster    # Production environment  
├── config.test-cluster    # Test environment
└── cache/                 # kubectl cache (untouched)
```

## 🔍 Troubleshooting

### Common Issues

**Issue**: "Folder not found!" (Windows)
**Solution**: Ensure `%USERPROFILE%\.kube` directory exists

**Issue**: "No older configs to switch!" 
**Solution**: You need at least two config files (one active, one saved)

**Issue**: Permission denied
**Solution**: Check read/write permissions on your `.kube` directory

### Verification

Check your current context:
```bash
kubectl config current-context
```

List all contexts:
```bash
kubectl config get-contexts
```

## 🤝 Contributing

Feel free to submit issues or pull requests to improve this tool!

## 📄 License

This project is open source and available under the MIT License.

---
**Author**: ZombiePm  
**Repository**: https://github.com/ZombiePm/switch-kubectl