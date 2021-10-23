variable "client_secret" {
  description = "The Client Secret for the service principal"
  default     = "0000000000000"
}
variable "subscription_id" {
  description = "The subscription id for the deployment"
  default     = "00000-0000-00000-000000-00000000"
}

variable "rg_name" {
  description = "resource group name for the deployment"
  default     = "moodle"
}

variable "location" {
  description = "location for resources deployment"
  default     = "West Europe"
}

variable "nsg-name" {
  description = "network security group name"
  default     = "moodle-nsg"
}

variable "vnet_name" {
  description = "virtual network name"
  default     = "moodle"
}

variable "vnet_address_space" {
  description = "virtual network address space"
  default     = "10.0.0.0/16"
}

variable "vmss_subnet" {
  description = "virtual machine scale set subnet name "
  default     = "vmss_subnet"
}

variable "vmss_subnet_addr" {
  description = "virtual machine scale set subnet range "
  default     = "10.0.1.0/24"
}

variable "netapp_subnet" {
  description = "Netapp account subnet name "
  default     = "netapp_subnet"
}

variable "netapp_subnet_addr" {
  description = "Netapp account subnet range "
  default     = "10.0.2.0/24"
}

variable "appgw_subnet" {
  description = "Application gateway subnet name "
  default     = "appgw_subnet"
}

variable "appgw_subnet_addr" {
  description = "Application gateway subnet range "
  default     = "10.0.3.0/24"
}

variable "mysql_server_name" {
  description = "azure mysql server name "
  default     = "moodledep01"
}

variable "mysql_admin_login" {
  description = "azure mysql server admin login "
  default     = "moodle"
}

variable "mysql_admin_password" {
  description = "azure mysql server admin password "
  default     = "Pa$$w0rd101102!"
}

variable "netapp_account_name" {
  description = "netapp account name "
  default     = "moodle"
}

variable "netapp_account_pool" {
  description = "netapp account pool name "
  default     = "moodlepool01"
}

variable "netapp_volume_name" {
  description = "netapp account volume name "
  default     = "moodlevol01"
}


variable "vm_name" {
  description = "virtual machine name "
  default     = "moodle-vm"
}

variable "appgw_name" {
  description = "application gateway name "
  default     = "moodle-appgw"
}

variable "redis_name" {
  description = "Redis Cache name "
  default     = "moodle-redis"
}
