ARG __src_image=registry.access.redhat.com/ubi8/ubi-minimal:latest
FROM ${__src_image}

#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# TODO: fix dependencies versions

ARG __user_name=webmethods
ARG __user_id=888
ARG __group_name=webmethods
ARG __group_id=888

# Usually for testing purposes we would declare these folders as volumes
ARG __install_dir=/app/webmethods/version/products
ARG __upd_mgr_home_dir=/app/webmethods/upd-mgr-v11
ARG __audit_home_dir=/app/webmethods/audit

ENV WMUI_INSTALL_InstallDir=${__install_dir} \
    JAVA_HOME=${__install_dir}/jvm/jvm/ \
    JRE_HOME=${__install_dir}/jvm/jvm/jre/ \
    WMUI_USER_HOME=/home/${__user_name} \
    WMUI_UPD_MGR_HOME=${__upd_mgr_home_dir} \
    WMUI_LOCAL_SCRIPTS_HOME=/mnt/scripts \
    WMUI_AUDIT_BASE_DIR=/app/audit

RUN microdnf -y update ;\
    microdnf -y install \
      findutils \
      gettext \
      gzip \
      less \
      shadow-utils \
      tar \
      which \
      ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum; \
    /usr/sbin/groupadd -r -g ${__group_id} ${__group_name} ;\
    /usr/sbin/useradd -r -u ${__user_id} -m -g ${__group_name} ${__user_name} ;\
    mkdir -p "${WMUI_SUM_HOME}" "${WMUI_AUDIT_BASE_DIR}" \
      "${__install_dir}" "${WMUI_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${__user_name}:${__group_name} "${WMUI_LOCAL_SCRIPTS_HOME}" ;\
    chown -R ${__user_name}:${__group_name} "${WMUI_SUM_HOME}" ;\
    chown -R ${__user_name}:${__group_name} "${WMUI_AUDIT_BASE_DIR}" ;\
    chown -R ${__user_name}:${__group_name} "${__install_dir}"

USER sag

# VOLUME /mnt/output
