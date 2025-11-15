ARG __from_img=registry.access.redhat.com/ubi8/ubi-minimal:latest
# ARG __from_img used below on the final stage
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS installer

# Temporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __u_bin=/tmp/upd-mgr-bootstrap.bin
ARG __wm_install_home=/opt/webmethods/products
ARG __wm_install_template=EM/1101/full
ARG __wmui_tag=main

RUN microdnf -y update ;\
    microdnf -y install \
        gettext \
        git \
        gzip \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        java-11-openjdk-devel \
        ;\
    microdnf clean all ;\
    rm -rf /var/cache/yum

COPY ./installer.bin ${__i_bin}
COPY ./upd-mgr-bootstrap.bin ${__u_bin}
COPY ./products.zip /tmp/products.zip
COPY ./fixes.zip /tmp/fixes.zip
COPY ./install.sh /tmp/install/install.sh

ENV WMUI_SUM_HOME=/tmp/upd-mgr-v11 \
    WMUI_AUDIT_BASE_DIR=/tmp/WMUI_AUDIT \
    WMUI_DEBUG_ON=0 \
    WMUI_HOME=/tmp/WMUI \
    WMUI_INSTALL_IMAGE_FILE="/tmp/products.zip" \
    WMUI_INSTALL_INSTALL_DIR="${__wm_install_home}" \
    WMUI_INSTALL_INSTALLER_BIN="${__i_bin}" \
    WMUI_ONLINE_MODE=0 \
    WMUI_PATCH_AVAILABLE=1 \
    WMUI_PATCH_FIXES_IMAGE_FILE="/tmp/fixes.zip" \
    WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="${__u_bin}" \
    WMUI_SDC_ONLINE_MODE=0 \
    WMUI_TEMPLATE="${__wm_install_template}" \
    WMUI_TAG="${__wmui_tag}"

RUN cd /tmp/install; chmod u+x ./install.sh; ./install.sh

FROM alpine:latest AS jre-packager-and-picker

ARG __wm_install_home=/opt/webmethods/products

COPY --from=installer ${__wm_install_home} ${__wm_install_home}

#build minimal JRE
RUN apk --no-cache add openjdk17-jdk openjdk17-jmods binutils
RUN /usr/lib/jvm/java-17-openjdk/bin/jlink \
    --verbose \
    --add-modules \
        java.base,java.sql,java.xml,java.desktop,java.management,java.security.jgss,java.instrument  \
    --compress 2 --strip-debug --no-header-files --no-man-pages \
    --release-info="add:IMPLEMENTOR=IBM:IMPLEMENTOR_VERSION=IBM_JRE_DBC_17" \
    --output "${__wm_install_home}/jvm/jvm/jre"

FROM ${__from_img}

ARG __wm_install_home=/opt/webmethods/products
ARG __wm_user_id=1824
ARG __wm_grp_id=1824
ARG __wm_grp_name=webmethods
ARG __wm_user_name=webmethods

ENV \
    JAVA_HOME="${__wm_install_home}/jvm/jvm/jre" \
    PATH="$PATH:${__wm_install_home}/jvm/jvm/jre/bin" \
    SAG_HOME="${__wm_install_home}"

RUN microdnf -y install \
    shadow-utils \
    libXext \
    libXrender \
    libXtst \
    libXi \
    fontconfig \
    procps-ng && \
    microdnf clean all && \
    groupadd -g ${__wm_grp_id} "${__wm_grp_name}" && \
    useradd --shell /sbin/nologin \
    --uid ${__wm_user_id} --gid "${__wm_grp_name}"  "${__wm_user_name}"

COPY --chown=${__wm_user_id}:${__wm_grp_id} --from=jre-packager-and-picker ${__wm_install_home} ${__wm_install_home}

USER ${__wm_user_id}