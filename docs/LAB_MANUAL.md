# Suricata IDS Practical Lab Manual

## 1. Lab overview

This practical lab introduces Suricata as a network intrusion detection system (IDS). You will install Suricata, identify the interface carrying lab traffic, create a local detection rule, generate controlled TCP traffic with Netcat, and analyze alerts in `fast.log` and `eve.json`.

**Authorized-lab requirement:** use only VMs, hosts, addresses, and networks you are authorized to test.

### Learning objectives

By the end of the lab, you should be able to:

- Explain the role of an IDS.
- Identify the network interface Suricata should monitor.
- Install and validate Suricata.
- Write and load a simple Suricata rule.
- Generate controlled TCP traffic with Netcat.
- Confirm an alert in `fast.log`.
- Parse EVE JSON alerts with `jq`.
- Troubleshoot common connectivity and detection problems.
- Produce reproducible evidence for a GitHub portfolio.

---

## 2. Lab environment and topology

Recommended two-VM setup:

```text
CLIENT VM                                SURICATA SENSOR VM
<CLIENT_IP>                              <SURICATA_IP>
      |                                        |
      +----------- Lab network ---------------+
                       |
                 <INTERFACE>
```

The client sends TCP traffic to port 4444. The Suricata sensor runs a Netcat listener on TCP/4444 and monitors the interface connected to the lab network.

### Placeholders

| Placeholder | Meaning | Example |
|---|---|---|
| `<SURICATA_IP>` | IP address of the Suricata sensor/listener | `192.168.56.20` |
| `<CLIENT_IP>` | IP address of the traffic-generating client | `192.168.56.30` |
| `<INTERFACE>` | Suricata sensor interface carrying lab traffic | `eth0`, `enp0s3` |

Use your real lab values. Do not blindly copy the examples.

### Network mode

For isolated VirtualBox labs, Host-Only or Internal Network is usually easiest. NAT can work, but it can complicate VM-to-VM reachability and visibility.

---

## 3. Prerequisites

### On the Suricata sensor

- Kali Linux, Debian, or Ubuntu VM
- sudo/root access
- 1 network interface connected to the lab network
- Internet access during package installation, if using APT
- `jq`
- `netcat-openbsd`

### On the client

- Linux/macOS/Windows with a Netcat equivalent
- Network connectivity to `<SURICATA_IP>`

### Safety

Do not use this exercise against public IPs, third-party systems, production networks, or systems without authorization.

---

## 4. Install Suricata and supporting tools

On the Suricata sensor:

```bash
sudo apt update
```

**Expected:** APT refreshes package metadata.

```bash
sudo apt install -y suricata jq netcat-openbsd
```

**Expected:** Suricata, jq, and Netcat are installed.

Check Suricata:

```bash
suricata --build-info | head -n 20
```

**Expected:** Version/build information is displayed.

Check the service:

```bash
sudo systemctl status suricata --no-pager
```

**Expected:** You may see `active (running)`, `inactive`, or `failed`. Do not worry if it is not running yet; this lab also demonstrates starting Suricata manually with a selected interface.

If you want the service stopped while doing the manual test:

```bash
sudo systemctl stop suricata
```

---

## 5. Identify the network interface

Run:

```bash
ip -br addr
```

**Expected:** A compact list of interfaces, states, and IP addresses.

Example:

```text
lo        UNKNOWN   127.0.0.1/8
enp0s3    UP        192.168.56.20/24
```

Here the interface would be `enp0s3`.

Confirm the route to the client:

```bash
ip route
```

**Expected:** A route showing the lab subnet and interface.

You can also check which interface Linux would use to reach the client:

```bash
ip route get <CLIENT_IP>
```

**Expected:** Output containing something like:

```text
<CLIENT_IP> dev <INTERFACE> src <SURICATA_IP>
```

That `<INTERFACE>` is the value to use with Suricata.

---

## 6. Verify basic connectivity

From the client:

```bash
ping -c 4 <SURICATA_IP>
```

**Expected:** Replies with packet statistics.

If ICMP is blocked, test TCP once the listener is running instead.

From the sensor, verify the interface has the expected address:

```bash
ip addr show <INTERFACE>
```

---

## 7. Create the custom Suricata rule

The lab rule detects the exact marker `SURICATA-LAB-TEST` sent to TCP port 4444.

Create the directory:

```bash
sudo install -d -m 0755 /etc/suricata/rules
```

Copy the portfolio rule:

```bash
sudo cp rules/local.rules /etc/suricata/rules/local.rules
```

Inspect it:

```bash
sudo cat /etc/suricata/rules/local.rules
```

### Rule

```text
alert tcp any any -> any 4444 (
    msg:"SURICATA LAB Netcat Test";
    flow:to_server,established;
    content:"SURICATA-LAB-TEST";
    sid:1000001;
    rev:1;
)
```

### Rule breakdown

- `alert` — generate an alert when the rule matches.
- `tcp` — inspect TCP traffic.
- `any any` — any source IP and source port.
- `-> any 4444` — traffic destined for TCP/4444.
- `flow:to_server,established` — match established client-to-server traffic.
- `content` — search the payload for the exact marker.
- `sid:1000001` — unique local rule identifier for this exercise.
- `rev:1` — rule revision number.

---

## 8. Test the Suricata configuration

Run:

```bash
sudo suricata -T \
  -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules
```

**Expected:** A successful configuration-test message near the end, such as:

```text
Configuration provided was successfully loaded.
```

The exact wording varies by Suricata version.

If you receive a rule syntax error, inspect:

```bash
sudo suricata -T \
  -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules \
  -v
```

---

## 9. Check logging

Suricata commonly writes logs under:

```text
/var/log/suricata/
```

Check:

```bash
sudo ls -lah /var/log/suricata/
```

You want to see or eventually create files such as:

- `fast.log`
- `eve.json`
- `suricata.log`

Confirm that `fast.log` is enabled:

```bash
sudo grep -n -A5 -B2 "fast:" /etc/suricata/suricata.yaml
```

Confirm EVE is enabled:

```bash
sudo grep -n -A15 -B2 "eve-log:" /etc/suricata/suricata.yaml | head -n 30
```

If your distribution's configuration differs, use `configs/suricata-lab.yaml.example` as a reference and preserve the rest of the vendor configuration.

---

## 10. Start Suricata

First, stop any existing Suricata process:

```bash
sudo pkill suricata || true
```

Start Suricata manually:

```bash
sudo suricata \
  -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules \
  -i <INTERFACE> \
  -l /var/log/suricata
```

**Expected:** Suricata starts and continues running. Keep this terminal open.

If your build starts in the foreground, that is normal for this lab.

### Verify the process

Open another sensor terminal:

```bash
pgrep -a suricata
```

**Expected:** A Suricata process is listed.

You can also watch the logs:

```bash
sudo tail -f /var/log/suricata/suricata.log
```

Press `Ctrl+C` to stop `tail`, not Suricata.

---

## 11. Start the Netcat listener

On the Suricata sensor, in another terminal:

```bash
nc -lvnp 4444
```

**Expected:** Netcat listens on TCP/4444.

If your Netcat version uses different options, check:

```bash
nc -h
```

---

## 12. Generate controlled traffic

From the client VM:

```bash
printf 'SURICATA-LAB-TEST\n' | nc -v -w 3 <SURICATA_IP> 4444
```

**Expected:** Netcat reports a successful connection and the listener displays:

```text
SURICATA-LAB-TEST
```

You can also use the supplied script:

```bash
chmod +x scripts/generate_netcat_traffic.sh
./scripts/generate_netcat_traffic.sh <SURICATA_IP> 4444
```

---

## 13. Trigger and analyze the alert

### Check fast.log

On the sensor:

```bash
sudo grep -F "SURICATA LAB Netcat Test" /var/log/suricata/fast.log
```

**Expected:** A line containing:

```text
[**] [1:1000001:1] SURICATA LAB Netcat Test [**]
```

The line should also show the TCP source and destination.

### Show recent alerts

```bash
sudo tail -n 20 /var/log/suricata/fast.log
```

### Parse EVE JSON with jq

First verify valid JSON:

```bash
sudo jq -e . /var/log/suricata/eve.json >/dev/null
```

**Expected:** No error message.

Show only alert events:

```bash
sudo jq 'select(.event_type=="alert")' /var/log/suricata/eve.json
```

Show the most useful fields:

```bash
sudo jq '
  select(.event_type=="alert")
  | {
      timestamp,
      src_ip,
      src_port,
      dest_ip,
      dest_port,
      proto,
      signature: .alert.signature,
      sid: .alert.signature_id,
      severity: .alert.severity
    }
' /var/log/suricata/eve.json
```

### Filter the custom signature

```bash
sudo jq '
  select(.event_type=="alert" and .alert.signature=="SURICATA LAB Netcat Test")
  | {
      timestamp,
      src_ip,
      src_port,
      dest_ip,
      dest_port,
      signature: .alert.signature,
      severity: .alert.severity
    }
' /var/log/suricata/eve.json
```

### Count matching alerts

```bash
sudo jq '
  select(.event_type=="alert" and .alert.signature=="SURICATA LAB Netcat Test")
' /var/log/suricata/eve.json | wc -l
```

---

## 14. Understand the evidence

### fast.log

`fast.log` is line-oriented and designed for quick human inspection. A typical alert contains:

- timestamp
- generator ID
- signature ID
- rule revision
- signature message
- classification
- priority/severity
- protocol
- source address/port
- destination address/port

### eve.json

`eve.json` is structured JSON. Alert records can contain:

- timestamp
- flow ID
- event type
- source/destination IPs and ports
- protocol
- alert metadata
- application protocol information when available

This structure makes EVE useful for SIEM ingestion and automated analysis.

---

## 15. Troubleshooting

### Problem: `No route to host`

Check:

```bash
ip route
ip route get <SURICATA_IP>
```

Then verify:

- Both VMs are attached to the same VirtualBox network.
- The client and sensor are on the same expected subnet.
- The sensor interface is UP.
- The IP address is correct.
- Host firewall rules are not blocking the test.

On the sensor:

```bash
ip -br addr
```

On the client:

```bash
ip -br addr
```

If using VirtualBox, check the adapter mode and network name on both VMs.

### Problem: `Connection refused`

This normally means the destination is reachable but nothing is listening on TCP/4444.

On the sensor:

```bash
ss -lntp | grep ':4444'
```

Then start:

```bash
nc -lvnp 4444
```

Do not expect a successful Netcat connection if the listener is not running.

### Problem: Wrong interface

Run:

```bash
ip route get <CLIENT_IP>
```

Look for:

```text
dev <INTERFACE>
```

Then use that interface:

```bash
sudo suricata -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules \
  -i <INTERFACE> \
  -l /var/log/suricata
```

### Problem: No alerts

Work through this order:

1. Confirm Suricata is running:

```bash
pgrep -a suricata
```

2. Confirm the correct interface:

```bash
ip route get <CLIENT_IP>
```

3. Confirm the rule is loaded:

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml \
  -S /etc/suricata/rules/local.rules
```

4. Confirm the listener:

```bash
ss -lntp | grep ':4444'
```

5. Send the exact marker:

```bash
printf 'SURICATA-LAB-TEST\n' | nc -v -w 3 <SURICATA_IP> 4444
```

6. Check logs:

```bash
sudo tail -n 50 /var/log/suricata/suricata.log
sudo tail -n 50 /var/log/suricata/fast.log
```

7. Confirm packets actually reach the sensor:

```bash
sudo tcpdump -ni <INTERFACE> tcp port 4444
```

If `tcpdump` sees the traffic but Suricata does not alert, focus on the rule/configuration. If `tcpdump` sees nothing, focus on the VirtualBox network/interface/routing.

### Problem: `jq: command not found`

Install:

```bash
sudo apt update
sudo apt install -y jq
```

### Problem: permission denied reading logs

Use `sudo`:

```bash
sudo jq 'select(.event_type=="alert")' /var/log/suricata/eve.json
```

### Problem: `suricata: command not found`

Check:

```bash
command -v suricata
```

If missing:

```bash
sudo apt update
sudo apt install -y suricata
```

---

## 16. Verification checklist

Mark each item when complete.

- [ ] Suricata installed.
- [ ] `jq` installed.
- [ ] Netcat installed.
- [ ] Sensor IP identified as `<SURICATA_IP>`.
- [ ] Client IP identified as `<CLIENT_IP>`.
- [ ] Monitoring interface identified as `<INTERFACE>`.
- [ ] Client can reach sensor.
- [ ] Custom rule copied to `/etc/suricata/rules/local.rules`.
- [ ] `suricata -T` passes.
- [ ] Netcat listener is active on TCP/4444.
- [ ] Client sends `SURICATA-LAB-TEST`.
- [ ] `fast.log` contains the custom alert.
- [ ] `eve.json` contains an `event_type: alert` record.
- [ ] `jq` successfully parses the alert.
- [ ] Screenshots/evidence are sanitized.
- [ ] GitHub repository excludes raw logs and PCAPs.

---

## 17. Student questions

1. What is the difference between an IDS and an IPS?
2. Why does the rule use `flow:to_server,established`?
3. What does SID `1000001` identify?
4. Why is `eve.json` more useful for automation than `fast.log`?
5. What information can you obtain from `src_ip`, `dest_ip`, `src_port`, and `dest_port`?
6. Why can a correct rule still produce no alert if Suricata is monitoring the wrong interface?
7. What would change if the Netcat listener used TCP/5555 instead of TCP/4444?
8. What evidence would you collect to prove that the alert was generated by your custom rule?

---

## 18. Practical challenge

Create a second local rule that detects the marker:

`SURICATA-SECOND-TEST`

Requirements:

- TCP destination port 4444.
- Use a new SID.
- Use an appropriate message.
- Test the rule with Netcat.
- Confirm the alert in both `fast.log` and `eve.json`.
- Use `jq` to display only your second alert.
- Add a screenshot to the portfolio.
- Explain the rule in 3–5 sentences.

### Challenge extension

Modify the rule so it detects a different port and explain why changing the destination port changes what traffic is inspected.

---

## 19. Suggested GitHub portfolio write-up

Include:

**Objective:** Built and validated a Suricata IDS lab in an isolated virtual network.

**Skills demonstrated:** Linux administration, network interface identification, IDS configuration, Suricata rule writing, TCP traffic generation, log analysis, JSON parsing, troubleshooting, and security documentation.

**Evidence:** configuration validation, controlled traffic, `fast.log` alert, EVE JSON alert, and screenshots.

Avoid publishing sensitive or real production data.

---

## 20. Cleanup

Stop the foreground Suricata process with `Ctrl+C`.

Stop Netcat with `Ctrl+C`.

If you copied the rule to the system:

```bash
sudo rm -f /etc/suricata/rules/local.rules
```

If you started the system service for other work, manage it separately:

```bash
sudo systemctl status suricata
```

Do not delete system configuration files you did not create for this lab.
