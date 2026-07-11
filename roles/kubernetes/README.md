# Ansible Role: Kubernetes

Installs [Kubernetes](https://kubernetes.io) on Linux with kubeadm. A host is configured
as either a `control_plane` (runs `kubeadm init`, applies the CNI manifest) or a `node`
(joins the cluster with the `kubeadm join` command generated on the control plane).
Packages come from the official pkgs.k8s.io repositories and are version-pinned.

## Requirements

Requires a compatible
[Container Runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes),
e.g. containerd or Docker (`startcloud.startcloud_roles.docker`).

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    kubernetes_packages:
      - name: kubelet
        state: present
      - name: kubectl
        state: present
      - name: kubeadm
        state: present
      - name: kubernetes-cni
        state: present

Kubernetes packages to be installed on the server. Either a list of package names, or
`name`/`state` pairs for finer control.

    kubernetes_version: '1.25'
    kubernetes_version_rhel_package: '1.25.1'

The minor version of Kubernetes to install. `kubernetes_version` pins the apt package
version on Debian and feeds the kubeadm version (see `kubernetes_version_kubeadm`);
`kubernetes_version_rhel_package` must be a specific release and pins RHEL-family
packages.

    kubernetes_role: control_plane

Whether the server is a Kubernetes `control_plane` (default) or a `node`.

### Configuring kubeadm and kubelet through a config file (recommended)

`kubeadm init` runs with `--config <FILE>`:

    kubernetes_kubeadm_kubelet_config_file_path: '/etc/kubernetes/kubeadm-kubelet-config.yaml'

Path for the generated file (the directory is created if missing). The following
variables are rendered into that file — the skeleton (`apiVersion`, `kind`) is provided
by the template, so don't define those keys yourself:

    kubernetes_config_init_configuration:
      localAPIEndpoint:
        advertiseAddress: "{{ kubernetes_apiserver_advertise_address | default(ansible_default_ipv4.address, true) }}"

Options under `kind: InitConfiguration`.

    kubernetes_config_cluster_configuration:
      networking:
        podSubnet: "{{ kubernetes_pod_network.cidr }}"
      kubernetesVersion: "{{ kubernetes_version_kubeadm }}"

Options under `kind: ClusterConfiguration`.

    kubernetes_config_kubelet_configuration:
      cgroupDriver: systemd

Options under `kind: KubeletConfiguration` — the recommended way to configure kubelet;
most command-line options are deprecated upstream. The right `cgroupDriver` depends on
your container runtime (use `cgroupfs` with Docker instead of containerd).

    kubernetes_config_kube_proxy_configuration: {}

Options under `kind: KubeProxyConfiguration`.

### Configuring kubeadm and kubelet through command-line options

    kubernetes_kubelet_extra_args: ""

Extra args for kubelet startup (e.g. `"--fail-swap-on=false"` or
`"--node-ip={{ ansible_host }}"`). **Deprecated — prefer
`kubernetes_config_kubelet_configuration`.**

    kubernetes_kubeadm_init_extra_opts: ""

Extra args passed to `kubeadm init` (e.g.
`"--apiserver-cert-extra-sans my-custom.host"`).

    kubernetes_join_command_extra_opts: ""

Extra args appended to the generated `kubeadm join` command on nodes (e.g.
`--ignore-preflight-errors=Swap`).

### Additional variables

    kubernetes_allow_pods_on_control_plane: true

Whether to remove the taint that prevents pods from scheduling on the control plane.
Keep `true` for a single-node cluster; set `false` for a dedicated control plane.

    kubernetes_pod_network:
      # Flannel CNI.
      cni: 'flannel'
      cidr: '10.244.0.0/16'
      # Calico CNI.
      # cni: 'calico'
      # cidr: '192.168.0.0/16'

Supported CNIs: `flannel` (default), `calico`, or `weave`. Choose one per cluster —
converting between them is not handled by this role.

    kubernetes_apiserver_advertise_address: ''
    kubernetes_version_kubeadm: 'stable-{{ kubernetes_version }}'
    kubernetes_ignore_preflight_errors: 'all'

Options for control plane initialization. `kubernetes_apiserver_advertise_address`
falls back to `ansible_default_ipv4.address` when empty.

    kubernetes_apt_release_channel: "stable"
    kubernetes_apt_keyring_file: "/etc/apt/keyrings/kubernetes-apt-keyring.asc"
    kubernetes_apt_repository: "deb [signed-by={{ kubernetes_apt_keyring_file }}] https://pkgs.k8s.io/core:/{{ kubernetes_apt_release_channel }}:/v{{ kubernetes_version }}/deb/ /"

Apt repository options (Debian/Ubuntu). kubectl/kubeadm/kubelet are pinned to
`kubernetes_version` via apt preferences.

    kubernetes_yum_base_url: "https://pkgs.k8s.io/core:/stable:/v{{ kubernetes_version }}/rpm/"
    kubernetes_yum_gpg_key: "https://pkgs.k8s.io/core:/stable:/v{{ kubernetes_version }}/rpm/repodata/repomd.xml.key"
    kubernetes_yum_gpg_check: true
    kubernetes_yum_repo_gpg_check: true

Yum repository options (RHEL-family). Point the base URL and GPG key at a mirror if
needed.

    kubernetes_flannel_manifest_file: https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    kubernetes_calico_manifest_file: https://projectcalico.docs.tigera.io/manifests/calico.yaml

CNI manifests applied to the cluster. Substitute your own copies to customize the
networking configuration.

## Dependencies

None.

## Example Playbooks

### Single node (control-plane-only) cluster

    - hosts: all
      vars:
        kubernetes_allow_pods_on_control_plane: true
      roles:
        - startcloud.startcloud_roles.docker
        - startcloud.startcloud_roles.kubernetes

### Two or more nodes (single control-plane) cluster

Control plane inventory vars:

    kubernetes_role: "control_plane"

Node(s) inventory vars:

    kubernetes_role: "node"

Playbook:

    - hosts: all
      vars:
        kubernetes_allow_pods_on_control_plane: true
      roles:
        - startcloud.startcloud_roles.docker
        - startcloud.startcloud_roles.kubernetes

Then log into the control plane and run `kubectl get nodes` as root to see every server
in the cluster.

## License

GPL-2.0-or-later
