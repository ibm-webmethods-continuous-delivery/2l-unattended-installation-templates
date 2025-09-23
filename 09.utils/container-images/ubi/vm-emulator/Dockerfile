ARG __src_image=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${__src_image}

#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# Layer 1 - this is intended to be fixed across the landscape
# TODO: fix dependencies versions
RUN microdnf -y update &&\
    microdnf -y install \
      findutils \
      gettext \
      gzip \
      less \
      procps \
      shadow-utils \
      tar \
      which \
      &&\
    microdnf clean all &&\
    rm -rf /var/cache/yum

# Layer 2 - this may vary according to the context in this framework
ARG __user_name=webmethods
ARG __user_id=888
ARG __group_name=webmethods
ARG __group_id=888
ARG __user_home=/home/${__user_name}

# Usually for testing purposes we would declare these folders as volumes
ARG __audit_home_dir=/app/webmethods/audit
ARG __install_dir=/app/webmethods/version/products
ARG __upd_mgr_home_dir=/app/webmethods/upd-mgr-v11

# Usually these are also volumes, expected to be bind mounted
ARG __script_dir=/mnt/scripts

ENV \
  WMUI_EMULATOR_VM_AUDIT_BASE_DIR=${__audit_home_dir} \
  WMUI_EMULATOR_VM_INSTALL_INSTALL_DIR=${__install_dir} \
  WMUI_EMULATOR_VM_LOCAL_SCRIPTS_HOME=${__script_dir} \
  WMUI_EMULATOR_VM_UPD_MGR_HOME=${__upd_mgr_home_dir} \
  WMUI_EMULATOR_VM_USER_HOME=${__user_home}

RUN /usr/sbin/groupadd -r -g ${__group_id} ${__group_name} &&\
    /usr/sbin/useradd -r -u ${__user_id} -m -d ${__user_home} -g ${__group_name} ${__user_name} &&\
    mkdir -p \
      "${__audit_home_dir}" \
      "${__install_dir}" \
      "${__script_dir}" \
      "${__upd_mgr_home_dir}" &&\
    chown -R ${__user_name}:${__group_name} \
      "${__audit_home_dir}" \
      "${__install_dir}" \
      "${__script_dir}" \
      "${__upd_mgr_home_dir}"

USER ${__user_name}

VOLUME "${__audit_home_dir}" "${__install_dir}" "${__upd_mgr_home_dir}" "${__script_dir}" "${__user_home}"
