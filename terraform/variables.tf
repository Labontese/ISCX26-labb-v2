variable "proxmox_endpoint" {
  description = "Proxmox API-adress, till exempel https://10.10.0.3:8006"
  type        = string
}

variable "proxmox_node_address" {
  description = "IP-adress till Proxmox-noden som providern ansluter till via SSH"
  type        = string
  default     = "10.10.0.3"
}

variable "proxmox_token_id" {
  description = "API-token på formatet användare@realm!tokennamn"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Hemligheten som hör till API-token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Publik nyckel som läggs in på Linuxservern"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Sökväg till maskinnyckeln som providern använder mot Proxmox"
  type        = string
}

# --- labbnätet ---------------------------------------------------------------

variable "labbnat" {
  description = "Det isolerade nätet som de två maskinerna delar"
  type        = string
  default     = "192.168.110.0/24"
}

variable "ip_linux" {
  description = "Linuxserverns adress på labbnätet"
  type        = string
  default     = "192.168.110.50/24"
}

variable "ip_windows" {
  description = "Windowsserverns adress på labbnätet, sätts för hand i gästen"
  type        = string
  default     = "192.168.110.51/24"
}

variable "brygga_labb" {
  description = "OVS-bryggan utan fysisk port"
  type        = string
  default     = "ovsbr-iscx26b"
}

variable "brygga_drift" {
  description = "Bryggan för administration och uppdateringar"
  type        = string
  default     = "vmbr1"
}

variable "vlan_drift" {
  description = "VLAN-nummer på driftnätet"
  type        = number
  default     = 70
}
