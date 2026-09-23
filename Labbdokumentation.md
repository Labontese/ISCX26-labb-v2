# Labbdokumentation: virtuell labbmiljö och nätverk

**Daniel Gustafsson**
Chas Academy, ISCX26
September 2026

> (mall) Rader som börjar med `> (mall)` är instruktioner till mig själv. De tas bort
> (mall) när avsnittet är klart. Ett avsnitt är inte klart så länge en sådan rad finns kvar.

---

## 1. Introduktion och plan

### 1.1 Vad uppgiften går ut på

Jag bygger en liten labbmiljö med två virtuella maskiner, en Linuxserver och en
Windowsserver, på ett gemensamt internt nät med fasta IP-adresser. På dem utför
jag grundläggande kommandoradsarbete med mappar, grupper och behörigheter.
Arbetet versioneras i Git, och jag granskar ett AI-svar kritiskt genom att
testa det i stället för att lita på det.

### 1.2 Vad som ska bevisas

| Del | Kursmål | Vad som måste finnas i dokumentet |
|---|---|---|
| 1 | 10 | Repo skapat med `git init`, minst fem commits som speglar arbetet |
| 2 | 8 | Två VM på gemensamt internt nät, statiska adresser, nätverkstabell |
| 3 | 9 | Linux: mapp, grupp, 750/640, `ls -la`, ping, `ip addr show` |
| 3 | 9 | Windows: mapp, `Get-Acl`, ping, `ipconfig /all` |
| 4 | 11 | Prompt och svar ordagrant, verifiering, egen kritisk granskning |

### 1.3 Miljö och avgränsning

Hypervisor är min Proxmox-server. Maskinerna skapas med Terraform, så att
miljön finns som kod i repot. Windows installeras från ISO för hand, eftersom
det inte finns någon färdig mall.

| | Linux | Windows |
|---|---|---|
| VM-id | 311 | 312 |
| Hostname | `iscx26-linux` | `iscx26-win` |
| OS | Ubuntu Server 26.04 | Windows Server 2025 |
| Labbnät | 192.168.110.50/24 | 192.168.110.51/24 |
| Driftnät | DHCP på VLAN 70 | DHCP på VLAN 70 |

Labbnätet är en ny OVS-brygga, `ovsbr-iscx26b`, utan fysisk port. Den skiljs
från bryggan i mitt tidigare labb, och subnätet `192.168.110.0/24` krockar inte
med något annat.

**Rörs inte:** övriga virtuella maskiner på servern, bryggorna `vmbr0` och
`vmbr1`, filen `/etc/network/interfaces`, och det tidigare labbet (VM 301 och
302).

**Lämnas utanför:** härdning av Windows-ACL:en. Uppgiften ber mig dokumentera
den, inte ändra den.

### 1.4 Risker jag känner till i förväg

Jag har byggt en liknande miljö förut och vet var det brukar gå fel. Varje risk
har en åtgärd som ska vara på plats innan jag når det steget.

| Risk | Åtgärd |
|---|---|
| cloud-init skriver aldrig någon nätverkskonfiguration om korten pekas ut med MAC-adress | Peka ut korten med namn, `ens18` och `ens19` |
| Terraform vill stänga av Windows för att `q35` blivit `pc-q35-11.0+pve2` | `machine` i `ignore_changes` från början |
| En ändrad kommentar i cloud-init-filen får Terraform att skapa om Linuxservern | `source_raw` i `ignore_changes` på snippets |
| Gästagenten i Windows kör men svarar inte | Installera hela `virtio-win-gt-x64.msi`, inte bara agenten |
| Windows klassar nätet som publikt och blockerar allt | Sätt nätverksprofilen till privat |
| Ping mot Windows får inget svar | Slå på brandväggsregeln `FPS-ICMP4-ERQ-In` |
| Tabellen visar ett hostname som inte stämmer | `Rename-Computer` och omstart innan tabellen fylls i |
| Minnet tar slut på servern | 20 GB ledigt, labbet behöver 10 GB. Kontrolleras innan `apply` |

Ingen `terraform apply` körs utan att planen först är läst rad för rad.

## 2. Miljö och nätverk

### 2.1 Nätverkstabell

> (mall) Fylls i ur utskrifter, inte ur minnet. Hostnamnet här är hostnamnet i
> (mall) `hostnamectl` respektive `hostname` längre ner.

| Hostname | Operativsystem | IP-adress | Subnätmask | Standard gateway |
|---|---|---|---|---|
| | | | | |

### 2.2 Logiskt diagram

> (mall) Mermaid. Vad pratar med vad, vilka nät, var stoppar det.

```mermaid
flowchart LR
```

### 2.3 Fysisk placering

> (mall) draw.io. Källfil i `diagram/`, export i `bilder/`. Okomprimerad.

> (mall) ![Kort beskrivning](bilder/filnamn.png)

### 2.4 Hur miljön skapades

> (mall) Kommando, utskrift, förklaring. Kod i eget bibliotek om den finns.

### 2.5 Verifiering

> (mall) Bevis att miljön gör det den ska. Ping åt båda hållen, adresser avlästa
> (mall) inifrån maskinerna, inte antagna.

### 2.6 Det som gick fel, och hur jag hittade det

> (mall) Om inget gick fel: skriv det, och vad som kontrollerades. Om något gick fel:
> (mall) symptom, steg för steg till orsak, rättning, verifiering efteråt.

---

## 3. Genomförande

> (mall) Ett underavsnitt per moment i uppgiften. Samma form varje gång:
> (mall) kommando, ordagrann utskrift, en mening om vad utskriften bevisar.
> (mall) Räcker inte listningen som bevis, testa skarpt (till exempel som en
> (mall) användare utan rättighet) och visa nekandet.

### 3.1

### 3.2

---

## 4. Git och versionshantering

### 4.1 Struktur

```
<reponamn>/
├── Labbdokumentation.md
├── README.md
├── bilder/
└── diagram/
```

### 4.2 Vad som inte ligger i repot

> (mall) Vad `.gitignore` stoppar och varför. Bevis med `git check-ignore -v`.

### 4.3 Repository

> (mall) Länk. Privat eller publikt, och när det byts.

### 4.4 Commit-historik

> (mall) Regenereras ALLRA SIST, med noten att den är en commit kortare än repot.

```
$ git log --pretty=format:'%h  %ad  %s' --date=format:'%Y-%m-%d %H:%M'
```

---

## 5. AI-stöd och granskning

> (mall) Bara om uppgiften kräver det. Prompt ordagrant, svar ordagrant, verifiering
> (mall) på en kopia, mätningar, och sist min egen bedömning i egen text.

### 5.1 Verktyg och prompt

### 5.2 Svaret, ordagrant

### 5.3 Så verifierade jag

### 5.4 Vad mätningarna visade

### 5.5 Min bedömning

---

## 6. Reflektion

### 6.1 Vad jag inte testade

> (mall) Ärligt. Det som lämnades oprövat och varför.

### 6.2 Vad jag tar med mig

> (mall) Tre punkter räcker. Konkreta, inte "jag lärde mig mycket".
