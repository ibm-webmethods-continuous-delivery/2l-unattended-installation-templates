ARG __from_img=alpine:latest
# ARG __from_img used below on the final stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS installer

# Bumpable tags or versions
ARG __pu_tag=v0.1.5
ARG __wmui_tag=v0.0.2

# Temporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __u_bin=/tmp/upd-mgr-bootstrap.bin
ARG __wm_install_home=/opt/webmethods/dbc/1011/full
ARG __wm_install_template=dbc/1101/full

RUN microdnf -y update &&\
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
        &&\
    microdnf clean all &&\
    rm -rf /var/cache/yum

COPY ./installer.bin ${__i_bin}
COPY ./upd-mgr-bootstrap.bin ${__u_bin}
COPY ./products.zip /tmp/products.zip
COPY ./fixes.zip /tmp/fixes.zip
COPY ./install.sh /tmp/install/install.sh


ENV \
    WMUI_CIB_FIXES_IMAGE_FILE="/tmp/fixes.zip" \
    WMUI_CIB_INSTALLER_BIN="${__i_bin}" \
    WMUI_CIB_PU_TAG="${__pu_tag}" \
    WMUI_CIB_TEMPLATE="${__wm_install_template}" \
    WMUI_CIB_UMGR_BOOTSTRAP_BIN="${__u_bin}" \
    WMUI_CIB_WMUI_TAG="${__wmui_tag}" \
    WMUI_WMSCRIPT_imageFile="/tmp/products.zip" \
    WMUI_WMSCRIPT_InstallDir="${__wm_install_home}"

RUN cd /tmp/install && chmod u+x ./install.sh && ./install.sh

FROM alpine:latest AS jre-packager-and-picker

ARG __wm_install_home=/opt/webmethods/dbc/1011/full

RUN apk --no-cache add openjdk17-jdk openjdk17-jmods binutils

# build minimal JRE
RUN /usr/lib/jvm/java-17-openjdk/bin/jlink \
    --verbose \
    --add-modules \
        java.base,java.sql,java.xml,java.desktop,java.management,java.security.jgss,java.instrument  \
    --compress 2 --strip-debug --no-header-files --no-man-pages \
    --release-info="add:IMPLEMENTOR=IBM:IMPLEMENTOR_VERSION=IBM_JRE_DBC_17" \
    --output "${__wm_install_home}/jvm/jvm/jre"

COPY --from=installer ${__wm_install_home}/common/lib/ ${__wm_install_home}/common/lib/
COPY --from=installer ${__wm_install_home}/common/db/ ${__wm_install_home}/common/db/
COPY --from=installer ${__wm_install_home}/build-time-audit.tgz ${__wm_install_home}/build-time-audit.tgz

FROM ${__from_img}

ARG __wm_install_home=/opt/webmethods/dbc/1011/full

ARG __wm_user_id=1824
ARG __wm_grp_id=1824
ARG __wm_grp_name=webmethods
ARG __wm_user_name=webmethods

ENV \
    JAVA_HOME="${__wm_install_home}/jvm/jvm/jre" \
    PATH="$PATH:${__wm_install_home}/jvm/jvm/jre/bin" \
    SAG_HOME="${__wm_install_home}"

RUN addgroup -g ${__wm_grp_id} "${__wm_grp_name}" && \
    adduser --shell /sbin/nologin --disabled-password \
    --no-create-home --uid ${__wm_user_id} --ingroup "${__wm_grp_name}"  "${__wm_user_name}"

COPY --chown=${__wm_user_id}:${__wm_grp_id} --from=jre-packager-and-picker ${__wm_install_home} ${__wm_install_home}

USER ${__wm_user_id}

RUN mkdir -p ${__wm_install_home}/common/db/logs

VOLUME ${__wm_install_home}/common/db/logs