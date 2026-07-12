# qemu_guest_agent

Ansible role `qemu_guest_agent` for the `startcloud.startcloud_roles` collection.

Installs the QEMU Guest Agent and serves BOTH transports at once, so one
image provides a credential-less structured control channel (IP discovery,
guest-exec, clean shutdown, fsfreeze, osinfo) on every hypervisor:

- **bhyve / QEMU** — virtio-serial channel (`/dev/virtio-ports/org.qemu.guest_agent.0`
  → unix socket host-side).
- **VirtualBox** — plain ISA serial port (ttyS1/COM2, exposed host-side as a
  named pipe via `--uart2 0x2F8 3 --uart-mode2 server`).

The stock distro unit hard-binds to the virtio device and cannot start
without it; this role disables it and installs one systemd unit per
transport, each guarded with `ConditionPathExists` on its device, both
enabled. Whichever devices exist on a given boot are served — on bhyve that
is both (the idle serial listener is harmless), on VirtualBox the serial
one.

Windows images get the equivalent from the `virtio` role: the stock
`QEMU-GA` service (virtio, untouched) plus a second `QEMU-GA-COM` service
on COM2 — on any boot the service whose device is absent fails to start and
the other serves.

FreeBSD support (`tasks/freebsd.yml`) follows the same shape via rc.conf
but is UNTESTED on VirtualBox guests — verify before shipping OPNsense-style
images.

## Verification

Guest answering `{"return": {}}` to `{"execute":"guest-ping"}` = correct:

- bhyve global zone: `socat - UNIX-CONNECT:/<zonepath>/root/tmp/qga.sock`
- VirtualBox host: connect to the machine's named pipe and write the JSON
  line (one client at a time — nothing else may hold the pipe).
