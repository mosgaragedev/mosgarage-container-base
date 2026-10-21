#!/bin/bash
set -euo pipefail

DPKG_ARCHITECTURE=$(dpkg --print-architecture)

# GitHub release downloads stall for minutes at a time on flaky links; curl has
# no timeout of its own, so a dropped connection inside the build hangs forever.
CURL_BIN="curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 20 --max-time 600"

mkdir -p /tmp/mosgarage-pkgs
rm -Rf /tmp/mosgarage-pkgs/*

echo "Installing Skaffold ${SKAFFOLD_VERSION}..."
${CURL_BIN} -o /usr/local/bin/skaffold \
    https://github.com/GoogleContainerTools/skaffold/releases/download/v"${SKAFFOLD_VERSION}"/skaffold-linux-"${DPKG_ARCHITECTURE}"
chmod +x /usr/local/bin/skaffold

echo "Installing Kubectl ${KUBECTL_VERSION}..."
${CURL_BIN} -o /tmp/mosgarage-pkgs/kubectl \
    https://dl.k8s.io/release/v"${KUBECTL_VERSION}"/bin/linux/"${DPKG_ARCHITECTURE}"/kubectl
install -m 755 /tmp/mosgarage-pkgs/kubectl /usr/local/bin/kubectl
rm -f /tmp/mosgarage-pkgs/kubectl

echo "Installing Helm ${HELM_VERSION}..."
${CURL_BIN} -o /tmp/mosgarage-pkgs/helm.tar.gz \
    https://get.helm.sh/helm-v"${HELM_VERSION}"-linux-"${DPKG_ARCHITECTURE}".tar.gz
tar -C /tmp/mosgarage-pkgs -zxf /tmp/mosgarage-pkgs/helm.tar.gz
install -m 755 /tmp/mosgarage-pkgs/linux-"${DPKG_ARCHITECTURE}"/helm /usr/local/bin/helm
rm -Rf /tmp/mosgarage-pkgs/*

echo "Installing Kubeseal ${KUBESEAL_VERSION}..."
${CURL_BIN} -o /tmp/mosgarage-pkgs/kubeseal.tar.gz \
    https://github.com/bitnami-labs/sealed-secrets/releases/download/v"${KUBESEAL_VERSION}"/kubeseal-"${KUBESEAL_VERSION}"-linux-"${DPKG_ARCHITECTURE}".tar.gz
tar -C /tmp/mosgarage-pkgs -zxf /tmp/mosgarage-pkgs/kubeseal.tar.gz
install -m 755 /tmp/mosgarage-pkgs/kubeseal /usr/local/bin/kubeseal
rm -Rf /tmp/mosgarage-pkgs/*

echo "Installing k9s ${K9S_VERSION}..."
${CURL_BIN} -o /tmp/mosgarage-pkgs/k9s.tar.gz \
    https://github.com/derailed/k9s/releases/download/v"${K9S_VERSION}"/k9s_Linux_"${DPKG_ARCHITECTURE}".tar.gz
tar -C /tmp/mosgarage-pkgs -zxf /tmp/mosgarage-pkgs/k9s.tar.gz
install -m 755 /tmp/mosgarage-pkgs/k9s /usr/local/bin/k9s
rm -Rf /tmp/mosgarage-pkgs/*

echo "Installing Stern ${STERN_VERSION}..."
${CURL_BIN} -o /tmp/mosgarage-pkgs/stern.tar.gz \
    https://github.com/stern/stern/releases/download/v"${STERN_VERSION}"/stern_"${STERN_VERSION}"_linux_"${DPKG_ARCHITECTURE}".tar.gz
tar -C /tmp/mosgarage-pkgs -zxf /tmp/mosgarage-pkgs/stern.tar.gz
install -m 755 /tmp/mosgarage-pkgs/stern /usr/local/bin/stern
rm -Rf /tmp/mosgarage-pkgs/*

echo "Installing yq ${YQ_VERSION}..."
${CURL_BIN} -o /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/download/v"${YQ_VERSION}"/yq_linux_"${DPKG_ARCHITECTURE}"
chmod +x /usr/local/bin/yq

echo "System CLI tooling installed."
