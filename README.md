# AtomIDS

Tiny IDS with [Suricata](https://suricata.io/) and [OpenObserve](https://openobserve.ai/). It is capable of running even on [Raspberry Pi](https://www.raspberrypi.com/) or tiny thin clients such as [Dell Wyse 3040](https://www.parkytowers.me.uk/thin/wyse/3040/) with quad core Intel Atom CPU and 2GB of RAM. *The complete solution with network capture, IDS and lightweight SIEM should cost **less than 100 Euro**.*

In my reference setup, I use Dell Wyse 3040 and [Alpine Linux](https://alpinelinux.org/) as a base system, with minimal dependencies.

This tiny IDS can capture and analyze network traffic with Suricata and send all network logs and Suricata alerts to OpenObserve, a lightweight monitoring platform similar to ElasticSearch.

Traffic can be forwarded to this IDS by several ways, see next section.

## Capturing Network Traffic

Usually, you will need a little help from some of your network device.
Nowadays, network hubs are very rare (and very slow for modern standards of 1+Gbps networks), so using a promiscuous mode of network interface on the IDS machine is not sufficient (unless you want to use IDS in your virtual lab and the virtual switch can support promiscuous mode, e.g. ESXi vSwitch can).

Good network taps are usually expensive and not available in HomeLabs and SOHO environment. So, we can use what we usually have, or what is not so expensive to buy: port mirroring on your (managed) switch, or sniffing and streaming network traffic on your router.

Couple of recommended examples:
- cheap managed switches:
  - TP Link Gigabit Easy Smart Switch such as [TL-SG105E](https://www.tp-link.com/en/business-networking/soho-switch-easy-smart/tl-sg105e/) *(approx 20 Euro)*
  - Netgear Gigabit Ethernet Plus Switch such as [GS105E](https://www.netgear.com/support/product/gs105e) *(approx 30 Euro)*
- cheap routers with port mirroring or packet sniffer
  - [MikroTik Ethernet Routers](https://mikrotik.com/products/group/ethernet-routers), such as [hEX refresh](https://mikrotik.com/product/hex_2024) *(approx 50 Euro)*
  - [MikroTik Wireless for home and office products](https://mikrotik.com/products/group/wireless-for-home-and-office), such as [hAP ax S](https://mikrotik.com/product/hap_ax_s) or [hAP ac^2](https://mikrotik.com/product/hap_ac2) *(approx 65 Euro, but older hAP ac^2 can be purches on second-hand market for around 20 Euro)*

My personal favourite device with the best value for money is second-hand Mikrotik hAP ac^2. Couple of years ago, this device was distributed by our local telecomunication company to their customers as a device for home fixed LTE Internet conenction. They used their custom firmware based on MikroTik Router OS and now are available for approximately 20-30 Euro on local markets. And they can be re-flashed with the official vanilla RouterOS using the [Netinstall mode](https://help.mikrotik.com/docs/spaces/ROS/pages/24805390/Netinstall).

My another favourite device, especially in connection with Dell Wyse 3040, is TP Link TL-SG105E. Those two devices have almost similar form factor and can be stacked one on the another device. With simple 3D-printed holder, they can be mounted under the desk.

### Forwarding Network Traffic to IDS

**Port Mirroring method:** some switches allow to forward the mirrored traffic using the same Ethernetport, which is also used for normal internet connectivity of the IDS device. Example of such a switch is TL-SG105E. Thanks to this, you will not need any other ethernet adapter for management and access to your IDS device. If such port mirroring is not possible with your switch, you will need another USB-Ethernet adapter (or WiFi) for management of your IDS device and access to OpenObserve web interface. *Usually, there is only one gigabit port on board on tiny PCs, so it is better to dedicate it to traffic monitoring and use slower WiFi or USB-Ethernet adapter for normal internet connectivity).

**Streaming Network Traffic method:** some network devices allow to sniff network traffic directly on them and stream this network traffic to some destination in the network. For example, MikroTik uses [TaZmen Sniffer Protocol (TZSP)](https://en.wikipedia.org/wiki/TZSP) for this. In the past, MikroTik offered their own tool called [`trafr`](https://web.archive.org/web/20240513232540/https://mikrotik.com/download/trafr.tgz) for receiving the TZSP-encapsulated traffic and replaying it. It is old tool, only available as 32-bit Linux program. Nowadays, it is not available for downloading from MikroTik anymore. However, there is support of TZSP in couple of network monitoring tools, such as [WireShark](https://www.wireshark.org/docs/dfref/t/tzsp.html), [NetworkMiner](https://www.netresec.com/?page=Blog&month=2024-05&post=Remote-Sniffing-from-Mikrotik-Routers) or [tzsp2pcap](https://github.com/thefloweringash/tzsp2pcap/). This `tzsp2pcap` in conjunction with `tcpreplay` can be used for the same purpose as the original `trafr`.

*Note: please keep in mind that traffic mirroring/forwarding of 1Gbps full duplex into one 1Gbps ethernet port could cause packet loss. It is recommended to use either 2.5Gbps ports for port mirroring (if possible), or to limit the speed of monitored interfaces to minimalize packet loss. Optimal settings depend on your local environment and preferences - e.g. if you have only 300Mbps uplink to your ISP and you want to monitor only the outgoing/incoming traffic from/to your network, you do not need to limit any speeds. However, if you want to monitor your 1Gbps internal network, and multiple devices saturate those speeds in both direction, you will encounter significant packet loss in monitoring.*

## Alpine Setup

Because some models of Dell Wyse has only 8GB of eMMC flash storage, I want to have all available storage space to OS and do not waste it for RAM SWAP - the storage is also pretty slow in comparison to RAM or modern NVMe or SATA SSDs. *For extra data and storage of network logs, I usually use tiny USB flash drive in the one USB 3.0 port.*

So, during the Alpine Linux installation, I disable SWAP by setting the environment variable `SWAP_SIZE=0`.

```
SWAP_SIZE=0 setup-alpine
```

### Post-Install Setup
*(Optional)*If you like the color prompt, it is possible to do system-wide by enable color prompt in `/etc/profile.d`:

```
mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh
```

Some packages used in my AtomIDS are only in community repository, so we can enable it either by editing `/etc/apk/repositories`, or by running the command

```
setup-apkrepos -o
```

Next, it is time to upgrade current system and install required packages:

```
apk update
apk upgrade
apk add \
    vim \
    tcc \
    tcc-libs-static \
    musl-dev \
    libpcap-dev \
    tcpreplay \
    tcpdump \
    suricata \
    syslog-ng \
    syslog-ng-scl \
    syslog-ng-http \
    syslog-ng-json \
    tmux \
    htop \
    btop \
    bmon \
    curl \
    jq
```

*Note: htop, btop, bmon are installed just for monitoring of running instance in terminal.  tcpdump, vim, tmux, curl and jq are here for more convenient work during setup and troubleshooting. For a building `tzsp2pcap` tool, I use tiny C compiler `tcc` Instead of 'huge' `gcc` and its dependencies (160+ MB). If you do not use MikroTik TZSP Streaming (see section about Forwarding Network Traffic above), then, you can skip installation of tcc, tcc-libs-static, musl-dev and libpcap-dev libraries.*

*So, bare minimum for port mirroring method are only the few packages: suricata syslog-ng syslog-ng-scl syslog-ng-http syslog-ng-json.*

## TZSP Setup
For receiving TZSP-encapsulated traffic from MikroTik, we need to build the [tzsp2pcap tool](https://github.com/thefloweringash/tzsp2pcap/).

```
wget https://raw.githubusercontent.com/thefloweringash/tzsp2pcap/refs/heads/master/tzsp2pcap.c
tcc -o /usr/local/bin/tzsp2pcap -std=c99 -D_DEFAULT_SOURCE -Wall -Wextra -pedantic -O2 tzsp2pcap.c -lpcap
```

*Note: if you want to build with traditional method of `make` and `make install`, you will need to install other dependencies:*

```
apk add git coreutils binutils make
git clone https://github.com/thefloweringash/tzsp2pcap.git
cd tzsp2pcap
CC=tcc make
CC=tcc make install
```

Next step is to create a dummy network interface. We will use this interface for replaying TZSP-encapsulated traffic from MikroTik after the encapsulation was removed by `tzsp2pcap`:

```
cat <<EOF >>/etc/network/interfaces
auto tzsp0
iface tzsp0 inet manual
    pre-up ip link add tzsp0 type dummy
    pre-up ip link set tzsp0 mtu 9216
    up ip link set tzsp0 up
EOF
```

Now, we can either restart networking service, or reboot the host, to apply this changes:

```
rc-service networking restart
```

Now we should see the `tzsp0` interface. We can verify it with the command `ifconfig tzsp0`. And we can test the TZSP replay:

```
tzsp2pcap -f | tcpreplay-edit --quiet --suppress-warnings --no-flow-stats --topspeed --mtu=$(cat /sys/class/net/tzsp0/mtu) -i tzsp0 -
```

Start traffic streaming from packet sniffer tool on MikroTik and in another terminal on your IDS box, examine the received traffic with `tcpdump -n -i tzsp0`. If everything is OK, you should see network traffic on your monitored network.

### Service tzsp-replay
Now, we can run the tzsp-replay as a service. Copy the file `openrc/tzsp-replay` to the `/etc/init.d/tzsp-replay`, run the service and enable it to automatically starts after each boot.

```
rc-service tzsp-replay start
rc-update add tzsp-replay default
```

## Suricata Setup

Replace `/etc/suricata/suricata.yaml` with the config provided here. It is vanilla config, with following changes:

- HOME_NET adjusted for common situation in home labs or home networks behind the ISP's NAT
- EXTERNAL_NET set to any, it triggers more detection rules and can find more suspicious traffic in home or lab network
- disabled stats. To be honest, how many of you will review not only your network traffic, but also the suricata performance stats every day during let say 6 months?
- include pcap filename, when we run Suricata for processing network traffic captured in PCAP file. It is useful as reference during investigation in SIEM later. *Be careful, filename can contain something sensitive, such as personal or customer info*
- computing community-id for network connections. Useful for cross-reference the connection with another tools such as WireShark or Zeek
- enhanced logging of packet and payload details in alerts
- logging filetype and md5 and sha256 hashes of files (if transferred in plaintext, not in encrypted traffic)
- extended logging information about emails sent via SMTP (if sent in plaintext, not in encrypted traffic)
- enabled various protocols parsers, such as rdp, sip, pgsql and websocket

Copy `disable.conf` file from this repository to `/etc/suricata/disable.conf`. It is used for disabling signatures which are triggered very often by "almost" normal traffic, such as:

- various protocol decoders and reassembly errors
- weird modern domains, which are often used, especially in connection with AI and social networks such as Nostr.
- alerts for Telegram API domains. We will use telegram notifications, so our notification service will trigger another alerts if those signatures are enabled
- signature which is triggered by Windows devices

After that, we can update suricata rulesets, enable [Emerging Threats Open rules](https://rules.emergingthreats.net/open/) and update suricata signatures:

```
suricata-update update-sources
suricata-update enable-source et/open
suricata-update
```

Next, we can run suricata and enable it to automatically starts after each boot:

```
rc-service suricata start
rc-update add suricata default
```

It is recommended to periodically update the suricata rules. It can be done even without restarting the suricata by running the following command:

```
suricata-update -q --reload-command "suricatasc -c ruleset-reload-nonblocking"
```

We can do it automatically every day by copying file `suricata-update.sh` from this repository to `/etc/periodic/daily/suricata-update.sh`.

## Syslog-NG Setup

Suricata logs network events and alerts to the `/var/log/suricata/`. For further processing, `eve.json` file is most suitable. It contains all Suricata events in json formats, including alerts, http, tls, fileinfo, flow and other events. Every record has `event_type` field, telling us what kind of event it is.

We can process the `eve.json` file with syslog-ng, and do various actions depending on the event type. For example, we can send alerts to Telegram or Discord, and forward all events to our SIEM platform. Moreover, we can execute some commands for each alert, such as modification of firewall rules to block the alerted IP address.

*Note 1: by blocking alerted IP address with firewall, we can effectively turn our IDS into IPS*

*Note 2: be very carefull to do not block yourself. Recommended approach is to create allow rule for yourself, followed by deny rule for all IP addresses from "blocklist". Enable only malware-related Suricata rules, use Suricata for some time only in IDS mode and tune your rules and infrastructure. After the tunning, you can continue with IPS mode and add each alerted public IP address to the "blocklist" on your firewall.*

Copy the `syslog-ng.conf` and `secrets.conf` file to `/etc/syslog-ng/`. Adjust secrets in `secrets.conf` - your Telegram Bot token (you can [create](https://core.telegram.org/bots/tutorial#getting-ready) a bot with [BotFather](https://telegram.me/BotFather), the ID of Telegram chat, where you want to send alerts (it can be channel, group, or your account ID). ALso, you should change the OpenObserve credentials in the same file.

You can review the config syslog-ng.conf. It is minimal configuration, just for sending Telegram notifications with Suricata alerts and forwarding all Suricata events to OpenObserve (see next section).

Now, we can run syslog-ng and enable it to automatically starts after each boot:

```
rc-service syslog-ng start
rc-update add syslog-ng default
```

## OpenObserve Setup

With Suricata and syslog-ng up and running, we are ready to setup a platform for security events collection and management. Because in this project we focused on small devices devices and low budget, it is not recommended to run something heavy such as [Elastic Stack (ELK)](https://www.elastic.co/elastic-stack/), [OpenSearch](https://opensearch.org/) or [Splunk](https://www.splunk.com/). Instead, we can use more lightweight platform alled [OpenObserve](https://openobserve.ai/), with great storage efficiency and performance. 

There are couple of advantages of OpenObserve, such as ingestion compatible with ElasticSearch (and OpenSearch), ability to use saved views for log inspection, custom dashboards, pipelines and alerting. Basically we can use OpenObserve as a lightweight SIEM suitable for HomeLab and SOHO. In some cases (e.g. very large data ingestion and analysis), it is very suitable also for enterprise deployment thanks to the scalability and lower costs compared to ELK, OpenSearch or Splunk.

First of all, we can create new (unprivileged) user for OpenObserve:

```
addgroup openobserve
adduser -h /var/lib/openobserve -G openobserve -D -s /sbin/nologin openobserve
```

Then, download and extract the latest OSS version of [`openobserve`](https://openobserve.ai/downloads/) and initialize OpenObserve data dir (of course, change OpenObserve admin credentials here and also in `/etc/syslog-ng/syslog-ng.conf`):

```
curl -L -o openobserve.tar.gz https://downloads.openobserve.ai/releases/openobserve/v0.50.3/openobserve-v0.50.3-linux-amd64-musl.tar.gz
tar -xzf openobserve.tar.gz
rm openobserve.tar.gz
chown root:root openobserve
mv openobserve /usr/local/bin/openobserve
su openobserve -s /bin/ash -c 'ZO_DATA_DIR=/var/lib/openobserve/ ZO_TELEMETRY=false ZO_ROOT_USER_EMAIL="root@home.arpa" ZO_ROOT_USER_
PASSWORD="Complexpass#123" openobserve'
```

### OpenObserve as a service

It is recommended to run OpenObserve as a service. Copy the file `openrc/openobserve` to the `/etc/init.d/openobserve`, run the service and enable it to automatically starts after each boot.

```
touch /var/log/openobserve.log
chown openobserve:openobserve /var/log/openobserve.log
rc-service openobserve start
rc-update add openobserve default
```

OpenObserve should be listening on TCP port 5080 on all interfaces. You can verify it with `netstat -tlnp`, or just visit [http://a.b.c.d:5080](http://a.b.c.d:5080), where `a.b.c.d` is the IP address of your AtomIDS machine.

After a while, you should see several indexes with logs in OpenObserve. If you used syslog-ng config provided here, there should be a separate index for every type of Suricata events. You can verify it by clicking on Streams, or Logs in the left navigation menu.

### OpenObserve alerts

If you want to setup notifications about Suricata alerts, you can use OpenObserve alerts feature for this.

Let's say that we would like to send notifications to Discord.

First, configure alert template via Management (top right corner) -> Templates. Create new Template, choose Web Hook, and define the body of web hook request for Discord:

```
{
    "content": "{alert_category}\n[{alert_signature_id}] {alert_signature}\n{proto} {src_ip}:{src_port} -> {dest_ip}:{dest_port}",
    "username": "Suricata IDS",
    "avatar_url": "https://suricata.io/wp-content/uploads/2021/01/cropped-favicon.png"
}
```

Then, configure destination via Management -> Alert Destinations. Create a new web hook destination, choose the Discord template created in previous step. Grab the URL from [Discord Webhooks integration](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks) and select the 'POST' method in OpenObserve Alert Destination. Also, add `Content-Type` header with value `application/json` and the Alert Destination is ready.

Last, setup new OpenObserve alert via Alerts (left navigation menu). Stream Type should be `logs` and Stream Name should be `suricata_alert`. On the next screen, you can filter which alerts you want to receive as notifications. For example, in Conditions, use `if alert_severity <= 2` to select only the alerts with higher severity. Next, in Alert Settings screen, select previously defined Discord destination and you are done.

You can test if it is working by generating some alerts in you network, for example with the command

```
curl -s http://testmynids.org/uid/index.html
```
