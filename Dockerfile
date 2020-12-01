# (first line comment needed for DOCKER_BUILDKIT use)
#
# cilium-envoy from github.com/cilium/proxy
#
FROM quay.io/cilium/cilium-envoy:6c980c60fb96e27faae370af792217316482c2ed@sha256:4c1cc322e6a76a49839b94cc3f0b088bd0c93dda6e98eefc0fd129e4b4c55157 as cilium-envoy
ARG CILIUM_SHA=""
LABEL cilium-sha=${CILIUM_SHA}

#
# Hubble CLI
#
FROM docker.io/jrajahalme/hubble:v0.7.1@sha256:2cfff586d2f4c2e9d4345fb7c3d2b2d59e736c4f13d974009fcdd7b3255b7f93 as hubble
ARG CILIUM_SHA=""
LABEL cilium-sha=${CILIUM_SHA}

#
# Cilium incremental build. Should be fast given builder-deps is up-to-date!
#
# cilium-builder tag is the date on which the compatible build image
# was pushed.  If a new version of the build image is needed, it needs
# to be tagged with a new date and this file must be changed
# accordingly.  Keeping the old images available will allow older
# versions to be built while allowing the new versions to make changes
# that are not backwards compatible.
#
# BUILDPLATFORM note: BUILDPLATFORM is an automatic platform ARG enabled by
# Docker BuildKit. The form we would want to use to enable cross-platform builds
# is "--platform=$BUILDPLATFORM". This would break classic builds, as they would
# see just "--platform=", which causes an invalid argument error.
# Makefile.buildkit detects the "# FROM ..." comment on the previous line and
# augments the FROM line accordingly.
#
# FROM --platform=$BUILDPLATFORM
FROM docker.io/jrajahalme/cilium-builder:2020-12-01@sha256:24cc4f7c3d048e5c93e98f2cecdd351cf1f2179060091ec20f8c2f31d94bcdc7 as builder
ARG CILIUM_SHA=""
LABEL cilium-sha=${CILIUM_SHA}
LABEL maintainer="maintainer@cilium.io"
WORKDIR /go/src/github.com/cilium/cilium
COPY . ./
ARG NOSTRIP
ARG LOCKDEBUG
ARG RACE
ARG V
ARG LIBNETWORK_PLUGIN

#
# Please do not add any dependency updates before the 'make install' here,
# as that will mess with caching for incremental builds!
#
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
#
ARG TARGETARCH
RUN make GOARCH=$TARGETARCH RACE=$RACE NOSTRIP=$NOSTRIP LOCKDEBUG=$LOCKDEBUG PKG_BUILD=1 V=$V LIBNETWORK_PLUGIN=$LIBNETWORK_PLUGIN \
    SKIP_DOCS=true DESTDIR=/tmp/install build-container install-container \
    licenses-all

#
# Cilium runtime install.
#
# cilium-runtime tag is a date on which the compatible runtime base
# was pushed.  If a new version of the runtime is needed, it needs to
# be tagged with a new date and this file must be changed accordingly.
# Keeping the old runtimes available will allow older versions to be
# built while allowing the new versions to make changes that are not
# backwards compatible.
#
FROM docker.io/jrajahalme/cilium-runtime:2020-11-30@sha256:ba79fe3c45a210612c6a4a132fe669df75072456e873dc13ee0b22e7246a6148
ARG CILIUM_SHA=""
LABEL cilium-sha=${CILIUM_SHA}
LABEL maintainer="maintainer@cilium.io"
COPY --from=builder /tmp/install /
COPY --from=cilium-envoy / /
COPY --from=hubble /usr/bin/hubble /usr/bin/hubble
COPY --from=builder /go/src/github.com/cilium/cilium/plugins/cilium-cni/cni-install.sh /cni-install.sh
COPY --from=builder /go/src/github.com/cilium/cilium/plugins/cilium-cni/cni-uninstall.sh /cni-uninstall.sh
COPY --from=builder /go/src/github.com/cilium/cilium/contrib/packaging/docker/init-container.sh /init-container.sh
COPY --from=builder /go/src/github.com/cilium/cilium/LICENSE.all /LICENSE.all
WORKDIR /home/cilium
RUN groupadd -f cilium \
    && /usr/bin/hubble completion bash > /etc/bash_completion.d/hubble \
    && echo ". /etc/profile.d/bash_completion.sh" >> /etc/bash.bashrc

ENV INITSYSTEM="SYSTEMD"
CMD ["/usr/bin/cilium"]
