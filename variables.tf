# Builds Open Source LAMP stack on OCI Classic IaaS.
# Includes 3 network zones: Management (Public), Application (Public), & Database (Private) - Role-specific instances are distributed across the zones.
#
# Note: Initial version created by: cameron.senese@oracle.com

### Credentials ###
  variable "ociUser" {
      description = "Username - OCI-Classic user account with Compute_Operations rights"
  }
  variable "ociPass" {
      description = "Password - OCI-Classic user account with Compute_Operations rights"
  }
  variable "idDomain" {
      description = "Platform version dependent - Either tenancy ID Domain or Compute Service Instance ID"
  }
  variable "apiEndpoint" {
      description = "OCI-Classic Compute tenancy REST Endpoint URL"
  }

### Keys ###
  variable sshUser {
    description = "Username - Account for ssh access to the image"
    default     = "opc"
  }
  variable sshPrivateKey {
    description = "File location of the ssh private key"
    default     = "./ssh/id_rsa"
  }
  variable sshPublicKey {
    description = "File location of the ssh public key"
    default     = "./ssh/id_rsa.pub"
  }