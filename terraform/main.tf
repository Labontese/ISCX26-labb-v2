# ============================================================================
# Två virtuella maskiner på ett gemensamt, isolerat nät.
#
#   311  iscx26-linux   Ubuntu Server 26.04   192.168.110.50/24
#   312  iscx26-win     Windows Server 2025   192.168.110.51/24
#
# Labbnätet är OVS-bryggan ovsbr-iscx26b, som saknar fysisk port.
# ============================================================================

# ------------------------------------------------------------ cloud-init ----
# Proxmox egen nätverkskonfiguration döper kortet till eth0, men Ubuntu 26.04
# kallar det ens18. Därför skickas en egen konfiguration med.
#
# ignore_changes på source_raw: cloud-init läser filerna en enda gång, vid
# första uppstart. Utan raden räknar Terraform även en ändrad kommentar som
# skäl att ersätta filen, och därmed hela maskinen.
resource "proxmox_virtual_environment_file" "networkdata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = templatefile("${path.module}/cloud-init/linux-networkdata.yaml.tftpl", {
      ip_linux = var.ip_linux
    })
    file_name = "iscx26b-linux-networkdata.yaml"
  }

  lifecycle {
    ignore_changes = [source_raw]
  }
}

resource "proxmox_virtual_environment_file" "userdata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = templatefile("${path.module}/cloud-init/linux-userdata.yaml.tftpl", {
      ssh_public_key = var.ssh_public_key
    })
    file_name = "iscx26b-linux-userdata.yaml"
  }

  lifecycle {
    ignore_changes = [source_raw]
  }
}

# ------------------------------------------------------------ Linuxservern --
resource "proxmox_virtual_environment_vm" "linux" {
  name        = "iscx26-linux"
  description = "ISCX26 labb. Skapad med Terraform."
  node_name   = "pve"
  vm_id       = 311
  tags        = ["iscx26", "labb"]

  clone {
    vm_id = 9001 # mallen ubuntu-2604-cloudinit
    full  = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "zfs-pve"
    interface    = "scsi0"
    size         = 20
    discard      = "on"
  }

  # net0, labbnätet. Blir ens18 i gästen.
  network_device {
    bridge      = var.brygga_labb
    mac_address = "BC:24:11:00:C3:11"
  }

  # net1, driftnätet. Blir ens19. Behövs för att installera
  # qemu-guest-agent, eftersom labbnätet saknar väg ut.
  network_device {
    bridge      = var.brygga_drift
    vlan_id     = var.vlan_drift
    mac_address = "BC:24:11:00:D3:11"
  }

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_data_file_id    = proxmox_virtual_environment_file.userdata.id
    network_data_file_id = proxmox_virtual_environment_file.networkdata.id
  }

  agent {
    enabled = true
    timeout = "3m"
  }
}

# ----------------------------------------------------------- Windowsservern --
# Ingen färdig mall finns, så maskinen skapas tom och Windows installeras
# från ISO för hand.
resource "proxmox_virtual_environment_vm" "windows" {
  name        = "iscx26-win"
  description = "ISCX26 labb. Skapad med Terraform, Windows installerat för hand."
  node_name   = "pve"
  vm_id       = 312
  tags        = ["iscx26", "labb"]

  bios    = "ovmf"
  machine = "q35"

  operating_system {
    type = "win11"
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  efi_disk {
    datastore_id      = "zfs-pve"
    type              = "4m"
    pre_enrolled_keys = true
  }

  tpm_state {
    datastore_id = "zfs-pve"
    version      = "v2.0"
  }

  # SATA och e1000e: drivrutinerna finns inbyggda i Windows installationsprogram.
  disk {
    datastore_id = "zfs-pve"
    interface    = "sata0"
    size         = 60
  }

  # Providern tillåter bara en CD-enhet. Drivrutinsskivan virtio-win hängs
  # därför på som ide3 med qm set innan första start, se started nedan.
  cdrom {
    interface = "ide2"
    file_id   = "local:iso/winserver2025-eval.iso"
  }

  # Skapas avstängd, så att drivrutinsskivan kan monteras innan Windows
  # startar första gången. Då ser installationen båda skivorna direkt.
  started = false

  network_device {
    bridge      = var.brygga_labb
    model       = "e1000e"
    mac_address = "BC:24:11:00:C3:12"
  }

  network_device {
    bridge      = var.brygga_drift
    vlan_id     = var.vlan_drift
    model       = "e1000e"
    mac_address = "BC:24:11:00:D3:12"
  }

  agent {
    enabled = true
    timeout = "3m"
  }

  # Windows sköts för hand efter att maskinen skapats.
  # machine står med för att Proxmox löser upp "q35" till en exakt version,
  # till exempel pc-q35-11.0+pve2. Terraform ser det som en skillnad, och ett
  # byte av maskintyp kräver att maskinen stängs av.
  lifecycle {
    ignore_changes = [cdrom, started, machine]
  }
}

# ------------------------------------------------------------------ utdata --
output "maskiner" {
  value = {
    linux   = { vmid = 311, ip = var.ip_linux }
    windows = { vmid = 312, ip = var.ip_windows }
    labbnat = var.labbnat
  }
}
