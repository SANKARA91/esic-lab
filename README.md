# esic-lab

> Infrastructure DevOps sur Azure — provisionnée en IaC, conteneurisée et déployée en CI/CD.

Projet réalisé pour démontrer une maîtrise concrète des outils DevOps : provisioning d'un cluster Kubernetes AKS avec Terraform, conteneurisation d'une application PHP avec Docker, stockage des images sur Azure Container Registry, et pipeline de déploiement automatique via GitHub Actions.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub                               │
│  push → GitHub Actions → build image → push ACR            │
│                              │                              │
│                              ▼                              │
│                     kubectl set image                       │
└──────────────────────────────┼──────────────────────────────┘
                               │
        ┌──────────────────────▼──────────────────────┐
        │               Azure (esic-lab-rg)            │
        │                                              │
        │   ┌─────────────┐     ┌──────────────────┐  │
        │   │     ACR     │────▶│    AKS Cluster   │  │
        │   │esiclabacr   │     │   esic-lab-aks   │  │
        │   └─────────────┘     │                  │  │
        │                       │  Pod 1 │  Pod 2  │  │
        │                       │  esic  │  esic   │  │
        │                       │  -app  │  -app   │  │
        │                       └────────┬─────────┘  │
        │                                │             │
        │                       LoadBalancer (IP pub)  │
        └────────────────────────────────┼─────────────┘
                                         │
                                    Navigateur
```

---

## Stack technique

| Outil | Rôle |
|-------|------|
| Terraform | Provisioning IaC : AKS, ACR, Resource Group, Role Assignment |
| Azure AKS | Cluster Kubernetes managé (1 node Standard_D2s_v3) |
| Azure ACR | Registre Docker privé (stockage des images) |
| Docker | Build de l'image de l'application PHP |
| Kubernetes | Déploiement (2 replicas), Service LoadBalancer, Ingress |
| GitHub Actions | Pipeline CI/CD : build → push ACR → kubectl rollout |

---

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3.0
- [Azure CLI](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli) installé et configuré
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) en cours d'exécution
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installé
- Un compte Azure avec une subscription active
- Un repo GitHub avec les secrets configurés

---

## Installation

### 1. Cloner le repo

```bash
git clone https://github.com/SANKARA91/esic-lab.git
cd esic-lab
```

### 2. Se connecter à Azure

```bash
az login --tenant <TENANT_ID>
az account set --subscription <SUBSCRIPTION_ID>
```

### 3. Provisionner l'infrastructure avec Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Durée estimée : ~5 minutes. À la fin, Terraform affiche les outputs :

```
acr_login_server    = "esiclabacr.azurecr.io"
aks_cluster_name    = "esic-lab-aks"
resource_group_name = "esic-lab-rg"
```

### 4. Récupérer le kubeconfig

```bash
az aks get-credentials --resource-group esic-lab-rg --name esic-lab-aks
kubectl get nodes
```

Le node doit apparaître en état `Ready`.

### 5. Builder et pusher l'image Docker

```bash
cd ..
az acr login --name esiclabacr
docker build -t esiclabacr.azurecr.io/esic-app:latest ./app
docker push esiclabacr.azurecr.io/esic-app:latest
```

### 6. Déployer sur Kubernetes

```bash
kubectl apply -f k8s/
kubectl get svc esic-app-svc
```

Attendez l'`EXTERNAL-IP` puis ouvrez l'URL dans le navigateur.

---

## Pipeline CI/CD

Le pipeline GitHub Actions se déclenche automatiquement à chaque `push` sur `main` :

```
push → checkout → login ACR → build image → push image → set AKS context → kubectl apply → rollout status
```

### Secrets GitHub à configurer

| Secret | Valeur |
|--------|--------|
| `ACR_USERNAME` | Username de l'ACR (`esiclabacr`) |
| `ACR_PASSWORD` | Password de l'ACR |
| `AZURE_CREDENTIALS` | JSON du Service Principal Azure |

Générer les credentials Azure :

```bash
az ad sp create-for-rbac \
  --name "esic-lab-github" \
  --role contributor \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/esic-lab-rg \
  --json-auth
```

---

## Structure du projet

```
esic-lab/
├── .github/
│   └── workflows/
│       └── deploy.yml        # Pipeline CI/CD GitHub Actions
├── app/
│   ├── Dockerfile            # Image PHP Apache
│   └── index.php             # Application (affiche le hostname du pod)
├── k8s/
│   ├── deployment.yaml       # Deployment 2 replicas
│   ├── service.yaml          # Service LoadBalancer
│   └── ingress.yaml          # Ingress
├── terraform/
│   ├── main.tf               # AKS + ACR + Role Assignment
│   ├── provider.tf           # Provider azurerm
│   ├── variables.tf          # Variables configurables
│   └── outputs.tf            # Outputs post-apply
└── README.md
```

---

## Commandes utiles

```bash
# Voir les pods en cours
kubectl get pods

# Voir les logs d'un pod
kubectl logs <nom-du-pod>

# Vérifier le rollout
kubectl rollout status deployment/esic-app

# Scaler le déploiement
kubectl scale deployment esic-app --replicas=3

# Détruire toute l'infrastructure
terraform destroy
```

---

## Points techniques notables

Identité managée AKS → ACR : Le cluster AKS utilise une `SystemAssigned` identity avec le rôle `AcrPull` sur l'ACR. Aucun credential n'est stocké manuellement — principe du moindre privilège appliqué à l'IaC.

2 replicas : Le déploiement tourne avec 2 pods. En rafraîchissant la page, le hostname affiché alterne entre les deux pods — preuve que le load balancer Kubernetes fonctionne.

Déploiement sans interruption : Le pipeline utilise `kubectl set image` + `kubectl rollout status` pour garantir un rolling update sans downtime.

---

## Améliorations futures

- Ajouter Prometheus + Grafana pour la supervision
- Configurer un Ingress NGINX avec TLS pour HTTPS
- Utiliser un backend Terraform distant (Azure Storage) pour le tfstate en équipe

---

## Auteur

**Boureima SANKARA** — Ingénieur Systèmes, Réseaux & Sécurité Cloud  
[GitHub](https://github.com/SANKARA91) · [LinkedIn](https://linkedin.com/in/boureima-sankara)