curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | sudo tee -a /etc/apt/sources.list.d/falcosecurity.list

apt-get update -y

sudo apt install -y dkms make linux-headers-$(uname -r)

sudo apt install -y clang llvm

sudo apt install -y dialog

sudo FALCO_DRIVER_CHOICE=kmod FALCO_FRONTEND=noninteractive apt install -y falco
