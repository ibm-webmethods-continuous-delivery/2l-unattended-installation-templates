ARG __from_img=registry.access.redhat.com/ubi8/ubi-minimal:latest
# ARG __from_img used below on the final stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS installer

# Bumpable tags or versions
ARG __pu_tag=v0.1.5
ARG __wmui_tag=v0.0.5

# Temporary until buildah fix will be available: one argument for ARG
ARG __i_bin=/tmp/installer.bin
ARG __u_bin=/tmp/upd-mgr-bootstrap.bin
ARG __p_zip=/tmp/products.zip
ARG __f_zip=/tmp/fixes.zip
ARG __i_sh=/tmp/install.sh
ARG __wmui_preserve_audit=true
ARG __wm_install_template=em/1101/full
ARG __wm_install_home=/opt/webmethods/${__wm_install_template}

RUN microdnf -y update &&\
    microdnf -y install \
        gettext \
        git \
        gzip \
        java-11-openjdk-devel \
        less \
        nc \
        procps \
        shadow-utils \
        tar \
        which \
        && \
    microdnf clean all &&\
    rm -rf /var/cache/yum

COPY ./installer.bin ${__i_bin}
COPY ./upd-mgr-bootstrap.bin ${__u_bin}
COPY ./products.zip ${__p_zip}
COPY ./fixes.zip ${__f_zip}
COPY ./local-install.sh ${__i_sh}

# From framework's local-install.sh prerequisites:
#
# 1. Any other mandatory environment variable required by the installed template MUST be set before calling this script
# 1. WMUI_LI_TEMPLATE MUST exist and contain the template id of the installation, e.g. msr/1101/simple
# 2. WMUI_LI_INSTALLER_BIN MUST exist and point to the installer binary file
# 3. WMUI_WMSCRIPT_imageFile MUST exist and point to an installer image containing the products mentioned by the template
# 4. WMUI_LI_UMGR_BOOTSTRAP_BIN is OPTIONAL. If it exists, it must point to a valid Update Manager Bootstrap file
# 5. WMUI_LI_FIXES_IMAGE_FILE is OPTIONAL. If it exists, it must point to a valid installer image containing the fixes mentioned by the template

ENV \
    WMUI_LI_FIXES_IMAGE_FILE="/tmp/fixes.zip" \
    WMUI_LI_INSTALLER_BIN="${__i_bin}" \
    WMUI_LI_PRESERVE_AUDIT="${__wmui_preserve_audit}" \
    WMUI_LI_PU_TAG="${__pu_tag}" \
    WMUI_LI_TEMPLATE="${__wm_install_template}" \
    WMUI_LI_UMGR_BOOTSTRAP_BIN="${__u_bin}" \
    WMUI_Li_WMUI_TAG="${__wmui_tag}" \
    WMUI_WMSCRIPT_imageFile="${__p_zip}" \
    WMUI_WMSCRIPT_InstallDir="${__wm_install_home}"

RUN chmod u+x "${__i_sh}" && "${__i_sh}"

FROM alpine:latest AS jre-packager-and-picker

ARG __wm_install_template=em/1101/full
ARG __wm_install_home=/opt/webmethods/${__wm_install_template}

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

ARG __wm_install_template=em/1101/full
ARG __wm_install_home=/opt/webmethods/${__wm_install_template}

ARG __wm_user_id=1001
ARG __wm_grp_id=1001
ARG __wm_grp_name=webmethods
ARG __wm_user_name=webmethods

ENV \
    JAVA_HOME="${__wm_install_home}/jvm/jvm/jre" \
    PATH="$PATH:${__wm_install_home}/jvm/jvm/jre/bin" \
    SAG_HOME="${__wm_install_home}"

RUN microdnf -y update &&\
    microdnf -y install \
        fontconfig \
        libXext \
        libXi \
        libXrender \
        libXtst \
        procps-ng \
        shadow-utils \
    && \
    microdnf clean all && \
    groupadd -g ${__wm_grp_id} "${__wm_grp_name}" && \
    useradd --shell /sbin/nologin \
    --uid ${__wm_user_id} --gid "${__wm_grp_name}"  "${__wm_user_name}"

COPY --chown=${__wm_user_id}:${__wm_grp_id} --from=jre-packager-and-picker ${__wm_install_home} ${__wm_install_home}

USER ${__wm_user_id}
