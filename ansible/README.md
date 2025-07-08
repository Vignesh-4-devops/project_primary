# Ansible Automation Playbooks

This directory contains Ansible playbooks to help you manage services and run custom commands across your infrastructure.

## Prerequisites

Before using these playbooks, you need to install Ansible and its dependencies. Run the installation script:

```sh
./install_dependencies.sh
```

This script will install:
- Ansible (latest version from PPA on Ubuntu/Debian, via Homebrew on macOS)

## Inventory

- The `hosts` file defines your inventory (host groups and hostnames).

## Playbooks

### 1. manage_service.yml
**Purpose:**
- Manage (start, stop, restart, check status) any systemd service on your target hosts.

**Prompts:**
- **Target host group:** Enter a group from your inventory (e.g., `all_machines`, `usa-region`, or a specific hostname). Defaults to `all_machines`.
- **Service name:** The systemd service to manage (e.g., `docker.service`, `cloudinfra_aisearch_backend.service`).
- **Action:** What to do: `start`, `stop`, `restart`, or `status`.

**Example usage:**
```sh
ansible-playbook -i hosts manage_service.yml
```

### 2. run_custom_command_advanced.yml
**Purpose:**
- Run any shell command on selected hosts, as any user (including root or the current user).

**Prompts:**
- **Target host group:** Enter a group from your inventory (e.g., `all_machines`, `usa-region`, or a specific hostname). Defaults to `all_machines`.
- **Command:** The shell command to run (e.g., `whoami`, `uptime`).
- **User:** The user to run the command as. Enter `root` for sudo, another username, or leave blank to run as the current user.

**Example usage:**
```sh
ansible-playbook -i hosts run_custom_command_advanced.yml
```

## Notes
- Make sure your inventory (`hosts` file) is up to date with the correct host groups and hostnames.
- You may need appropriate SSH access and sudo privileges for some operations.
- For custom commands, privilege escalation is only used if you specify a user.

---
Feel free to modify these playbooks to suit your infrastructure needs! 