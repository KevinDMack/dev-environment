#!/bin/bash
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$SCRIPT_NAME.log"
SPACEFX_DIR="/var/spacedev"
SPACEFX_ENV="spacefx.env"
SPACEFX_TAR="msft-azure-orbital-sdk.tgz"
declare -A SCRIPT_REQUIRED_PARAMETERS=(
    ["ENV_FILE"]="--env"
    ["CONTAINER_REGISTRY"]="--registry"
)
SDK_BOOTSTRAP_DIR=$(find /home d -name "sdk-bootstrap" -print -quit)
DOCKER_INSTALL=false
ORAS_VERSION="1.0.0"
source ${SDK_BOOTSTRAP_DIR}/envs/spacefx.0.10.0.env # Default values for the environment variables
############################################################
# Help                                                     #
############################################################
show_help() {
  # Display Help
  echo "A BASH script intended to be run for creating a virtual satellite host machine in azure.  ."
  echo
  echo "Usage: bash ./$SDK_BOOTSTRAP_DIR/$SCRIPT_NAME --env ./env/spacefx.env --registry spacefx.azurecr.io"
  echo
  echo "Flags:"
  echo "--docker                   |       [OPTIONAL] Whether to install docker or not."
  echo "--help                     | -h    [OPTIONAL] how to use the script (this screen)"
  echo
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --docker)
        shift
        DOCKER_INSTALL=true
        ;;
        --admin-user)
        shift
        ADMIN_USERNAME=$1
        ;;
        -h | --help) show_help ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

if [[ -d "${SPACEFX_DIR}" ]]; then
    echo "${SPACEFX_DIR} directory exists..."
else
    sudo chown -R $USER $PWD
    echo "Creating ${SPACEFX_DIR}..."    
    sudo mkdir -p ${SPACEFX_DIR}/env
    sudo mkdir -p ${SPACEFX_DIR}/modules
    sudo chown -R $USER ${SPACEFX_DIR}
    echo "Copying ${SPACEFX_DIR}/modules/ from $SDK_BOOTSTRAP_DIR/modules/*..."
    sudo cp $SDK_BOOTSTRAP_DIR/modules/* ${SPACEFX_DIR}/modules/
fi

echo "Getting host architecture from '$(dpkg --print-architecture)'..."
host_architecture="$(dpkg --print-architecture)"
echo "host_architecture is $host_architecture"

INSTALL_SCRIPT_URI_AZ="https://aka.ms/InstallAzureCLIDeb"
INSTALL_SCRIPT_URI_HELM="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
INSTALL_SCRIPT_URI_ORAS="https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${host_architecture}.tar.gz"

install_az() {
    # # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt#option-1-install-with-one-command
    echo "Installing Azure CLI..."
    sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
    curl -sL "$INSTALL_SCRIPT_URI_AZ" | sudo bash
}

install_linux_modules_extra_azure() {
    echo "Installing linux-modules-extra-azure..."
    sudo apt-get update
    sudo apt-get install -y linux-modules-extra-azure
}

install_dotnet() {
    echo "Installing dotnet..."
    sudo apt-get install -y dotnet-sdk-7.0
}

install_helm() {
    # https://helm.sh/docs/intro/install/#from-script
    echo "Installing helm..."
    curl "$INSTALL_SCRIPT_URI_HELM" | bash

}

install_jq() {
    echo "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
}

install_rsync() {
    sudo apt-get install -y rsync
}

install_net_tools() {
    sudo apt-get install -y net-tools
}

install_traceroute() {
    sudo apt install inetutils-traceroute
}

install_docker() {
    # https://docs.docker.com/engine/install/ubuntu/#uninstall-old-versions
    echo "Uninstalling previous versions of docker, if any"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

    # https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    echo "Installing docker - version ${VER_DOCKER_MIN}..."
    sudo apt-get install -y ca-certificates curl gnupg

    echo "Adding docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "Setting up docker repository"
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    echo "Update apt and install docker"
    sudo apt-get update -y
    VERSION_STRING="5:${VER_DOCKER_MIN}-1~ubuntu.22.04~jammy"
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

    sudo chmod 666 /var/run/docker.sock # an alternative to adding a user to the docker group
}

configure_docker(){
    sudo groupadd docker
    sudo usermod -aG docker azureuser
    sudo systemctl start docker
    sleep 2
    newgrp docker
    sleep 2 
    sudo chmod g+rw /var/run/docker.sock
}

install_oras() {
    echo "Installing oras..."
    curl -LO "$INSTALL_SCRIPT_URI_ORAS"
    mkdir -p oras-install/
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
    sudo mv oras-install/oras /usr/local/bin/
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/
}

install_regctl() {
    echo "Installing regctl - version ${VER_REGCTL}..."
    curl -L https://github.com/regclient/regclient/releases/download/${VER_REGCTL}/regctl-linux-amd64 >regctl
    sudo mv regctl /usr/local/bin/
    sudo chmod 755 /usr/local/bin/regctl
    rm -rf regctl
}

install_dive() {
    DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -OL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb
    sudo apt install ./dive_${DIVE_VERSION}_linux_amd64.deb
}

install_tree() {
    sudo apt install tree -y
}

make_directory_structure(){
    echo "Giving rights to ~/sdk-bootstrap..."
    sudo chown -R $ADMIN_USERNAME /home/azureuser/sdk-bootstrap

    echo "Creating and Giving rights to ~/sdk-bootstrap/machine-config..."
    sudo mkdir -p /home/$ADMIN_USERNAME/sdk-bootstrap/machine-config
    sudo chown -R $ADMIN_USERNAME /home/azureuser/sdk-bootstrap/machine-config
    
    echo "Creating and Giving rights to /var/spacedev..."
    sudo mkdir -p /var/spacedev/
    sudo chown -R $ADMIN_USERNAME /var/spacedev/
    sudo chown -R $ADMIN_USERNAME /home/$ADMIN_USERNAME/sdk-bootstrap/

    echo "Creating and Giving rights to ~/inbox..."
    mkdir -p /home/$ADMIN_USERNAME/inbox
    sudo chown -R $ADMIN_USERNAME /home/$ADMIN_USERNAME/inbox
    echo "Creating and Giving rights to ~/outbox..."
    mkdir -p /home/$ADMIN_USERNAME/outbox
    sudo chown -R $ADMIN_USERNAME /home/$ADMIN_USERNAME/outbox
}

output_version(){
    echo "--------------------------------------------------"
    echo "Configuration identifies the following versions..."
    echo "--------------------------------------------------"
    echo "VER_DOCKER_MIN=${VER_DOCKER_MIN}"
    echo "VER_DOCKER_MAX=${VER_DOCKER_MAX}"
    echo "VER_CFSSL=${VER_CFSSL}"
    echo "VER_HELM=${VER_HELM}"
    echo "VER_K3S=${VER_K3S}"
    echo "VER_KUBECTL=${VER_KUBECTL}"
    echo "VER_JQ=${VER_JQ}"
    echo "VER_YQ=${VER_YQ}"
    echo "VER_REGCTL=${VER_REGCTL}"
    echo "--------------------------------------------------"
}

validate_versions(){
    echo ""
    echo "Validating versions..."
    echo "--------------------------------------------------"
    echo "linux-modules-extra-azure:"
    apt show linux-modules-extra-azure
    echo "--------------------------------------------------"
    echo "Azure CLI:"
    az --version
    echo "--------------------------------------------------"
    echo "DOTNET:"
    dotnet --version
    echo "--------------------------------------------------"
    echo "Helm:"
    helm version
    echo "--------------------------------------------------"
    echo "JQ:"
    jq --version
    echo "--------------------------------------------------"
    echo "oras:"
    oras version
    echo "--------------------------------------------------"
    echo "regctl:"
    regctl version
    echo "--------------------------------------------------"
    echo "Net-tools:"
    ifconfig -V
    echo "--------------------------------------------------"
    echo "dive:"
    dive version
    echo "--------------------------------------------------"
    echo "traceroute:"
    #traceroute --version
    echo "--------------------------------------------------"
    echo "tree:"
    tree --version
    echo "--------------------------------------------------"
    echo "rsync:"
    rsync --version
    echo "--------------------------------------------------"
    if [[ "$DOCKER_INSTALL" == true ]]; then 
        echo "Docker:"
        docker --version
        echo "--------------------------------------------------"
    fi 
}

main() {
    echo "Starting install of pre-reqs..."
    output_version
    install_az
    install_linux_modules_extra_azure
    install_dotnet
    install_helm
    install_jq
    if [[ "$DOCKER_INSTALL" == true ]]; then 
        install_docker
    else
        echo "Skipping docker install..."
    fi 
    install_oras
    install_rsync
    install_regctl
    install_net_tools
    if [[ "$DOCKER_INSTALL" == true ]]; then 
        configure_docker
    else
        echo "Skipping Docker Configuration..."
    fi 
    install_dive
    install_tree
    validate_versions
    echo ""
    echo "Finished install of pre-reqs..."
}

main
