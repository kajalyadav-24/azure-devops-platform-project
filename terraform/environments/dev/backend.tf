terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-cloudops-dev"
    storage_account_name = "sttfhzeq5tc7"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"

    use_azuread_auth = true
  }
}

