#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm

set -e



KUBE_VERSION=1.31.1

# get platform
PLATFORM="amd64"

### setup terminal
apt-get --allow-unauthenticated update
apt-get --allow-unauthenticated install -y bash-completion binutils
sudo sh -c "echo 'colorscheme ron' >> /etc/vim/vimrc"
sudo sh -c "echo 'set tabstop=2' >> /etc/vim/vimrc"
sudo sh -c "echo 'set shiftwidth=2' >> /etc/vim/vimrc"
sudo sh -c "echo 'set expandtab' >> /etc/vim/vimrc"
sudo sh -c "echo 'source <(kubectl completion bash)' >> /etc/bash.bashrc"
sudo sh -c "echo 'alias k=kubectl' >> /etc/bash.bashrc"
sudo sh -c "echo 'alias c=clear' >> /etc/bash.bashrc"
sudo sh -c "echo 'complete -F __start_kubectl k' >> /etc/bash.bashrc"
sudo sed -i '1s/^/force_color_prompt=yes\n/' /etc/bash.bashrc
sudo sh -c "echo 'source <(kubectl completion bash)' >> /root/.bashrc"
sudo sh -c "echo 'alias k=kubectl' >> /root/.bashrc"
sudo sh -c "echo 'alias c=clear' >> /root/.bashrc"
sudo sh -c "echo 'complete -F __start_kubectl k' >> /root/.bashrc"
sudo sh -c "echo 'colorscheme ron' >> /root/.vimrc"
sudo sh -c "echo 'set tabstop=2' >> /root/.vimrc"
sudo sh -c "echo 'set shiftwidth=2' >> /root/.vimrc"
sudo sh -c "echo 'set expandtab' >> /root/.vimrc"
sudo sed -i '1s/^/force_color_prompt=yes\n/' /root/.bashrc
sudo bash -c "source /etc/bash.bashrc"
sudo bash -c "source /root/.bashrc"


### disable linux swap and remove any existing swap partitions
swapoff -a
sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab


### remove packages
kubeadm reset -f || true
crictl rm --force $(crictl ps -a -q) || true
apt-mark unhold kubelet kubeadm kubectl kubernetes-cni || true
apt-get remove -y docker.io containerd kubelet kubeadm kubectl kubernetes-cni || true
apt-get autoremove -y
systemctl daemon-reload

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get --allow-unauthenticated update
sudo apt-get --allow-unauthenticated install -y docker.io containerd kubelet=${KUBE_VERSION}-* kubeadm=${KUBE_VERSION}-* kubectl=${KUBE_VERSION}-* kubernetes-cni
apt-mark hold kubelet kubeadm kubectl kubernetes-cni


### install containerd 1.6 over apt-installed-version
wget https://github.com/containerd/containerd/releases/download/v1.6.12/containerd-1.6.12-linux-${PLATFORM}.tar.gz
tar xvf containerd-1.6.12-linux-${PLATFORM}.tar.gz
systemctl stop containerd
mv bin/* /usr/bin
rm -rf bin containerd-1.6.12-linux-${PLATFORM}.tar.gz
systemctl unmask containerd
systemctl start containerd


### containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
/sbin/modprobe overlay
/sbin/modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo mkdir -p /etc/containerd


### containerd config
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF


### crictl uses containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}


### kubelet should use containerd
{
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
}



### start services
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet && systemctl start kubelet


### init k8s
rm /root/.kube/config || true
kubeadm init --kubernetes-version=${KUBE_VERSION} --ignore-preflight-errors=NumCPU --skip-token-print --pod-network-cidr 192.168.0.0/16


if [ -n "$SUDO_USER" ]; then
    USER_ORIGIN=$SUDO_USER
else
    USER_ORIGIN=$(whoami)
fi
sudo mkdir -p /home/$USER_ORIGIN/.kube/
sudo cp -i /etc/kubernetes/admin.conf /home/$USER_ORIGIN/.kube/config
sudo mkdir -p ~/.kube/
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER_ORIGIN:$USER_ORIGIN /home/$USER_ORIGIN/.kube/config
sudo chmod 600 /home/$USER_ORIGIN/.kube/config
sudo chmod 600 ~/.kube/config
# etcdctl
ETCDCTL_VERSION=v3.5.1
ETCDCTL_ARCH=$(dpkg --print-architecture)
ETCDCTL_VERSION_FULL=etcd-${ETCDCTL_VERSION}-linux-${ETCDCTL_ARCH}
wget https://github.com/etcd-io/etcd/releases/download/${ETCDCTL_VERSION}/${ETCDCTL_VERSION_FULL}.tar.gz
tar xzf ${ETCDCTL_VERSION_FULL}.tar.gz ${ETCDCTL_VERSION_FULL}/etcdctl
mv ${ETCDCTL_VERSION_FULL}/etcdctl /usr/bin/
rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz

# Install HELM
HELMVERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
wget https://get.helm.sh/helm-${HELMVERSION}-linux-${PLATFORM}.tar.gz
tar -zxvf helm-${HELMVERSION}-linux-${PLATFORM}.tar.gz
sudo mv linux-${PLATFORM}/helm /usr/local/bin/helm
sudo chmod 755 /usr/local/bin/helm
echo "$(helm version --short) installed"
rm -R ./linux-${PLATFORM}
rm helm-${HELMVERSION}-linux-${PLATFORM}.tar.gz


#delete Kube-proxy
kubectl delete ds kube-proxy -n kube-system

# Install Cilium

helm repo add cilium https://helm.cilium.io/
CILIUMVERSION=$(helm search repo cilium/cilium --versions | awk 'NR==2 {print $2}')
helm install cilium cilium/cilium --version ${CILIUMVERSION} --namespace kube-system --set kubeProxyReplacement=true
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=${PLATFORM}
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
cilium uninstall
cilium install


echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0
