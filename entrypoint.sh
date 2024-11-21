#!/bin/bash

set -eux -o pipefail

case "${RSYNC_DAEMON:-rsyncd}" in
    'rsyncd')
      # Generate configuration from env vars
      envsubst '$RSYNC_PORT $USER_ETC_DIR $USER_RUN_DIR'< "${USER_ETC_DIR}"/rsyncd.conf.orig > "${USER_ETC_DIR}"/rsyncd.conf
      cat "${USER_ETC_DIR}"/rsyncd.conf
      # Start rsyncd daemon
      exec /usr/bin/rsync --no-detach --daemon --config "${USER_ETC_DIR}"/rsyncd.conf;;
    'sshd')
      # Generate configuration from env vars
      envsubst '$SSH_PORT $USER_ETC_DIR $USER_RUN_DIR'< "${USER_ETC_DIR}"/sshd_config.orig > "${USER_ETC_DIR}"/sshd_config

      # Generate hostkeys
      ssh-keygen -q -N "" -t dsa -f "${USER_ETC_DIR}"/ssh_host_dsa_key
      ssh-keygen -q -N "" -t rsa -b 4096 -f "${USER_ETC_DIR}"/ssh_host_rsa_key
      ssh-keygen -q -N "" -t ecdsa -f "${USER_ETC_DIR}"/ssh_host_ecdsa_key
      ssh-keygen -q -N "" -t ed25519 -f "${USER_ETC_DIR}"/ssh_host_ed25519_key

      # Load public key if provided
      if [[ "${SSH_PUBLIC_KEY:-'defaultNoKey'}" == ssh-* ]]; then
        mkdir -p "${HOME}/.ssh"
        chmod 0700 "${HOME}/.ssh"
        SSH_RSYNC_KEY="command=\"/ssh-rsync-wrapper.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${SSH_PUBLIC_KEY}"
        echo "${SSH_RSYNC_KEY}" > "${HOME}/.ssh/authorized_keys"
        chmod 0600 "${HOME}/.ssh/authorized_keys"
      fi

      # Start SSHD daemon
      exec /usr/sbin/sshd -D -f "${USER_ETC_DIR}"/sshd_config -e;;
    *)
      echo "ERROR: 'RSYNC_DAEMON' can only take one of the following values: 'rsyncd' (default), 'sshd";
      exit 1;;
esac
