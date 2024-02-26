## Infrastucture
Deployment scripts to bring Product Consilium online via Azure.  Terraform Cloud manages execution and state while deploying to dev, test, and prod. 

Includes necessary scripting to bring ArgoCD application online and manage deployment between environments.

## Set Up
az role assignment create --assignee <principal-appId> --role "Owner" --scope /subscriptions/<subscription-id>