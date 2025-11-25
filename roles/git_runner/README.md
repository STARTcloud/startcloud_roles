# Ansible Role: git_runner

Sets up a GitHub Actions JIT (Just-In-Time) self-hosted runner on your system. This role downloads the GitHub Actions runner, configures it with a JIT token obtained from GitHub's API, and optionally sets it up as a systemd service.

## Requirements

- Debian-based Linux system (Debian 12+ or Ubuntu 20.04+)
- GitHub API token with appropriate permissions
- Internet access to download the runner and communicate with GitHub

## Role Variables

### Required Variables

These must be set in your playbook or Hosts.yml:

```yaml
# GitHub API token (best stored in .secrets.yml)
git_runner_github_token: "{{ secrets.github_token }}"

# Organization OR repository (one must be specified)
git_runner_org: "your-org-name"           # For org-level runner
# OR
git_runner_repo: "owner/repo-name"        # For repo-level runner
```

### Optional Variables

Available in `defaults/main.yml`:

```yaml
# Runner configuration
git_runner_user: "{{ service_user | default('startcloud') }}"
git_runner_home: "{{ service_home_dir | default('/home/' + git_runner_user) }}"
git_runner_dir: "{{ git_runner_home }}/actions-runner"
git_runner_work_folder: "_work"

# Runner identity
git_runner_name: "runner-{{ ansible_hostname }}"
git_runner_labels: ["self-hosted", "Linux", "X64"]
git_runner_group_id: 1

# Runner version
git_runner_version: "latest"  # Or specific version like "2.311.0"

# Systemd service
git_runner_service_enabled: true
git_runner_service_name: "github-actions-runner"
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - role: startcloud.startcloud_roles.git_runner
      vars:
        git_runner_org: "my-organization"
        git_runner_name: "production-runner"
        git_runner_labels: ["self-hosted", "linux", "production"]
```

## Running Ad-Hoc (Standalone Execution)

You can run this role ad-hoc outside of the Vagrant provisioning workflow to set up or reset a runner.

### Method 1: Using a Simple Playbook

Create `setup-runner.yml`:

```yaml
---
- name: Setup GitHub Actions Runner
  hosts: localhost
  connection: local
  become: true
  vars:
    git_runner_org: "your-organization"
    git_runner_name: "dev-runner"
    git_runner_labels: ["self-hosted", "linux", "x64"]
  
  roles:
    - startcloud.startcloud_roles.git_runner
```

Run with:
```bash
ansible-playbook setup-runner.yml -e "@.secrets.yml"
```

Or specify token directly:
```bash
ansible-playbook setup-runner.yml -e "git_runner_github_token=ghp_yourtoken"
```

### Method 2: One-Liner Command (No Playbook File Needed)

**Basic one-liner** (using token from .secrets.yml):
```bash
ansible localhost -m include_role -a name=startcloud.startcloud_roles.git_runner -e git_runner_org=my-org -e "@.secrets.yml" --become
```

**One-liner with all options**:
```bash
ansible localhost -m include_role -a name=startcloud.startcloud_roles.git_runner -e git_runner_github_token=ghp_token -e git_runner_org=my-org -e git_runner_name=custom-runner -e "git_runner_labels=['self-hosted','linux','x64']" --become
```

**For repository-level runner**:
```bash
ansible localhost -m include_role -a name=startcloud.startcloud_roles.git_runner -e git_runner_github_token=ghp_token -e git_runner_repo=owner/repo -e git_runner_name=repo-runner --become
```

**Ephemeral (one-job) runner**:
```bash
ansible localhost -m include_role -a name=startcloud.startcloud_roles.git_runner -e git_runner_org=my-org -e git_runner_ephemeral=true -e "@.secrets.yml" --become
```

### Method 3: Reset/Reinstall Runner

To completely reset and reinstall a runner, create `reset-runner.yml`:

```yaml
---
- name: Reset GitHub Actions Runner
  hosts: localhost
  connection: local
  become: true
  vars:
    git_runner_org: "your-organization"
    git_runner_user: "startcloud"
    git_runner_home: "/home/startcloud"
    git_runner_dir: "{{ git_runner_home }}/actions-runner"
  
  tasks:
    - name: Stop runner service if exists
      systemd:
        name: "actions.runner.*"
        state: stopped
      ignore_errors: true
    
    - name: Remove runner using svc.sh
      shell: |
        cd {{ git_runner_dir }}
        sudo ./svc.sh uninstall || true
      args:
        executable: /bin/bash
      ignore_errors: true
    
    - name: Remove runner directory
      file:
        path: "{{ git_runner_dir }}"
        state: absent
  
  roles:
    - startcloud.startcloud_roles.git_runner
```

Run with:
```bash
ansible-playbook reset-runner.yml -e "@.secrets.yml"
```

### Requirements for Ad-Hoc Execution

- Ansible installed on the target system
- startcloud_roles collection available in Ansible collections path
- GitHub token with appropriate permissions
- Root/sudo access for systemd service installation


## Usage in Hosts.yml

### Step 1: Add GitHub Token to .secrets.yml

```yaml
---
github_token: "ghp_yourGitHubPersonalAccessToken"
```

### Step 2: Configure in Hosts.yml

For an **organization-level runner**:

```yaml
vars:
  git_runner_org: "your-org-name"
  git_runner_name: "my-custom-runner"
  git_runner_labels: ["self-hosted", "linux", "domino"]

roles:
  - name: startcloud.startcloud_roles.git_runner
    when: true
```

For a **repository-level runner**:

```yaml
vars:
  git_runner_repo: "owner/repo-name"
  git_runner_name: "repo-runner"
  
roles:
  - name: startcloud.startcloud_roles.git_runner
    when: true
```

### Advanced Configuration

```yaml
vars:
  git_runner_org: "my-org"
  git_runner_name: "specialized-runner"
  git_runner_labels: ["self-hosted", "linux", "gpu", "x64"]
  git_runner_version: "2.311.0"  # Specific version
  git_runner_service_enabled: true
  git_runner_dir: "/opt/github-runner"  # Custom install location

roles:
  - name: startcloud.startcloud_roles.git_runner
```

## How It Works

1. **Validation**: Checks that required variables are set
2. **Version Detection**: Gets latest runner version or uses specified version
3. **Download**: Downloads GitHub Actions runner binary
4. **API Call**: Makes REST API call to GitHub to generate JIT configuration
5. **Service Setup**: 
   - If `git_runner_service_enabled: true` (default): Creates and starts systemd service
   - If `git_runner_service_enabled: false`: Starts runner in background
6. **Documentation**: Creates runner-info.txt with configuration details

## JIT Runner Behavior

JIT (Just-In-Time) runners are **ephemeral** by design:
- Each runner executes **at most one job**
- After job completion, the runner **automatically de-registers** from GitHub
- This ensures a clean environment for every job
- Perfect for security-sensitive workflows

## GitHub Token Permissions

Your GitHub token needs these scopes:

### For Organization Runners:
- `admin:org` - Full control of organizations

### For Repository Runners:
- `repo` - Full control of private repositories (or `public_repo` for public repos only)

## Systemd Service

When enabled (default), the runner is installed as a systemd service:

```bash
# Check status
sudo systemctl status github-actions-runner

# View logs
sudo journalctl -u github-actions-runner -f

# Restart service
sudo systemctl restart github-actions-runner
```

## Runner Information

After installation, check the runner-info.txt file:

```bash
cat ~/actions-runner/runner-info.txt
```

This file contains:
- Runner Name
- Runner ID
- Status
- Labels
- Start time
- Service information

## Troubleshooting

### Runner not appearing in GitHub

1. Check the runner-info.txt file for the runner ID
2. Verify the GitHub token has correct permissions
3. Check systemd service status: `sudo systemctl status github-actions-runner`
4. View runner logs in the runner directory

### API call fails

- Ensure the github_token is valid
- Verify org/repo names are correct
- Check internet connectivity

### Permission issues

- Ensure the runner user has proper permissions
- Check ownership of the runner directory

## License

Apache

## Author Information

This role was created by MarkProminic for STARTCloud.

## Related Documentation

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [JIT Runners API](https://docs.github.com/en/rest/actions/self-hosted-runners#create-configuration-for-a-just-in-time-runner-for-an-organization)
- [Security Hardening for Self-Hosted Runners](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
