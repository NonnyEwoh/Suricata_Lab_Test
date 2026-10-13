# Suricata IDS Command Cheat Sheet

## Installation

```bash
sudo apt update
sudo apt install -y suricata jq netcat-openbsd
```

## Version/build

```bash
suricata --build-info | head -n 20
```

## Interface

```bash
ip -br addr
ip route
ip route get <CLIENT_IP>
```

## Rule

```bash
sudo install -d -m 0755 /etc/suricata/rules
sudo cp rules/local.rules /etc/suricata/rules/local.rules
sudo cat /etc/suricata/rules/local.rules
```

## Validate

```bash
sudo suricata -T \
  -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules
```

## Start Suricata

```bash
sudo suricata \
  -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules \
  -i <INTERFACE> \
  -l /var/log/suricata
```

## Listener

```bash
nc -lvnp 4444
```

## Generate traffic

```bash
printf 'SURICATA-LAB-TEST\n' | nc -v -w 3 <SURICATA_IP> 4444
```

## Process check

```bash
pgrep -a suricata
```

## Port check

```bash
ss -lntp | grep ':4444'
```

## Fast log

```bash
sudo grep -F "SURICATA LAB Netcat Test" /var/log/suricata/fast.log
sudo tail -n 20 /var/log/suricata/fast.log
```

## EVE JSON

```bash
sudo jq 'select(.event_type=="alert")' /var/log/suricata/eve.json
```

```bash
sudo jq '
select(.event_type=="alert")
| {timestamp,src_ip,src_port,dest_ip,dest_port,signature:.alert.signature,severity:.alert.severity}
' /var/log/suricata/eve.json
```

## Packet visibility

```bash
sudo tcpdump -ni <INTERFACE> tcp port 4444
```

## Logs

```bash
sudo tail -f /var/log/suricata/suricata.log
sudo tail -f /var/log/suricata/fast.log
```

## Stop

```text
Ctrl+C
```

## Key placeholders

- `<SURICATA_IP>` = sensor/listener IP
- `<CLIENT_IP>` = traffic generator IP
- `<INTERFACE>` = sensor interface carrying lab traffic
