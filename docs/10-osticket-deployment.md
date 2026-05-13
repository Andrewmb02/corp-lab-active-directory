# osTicket Self-Hosted Helpdesk Deployment

Deployment of osTicket on Ubuntu Server 24.04 in Azure as the helpdesk
component of the corp.local lab environment. Built as part of the broader
small-enterprise IT simulation, with the goal of integrating with the
existing Active Directory for unified identity management.

## Overview

osTicket is an open-source ticketing system used by thousands of small to
mid-sized organizations. For this lab it provides the IT support workflow
component — ticket submission, triage, assignment, escalation, and
resolution — alongside the Active Directory domain that handles identity
and access management.

## Architecture decisions

| Decision | Rationale |
|---|---|
| Self-hosted on Ubuntu (not Spiceworks Cloud) | Practical experience with LAMP stack administration and a fully self-managed deployment |
| Deployed in East US 2 (separate from AD in East US) | Cross-region architecture provides exposure to multi-region networking patterns common in enterprise environments. Driven initially by Azure for Students BS-family vCPU quota limits in East US |
| Standard_B1s VM size | Sufficient for lab-scale ticket volumes; minimizes credit consumption |
| Apache + MariaDB + PHP 8.3 | Standard LAMP stack on a modern Ubuntu LTS release |
| Public IP with NSG-scoped access | SSH and HTTP allowed only from home IP, matching the security posture of the AD VMs |

## Infrastructure

```
ticket-vnet (10.1.0.0/16) in East US 2
└── ticket-subnet (10.1.1.0/24)
    └── TICKET01 (10.1.1.4)
        ├── Ubuntu Server 24.04 LTS (Gen2, x64)
        ├── Standard_B1s (1 vCPU, 1 GB RAM)
        ├── Apache 2.4
        ├── MariaDB 10.x
        ├── PHP 8.3 with required extensions
        └── osTicket 1.18.2
```

## VM provisioning

VM created via the Azure portal with the following specifications:

| Setting | Value |
|---|---|
| Resource group | ad-lab |
| Region | East US 2 |
| Image | Ubuntu Server 24.04 LTS - x64 Gen2 |
| Size | Standard_B1s |
| Authentication | SSH public key |
| Username | azureuser |
| Inbound ports | SSH (22), HTTP (80) |
| Virtual network | ticket-vnet (new, 10.1.0.0/16) |
| Subnet | ticket-subnet (10.1.1.0/24) |
| Auto-shutdown | Enabled, 23:00 local |

A new VNet was created in East US 2 because Azure VNets are region-bound.
Cross-region connectivity to the existing `ad-vnet` (East US) is established
via VNet peering — see `docs/06-cross-region-ad-integration.md`.

## LAMP stack installation

System prerequisites and the LAMP stack were installed in a single command:

```bash
sudo apt update && sudo apt upgrade -y && sudo apt install -y \
  apache2 mariadb-server \
  php php-cli php-mysql php-gd php-imap php-xml php-intl \
  php-apcu php-mbstring php-curl php-zip php-ldap \
  libapache2-mod-php unzip wget
```

The `php-ldap` extension was required for the LDAP plugin (see Section on
osTicket plugins) and was added after the initial install when the
plugin's prerequisite check flagged it as missing.

## MariaDB hardening

Standard hardening via `mysql_secure_installation`:

- Set root password
- Disabled anonymous users
- Disabled remote root login
- Removed test database
- Reloaded privileges

A dedicated database and user were created for osTicket, following
least-privilege principles:

```sql
CREATE DATABASE osticket CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'osticket_user'@'localhost' IDENTIFIED BY '<strong-password>';
GRANT ALL PRIVILEGES ON osticket.* TO 'osticket_user'@'localhost';
FLUSH PRIVILEGES;
```

The osticket_user account is restricted to localhost connections and can
only act on the osticket database — never the system tables or other
databases.

## osTicket installation

osTicket 1.18.2 was downloaded from the official GitHub releases:

```bash
cd /tmp
wget https://github.com/osTicket/osTicket/releases/download/v1.18.2/osTicket-v1.18.2.zip
unzip osTicket-v1.18.2.zip -d osticket
sudo mv osticket/upload /var/www/osticket
sudo cp /var/www/osticket/include/ost-sampleconfig.php /var/www/osticket/include/ost-config.php
sudo chown -R www-data:www-data /var/www/osticket
sudo chmod 0666 /var/www/osticket/include/ost-config.php
```

The config file was temporarily made world-writable so the web installer
could write to it, then locked back down to 0644 immediately after the
install completed.

## Apache virtual host

A dedicated virtual host configuration was created for the osTicket site
and the default Apache welcome page was disabled:

```apache
<VirtualHost *:80>
    ServerAdmin admin@corp.local
    DocumentRoot /var/www/osticket
    <Directory /var/www/osticket>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/osticket-error.log
    CustomLog ${APACHE_LOG_DIR}/osticket-access.log combined
</VirtualHost>
```

mod_rewrite was enabled for osTicket's URL handling, and the default
Apache site was disabled:

```bash
sudo a2dissite 000-default.conf
sudo a2ensite osticket.conf
sudo a2enmod rewrite
sudo systemctl restart apache2
```

## Web-based installer

The osTicket web installer was run at `http://<TICKET01-public-IP>/` and
configured with:

- Helpdesk Name: Corp Lab Help Desk
- Default Email: helpdesk@corp.local
- Admin user with strong password
- Database connection to localhost using the dedicated osticket_user

## Post-install hardening

Immediately after the installer completed, two cleanup commands were run:

```bash
sudo chmod 0644 /var/www/osticket/include/ost-config.php
sudo rm -rf /var/www/osticket/setup
```

The first restores read-only permissions on the configuration file so a
compromised Apache process cannot rewrite it. The second removes the
installer directory entirely — without this, anyone reaching the public IP
could navigate to /setup/install.php and reinstall the application,
seizing admin access.

## Access URLs

- Staff Control Panel: `http://<TICKET01-public-IP>/scp/`
- End-User Portal: `http://<TICKET01-public-IP>/`

Subsequent integration work (LDAPS authentication against Active Directory)
is covered in `docs/06-cross-region-ad-integration.md`.

## Operational notes

- Apache logs: `/var/log/apache2/osticket-error.log` and `/var/log/apache2/osticket-access.log`
- osTicket internal logs: Admin Panel → Dashboard → System Logs
- Config file: `/var/www/osticket/include/ost-config.php`
- Plugins directory: `/var/www/osticket/include/plugins/`
- Web root: `/var/www/osticket/`

## Future improvements

- Migrate from HTTP to HTTPS with Let's Encrypt or an internal CA certificate
- Configure automated database backups (mysqldump to a separate storage account)
- Set up email integration (SMTP outbound for ticket notifications)
- Move from password-based MariaDB auth to socket-based authentication for the local osticket_user
- Implement Fail2ban for SSH and Apache to mitigate brute-force attempts
