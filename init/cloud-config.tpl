#cloud-config
users:
  - name: ${admin_user}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh-authorized-keys:
      - ${ssh_authorized_key}
ssh_pwauth: True
runcmd:
  - [ bash, -c, "echo -e '${admin_password}\n${admin_password}' | passwd ${admin_user}"]
  - sed -i "s/^#Port 22/Port ${ssh_port}/" /etc/ssh/sshd_config
  - sed -i "s/^Port 22/Port ${ssh_port}/" /etc/ssh/sshd_config
  - systemctl restart sshd
  - firewall-cmd --remove-service ssh
  - firewall-cmd --remove-service ssh --permanent
  - firewall-cmd --add-port ${ssh_port}/tcp
  - firewall-cmd --add-port ${ssh_port}/tcp --permanent
power_state:
  mode: reboot
write_files:
  - content: |
      #!/bin/bash
      iptables -I INPUT 1 -p tcp --dport ${ssh_port} -j ACCEPT
    path: /var/lib/cloud/scripts/per-boot/iptable.sh
    owner: root:root
    permissions: '700'
