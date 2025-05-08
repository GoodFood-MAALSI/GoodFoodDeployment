# GoodFood

This README provides step-by-step instructions to set up the development environment for the **GoodFood** application. It covers the installation of required tools and how to launch the infrastructure in development mode using Skaffold.

---

## Prerequisites

Before running the application, ensure the following tools are installed on your system.

### 1. Install Docker

Docker is required to build and manage container images for the GoodFood application.

- **Windows**:
  1. Download Docker Desktop: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop).
  2. Install Docker Desktop and enable the WSL 2 backend if prompted.
  3. Launch Docker Desktop and ensure it is running.
  4. Verify the installation by running:
     ```bash
     docker --version
     ```

- **Linux**:
  1. Update your package index and install Docker using the following commands:
     ```bash
     sudo apt-get update
     sudo apt-get install -y docker.io
     sudo systemctl start docker
     sudo systemctl enable docker
     sudo usermod -aG docker $USER
     docker --version
     ```

---

### 2. Install Minikube

Minikube is used to run a local Kubernetes cluster.

- **Windows**:
  1. Download the Minikube installer from the [Minikube Releases](https://github.com/kubernetes/minikube/releases) page.
  2. Rename the downloaded file to `minikube.exe`.
  3. Move it to a folder like `C:\Program Files\Minikube` and add that folder to your system PATH.
  4. Verify the installation:
     ```bash
     minikube version
     ```

- **Linux**:
  ```bash
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install minikube-linux-amd64 /usr/local/bin/minikube
  minikube version

---

### 3. Install kubectl

kubectl is the command-line tool used to interact with the Kubernetes cluster.

- **Windows**:
  1. Download the latest release from the [kubectl Releases](https://kubernetes.io/docs/tasks/tools/).
  2. Add the downloaded binary to a folder in your system PATH.
  3. Verify the installation:
     ```bash
     kubectl version --client
     ```

- **Linux**:
  ```bash
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  kubectl version --client


---

### 4. Install Skaffold

Skaffold is a command-line tool that automates the workflow for building, deploying, and managing Kubernetes applications.

- **Windows**:
  1. Download the latest Skaffold release from the [Skaffold Releases](https://github.com/GoogleContainerTools/skaffold/releases).
  2. Rename the downloaded file to `skaffold.exe`.
  3. Move it to a folder like `C:\Program Files\Skaffold` and add that folder to your system PATH.
  4. Verify the installation:
     ```bash
     skaffold version
     ```

- **Linux**:
  ```bash
  curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
  chmod +x skaffold
  sudo mv skaffold /usr/local/bin/
  skaffold version

---

### 4. Start Cluster Minikube

- **Windows**:
    ```bash
    cd /GoodFood/subrepos/GoodFoodDeployment
- To deploy all pods:
    ```bash
    .\start.cmd
- To deploy specific pod:
    ```bash
    .\start.cmd restaurateur
- To deploy multiple pods:
    ```bash
    .\start.cmd restaurateur livreur

- **Linux**:
    ```bash
    cd /GoodFood/subrepos/GoodFoodDeployment
- To deploy all pods:
    ```bash
    .\start.sh
- To deploy specific pod:
    ```bash
    .\start.sh restaurateur
- To deploy client & order:
    ```bash
    .\start.sh client-order

---

### 5. Access the Application

Once the application is running, you can access the following endpoints in your browser:

- [http://localhost:8080/dashboard/](http://localhost:8080/dashboard/)
- [http://localhost:8080/restaurateur/](http://localhost:8080/restaurateur/)
- [http://localhost:8080/restaurateur/api](http://localhost:8080/restaurateur/api)
- [http://localhost:8080/restaurateur/api/swagger](http://localhost:8080/restaurateur/api/swagger)

---

### 6. Stop Cluster Minikube

- **Windows**:
    ```bash
    cd /GoodFood/subrepos/GoodFoodDeployment
    .\stop.cmd

- **Linux**:
    ```bash
    cd /GoodFood/subrepos/GoodFoodDeployment
    .\stop.sh