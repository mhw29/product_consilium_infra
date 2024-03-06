## Infrastucture
Deployment scripts to bring Product Consilium online via Azure.  Terraform Cloud manages execution and state while deploying to dev, test, and prod. 

Includes necessary scripting to bring ArgoCD application online and manage deployment between environments.

## Set Up
az role assignment create --assignee <principal-appId> --role "Owner" --scope /subscriptions/<subscription-id>

## Set up AKS to access ACR
Need to figure out how to get this into terraform so that pods can properly access ACR as they are created. 
az aks update -n myAKSCluster -g myResourceGroup --attach-acr <acr-resource-id>


