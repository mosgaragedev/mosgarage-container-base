#!/bin/bash
set -euo pipefail

DPKG_ARCHITECTURE=$(dpkg --print-architecture)
INSTALL_ADP_TOOLS="${INSTALL_ADP_TOOLS:-false}"

echo "Installing Kubectl Plugins..."
rm -rf /tmp/krew
mkdir -p /tmp/krew
curl -fsSL --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 20 --max-time 600 \
    -o /tmp/krew/krew.tar.gz \
    "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${DPKG_ARCHITECTURE}.tar.gz"
tar -C /tmp/krew -zxf /tmp/krew/krew.tar.gz
/tmp/krew/krew-linux_"${DPKG_ARCHITECTURE}" install krew

export PATH="${PATH}:/home/mosgarage/.krew/bin"

for plugin in neat debug-shell exec-cronjob mtail sniff secretdata; do
    kubectl krew install "${plugin}" || echo "krew plugin ${plugin} unavailable — continuing"
done

mkdir -p "/home/mosgarage/.zsh"
kubectl completion zsh > "/home/mosgarage/.zsh/kubernetes.sh"

echo "Installing Oh-My-ZSH..."
RUNZSH=no CHSH=no sh -c "$(curl -fsSL --retry 5 --retry-delay 3 https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
for repo in \
    "https://github.com/romkatv/powerlevel10k.git|${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git|${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
    "https://github.com/supercrabtree/k|${HOME}/.oh-my-zsh/custom/plugins/k" \
    "https://github.com/zsh-users/zsh-autosuggestions|${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
    "https://github.com/johanhaleby/kubetail.git|${HOME}/.oh-my-zsh/custom/plugins/kubetail"; do
    git clone --depth=1 "${repo%%|*}" "${repo##*|}" || echo "clone ${repo##*|} failed — continuing"
done

# ADP tooling is internal to the mosgarage cluster (it talks to artifactory and is
# interactive); it cannot be provisioned at build time, so it is opt-in.
if [ "${INSTALL_ADP_TOOLS}" = "true" ]; then
    echo "Installing ADP Tooling..."
    PATH="${HOME}/.local/bin:${PATH}" /usr/local/bin/adp-connect -D -I || { echo "ADP Tooling installation failed"; exit 1; }
else
    echo "Skipping ADP Tooling (INSTALL_ADP_TOOLS=false); run 'adp-connect -D -I' after start."
fi
