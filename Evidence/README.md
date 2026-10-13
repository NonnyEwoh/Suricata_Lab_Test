# Suricata IDS Practical Lab

A beginner-friendly, authorized-lab exercise for installing Suricata, writing a custom detection rule, generating TCP traffic with Netcat, and analyzing alerts in `fast.log` and `eve.json`.

> **Scope:** Perform this lab only on systems, virtual machines, and networks you own or are explicitly authorized to test.

## What you will build

- Suricata IDS sensor
- A custom rule that detects the lab string `SURICATA-LAB-TEST` sent to TCP/4444
- A Netcat listener/client pair for controlled traffic generation
- Alert analysis using `grep` and `jq`
- Evidence suitable for a cybersecurity GitHub portfolio

## Lab topology

```text
+-------------------+             TCP/4444              +----------------------+
| CLIENT VM         | --------------------------------> | SURICATA SENSOR VM   |
| <CLIENT_IP>       |    SURICATA-LAB-TEST payload      | <SURICATA_IP>        |
| Netcat client     |                                   | Kali/Debian +        |
+-------------------+                                   | Suricata + Netcat    |
                                                        +----------------------+
```

If your lab uses a separate server/listener VM, place it behind the sensor and keep the same concepts: the sensor must be able to see the traffic.

## Quick start

On the Suricata sensor:

```bash
sudo apt update
sudo apt install -y suricata jq netcat-openbsd
ip -br addr
sudo suricata --build-info | head -n 20
```

Identify the interface carrying lab traffic and replace `<INTERFACE>`.

Create the rule:

```bash
sudo install -d -m 0755 /etc/suricata/rules
sudo cp rules/local.rules /etc/suricata/rules/local.rules
sudo suricata -T -c /etc/suricata/suricata.yaml -S /etc/suricata/rules/local.rules
```

Start Suricata:

```bash
sudo suricata -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules \
  -i <INTERFACE> \
  -l /var/log/suricata
```

On the sensor, in another terminal:

```bash
nc -lvnp 4444
```

From the client:

```bash
printf 'SURICATA-LAB-TEST\n' | nc <SURICATA_IP> 4444
```

Then inspect:

```bash
sudo grep -F "SURICATA LAB" /var/log/suricata/fast.log
sudo jq 'select(.event_type=="alert") | {timestamp,src_ip,src_port,dest_ip,dest_port,signature:.alert.signature,severity:.alert.severity}' /var/log/suricata/eve.json
```

## Expected result

You should see an alert containing the custom signature:

`SURICATA LAB Netcat Test`

The EVE record should contain `event_type: "alert"` and source/destination IP and port information.

## Portfolio evidence

Capture screenshots showing:

1. `ip -br addr` with the selected interface/IP.
2. `suricata -T` returning successful configuration validation.
3. Netcat listener and client traffic.
4. `fast.log` containing the custom alert.
5. `eve.json` parsed with `jq`.
6. A short written analysis explaining what triggered the rule.

See `docs/LAB_MANUAL.md` for the complete walkthrough and troubleshooting guide.

## Project structure

```text
suricata-ids-lab/
├── README.md
├── .gitignore
├── LICENSE
├── rules/
│   └── local.rules
├── configs/
│   └── suricata-lab.yaml.example
├── scripts/
│   └── generate_netcat_traffic.sh
├── sample-output/
│   └── sample-alert.json
├── docs/
│   ├── LAB_MANUAL.md
│   └── COMMAND_CHEATSHEET.md
└── screenshots/
    └── README.md
```

## GitHub usage

```bash
git init
git add .
git commit -m "Add Suricata IDS practical lab"
git branch -M main
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```

Do not commit private IP addresses, credentials, PCAPs containing sensitive traffic, or real production logs.

## References

- Suricata documentation: https://docs.suricata.io/
- Suricata 8 installation guide: https://docs.suricata.io/en/suricata-8.0.7/install.html
- Suricata configuration: https://docs.suricata.io/en/suricata-8.0.7/configuration/suricata-yaml.html
- EVE JSON format: https://docs.suricata.io/en/suricata-8.0.7/output/eve/eve-json-format.html
