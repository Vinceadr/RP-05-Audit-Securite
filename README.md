# RP-05 — Audit et Sécurité Réseau

**Réalisation Professionnelle — BTS SIO SISR**
**ANDREO Vincent — IRIS Nice — 2026**

---

## Contexte et objectifs

Dans le cadre du BTS SIO option SISR, cette réalisation professionnelle porte sur l'**audit complet de la sécurité d'une infrastructure réseau virtualisée** hébergée sur un hyperviseur KVM/QEMU sous Debian 12.

L'objectif était d'identifier les vulnérabilités, de déployer une architecture sécurisée (DMZ + pare-feu nftables), de durcir les hôtes, puis de valider l'ensemble par des tests d'intrusion.

---

## Architecture déployée

```
<svg width="680" height="500" viewBox="0 0 680 500" xmlns="http://www.w3.org/2000/svg" role="img">
  <title>Architecture réseau avec pare-feu nftables</title>
  <desc>Internet connecté à un pare-feu Debian 12 nftables, séparant une DMZ et un LAN interne.</desc>

  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M2 1L8 5L2 9" fill="none" stroke="#888780" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </marker>
  </defs>

  <!-- Background -->
  <rect width="680" height="500" fill="#ffffff" rx="12"/>

  <!-- Internet -->
  <rect x="240" y="20" width="200" height="52" rx="8" fill="#E6F1FB" stroke="#378ADD" stroke-width="0.8"/>
  <text x="340" y="43" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#0C447C">Internet</text>
  <text x="340" y="61" text-anchor="middle" font-family="monospace" font-size="11" fill="#185FA5">Trafic entrant / sortant</text>

  <!-- Arrow Internet ↕ Firewall -->
  <line x1="340" y1="72" x2="340" y2="115" stroke="#888780" stroke-width="1.2" marker-end="url(#arrow)" marker-start="url(#arrow)"/>

  <!-- Firewall -->
  <rect x="175" y="117" width="330" height="60" rx="8" fill="#FAECE7" stroke="#D85A30" stroke-width="0.8"/>
  <text x="340" y="140" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#712B13">Debian 12 — nftables</text>
  <text x="340" y="158" text-anchor="middle" font-family="monospace" font-size="11" fill="#993C1D">192.168.40.3 · Filtrage stateful · NAT</text>

  <!-- Fork left → DMZ -->
  <path d="M280 177 L280 218 L165 218 L165 252" fill="none" stroke="#B4B2A9" stroke-width="1.2" marker-end="url(#arrow)"/>
  <!-- Fork right → LAN -->
  <path d="M400 177 L400 218 L515 218 L515 252" fill="none" stroke="#B4B2A9" stroke-width="1.2" marker-end="url(#arrow)"/>

  <!-- Zone labels -->
  <text x="165" y="212" text-anchor="middle" font-family="monospace" font-size="10" fill="#888780">DMZ</text>
  <text x="515" y="212" text-anchor="middle" font-family="monospace" font-size="10" fill="#888780">LAN interne</text>

  <!-- DMZ container -->
  <rect x="48" y="250" width="234" height="215" rx="12" fill="#F8F8F6" stroke="#B4B2A9" stroke-width="0.8" stroke-dasharray="6 4"/>
  <text x="165" y="270" text-anchor="middle" font-family="monospace" font-size="10" fill="#888780">Zone démilitarisée</text>

  <!-- LAN container -->
  <rect x="398" y="250" width="234" height="215" rx="12" fill="#F8F8F6" stroke="#B4B2A9" stroke-width="0.8" stroke-dasharray="6 4"/>
  <text x="515" y="270" text-anchor="middle" font-family="monospace" font-size="10" fill="#888780">Réseau interne</text>

  <!-- Nginx -->
  <rect x="68" y="285" width="194" height="58" rx="8" fill="#E1F5EE" stroke="#1D9E75" stroke-width="0.8"/>
  <text x="165" y="308" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#085041">Serveur web Nginx</text>
  <text x="165" y="327" text-anchor="middle" font-family="monospace" font-size="11" fill="#0F6E56">Ports 80, 443</text>

  <!-- Arrow Nginx → MySQL -->
  <line x1="165" y1="343" x2="165" y2="374" stroke="#B4B2A9" stroke-width="1" stroke-dasharray="4 3" marker-end="url(#arrow)"/>

  <!-- MySQL -->
  <rect x="68" y="375" width="194" height="58" rx="8" fill="#EEEDFE" stroke="#7F77DD" stroke-width="0.8"/>
  <text x="165" y="398" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#3C3489">Serveur MySQL</text>
  <text x="165" y="417" text-anchor="middle" font-family="monospace" font-size="11" fill="#534AB7">Port 3306</text>

  <!-- LAN workstations -->
  <rect x="418" y="285" width="194" height="58" rx="8" fill="#EAF3DE" stroke="#639922" stroke-width="0.8"/>
  <text x="515" y="308" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#27500A">Postes de travail</text>
  <text x="515" y="327" text-anchor="middle" font-family="monospace" font-size="11" fill="#3B6D11">192.168.10.0/24</text>

  <!-- Arrow workstations → services -->
  <line x1="515" y1="343" x2="515" y2="374" stroke="#B4B2A9" stroke-width="1" stroke-dasharray="4 3" marker-end="url(#arrow)"/>

  <!-- LAN services -->
  <rect x="418" y="375" width="194" height="58" rx="8" fill="#FAEEDA" stroke="#BA7517" stroke-width="0.8"/>
  <text x="515" y="398" text-anchor="middle" font-family="monospace" font-size="13" font-weight="600" fill="#633806">Services internes</text>
  <text x="515" y="417" text-anchor="middle" font-family="monospace" font-size="11" fill="#854F0B">AD, NFS, SMTP…</text>

</svg>

```
---

## Déroulement en 4 phases

### Phase 1 — Audit initial (Semaine 1)

- Découverte réseau complète avec **Nmap** (scan SYN, UDP, scripts NSE)
- Scan de vulnérabilités avec **OpenVAS** sur tous les hôtes
- **38 CVE identifiées** dont 8 critiques (CVSS ≥ 9.0)
- Rapport d'audit complet avec priorisation des risques (CVSS)

### Phase 2 — Déploiement nftables + DMZ (Semaine 2)

- Installation et configuration de **nftables** sur Debian 12 (pare-feu Linux kernel netfilter)
- Création de la **DMZ** (zone démilitarisée) avec interfaces eth0/eth1/eth2
- Politique par défaut : **deny-all** (drop toutes les connexions non autorisées)
- Règles NAT, port forwarding contrôlé, logging des paquets bloqués
- Fichier de configuration : `/etc/nftables.conf`

### Phase 3 — Durcissement CIS Benchmark (Semaine 3)

- Application des recommandations **CIS Benchmark Debian Linux**
- Configuration SSH : port non standard, désactivation root, authentification par clé uniquement
- Déploiement **Suricata** (IDS/IPS multi-thread) avec règles ET/Open
- Déploiement **CrowdSec** avec collections : `crowdsecurity/linux`, `crowdsecurity/sshd`, `crowdsecurity/nginx`
- Score **Lynis : 79/100** (vs 42/100 avant durcissement)
- Gestion des exceptions documentées : `ip_forward` (requis par KVM), faux positifs CVE

### Phase 4 — Tests d'intrusion (Semaine 4)

- **12 tests d'intrusion** exécutés sur l'infrastructure durcie
- Tests : scan évasif Nmap, brute-force SSH (Hydra), exploitation web (SQLMap, Nikto), traversée DMZ
- **Résultat : 12/12 PASS** — aucune intrusion aboutie
- Rapport de pentest avec preuves d'écran et recommandations finales

---

## Résultats obtenus

| Indicateur | Avant | Après |
|------------|-------|-------|
| Score Lynis | 42/100 | **79/100** |
| CVE critiques ouvertes | 8 | **0** |
| Ports exposés inutilement | 17 | **3** |
| Tests d'intrusion réussis | N/A | **0/12** |
| Services avec auth par clé | 0% | **100%** |

---

## Fichiers du dépôt

| Fichier | Description |
|---------|-------------|
| `RP-05-ANDREO-Vincent.docx` | Rapport technique complet (4 phases, scripts, captures) |
| `Fiche-RP05-ANDREO-Vincent.docx` | Fiche officielle ANNEXE 7-1-A (formulaire BTS) |
| `Présentation-5min-RP05-ANDREO-Vincent.docx` | Texte de présentation orale 5 minutes |

---

## Commandes clés

```bash
# Vérifier les règles nftables actives
nft list ruleset

# Lancer un audit Lynis complet
lynis audit system --quick

# Scanner l'infrastructure avec Nmap
nmap -sS -sV -O -A --script vuln 192.168.40.0/24

# Vérifier le statut CrowdSec
cscli metrics
cscli decisions list

# Voir les alertes Suricata en temps réel
tail -f /var/log/suricata/fast.log
```

---

## Compétences validées

- **A1.1** — Analyse du besoin et définition du périmètre de sécurité
- **A1.2** — Mise en place d'une architecture sécurisée (pare-feu, DMZ)
- **A3.1** — Administration et sécurisation des équipements réseau
- **A3.3** — Mise en œuvre de solutions de détection d'intrusion
- **A5.1** — Participation aux tests de sécurité (pentest)

---

## Environnement technique

- **OS Hyperviseur** : Debian 12 (Bookworm) — KVM/QEMU
- **OS VMs** : Debian 12 sur toutes les machines
- **Réseau** : 192.168.40.0/24 (LAN), DMZ isolée
- **Virtualisation** : `virsh`, `virt-manager`
- **École** : IRIS Nice — Promotion BTS SIO SISR 2025-2026

---

*Réalisation professionnelle validée dans le cadre de l'examen E5/E6 BTS SIO.*
