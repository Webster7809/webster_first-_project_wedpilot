# Running Wedpilot on a real phone over Wi-Fi

The phone app talks to the Node backend on your laptop. `localhost` on a phone
means *the phone itself*, so the app has to be built with your laptop's actual
LAN IP baked in. That IP is assigned by whatever network you're on, so **it
changes whenever you switch networks or the router/hotspot restarts** — and
when it changes the app stops connecting until you rebuild.

These are the five steps, start to finish.

---

## 1. Put the laptop and phone on the same network

Either both on the same Wi-Fi, or the laptop connected to the phone's hotspot.
It doesn't matter which, as long as it's the same network.

## 2. Find the laptop's current IP

```powershell
(Get-NetIPAddress -InterfaceAlias 'WiFi' -AddressFamily IPv4).IPAddress
```

Or `ipconfig` and read "IPv4 Address" under your Wi-Fi adapter.

Write it down — call it `<LAN_IP>`. It'll look like `192.168.1.42` or
`10.50.55.23`.

## 3. Start the backend

```bash
cd backend
npm start
```

Leave it running. Confirm it's reachable **on the LAN IP, not just localhost** —
this is the step that catches firewall problems early:

```bash
curl http://<LAN_IP>:3000/health
```

You want `{"status":"ok"}`. If localhost works but `<LAN_IP>` doesn't, it's the
Windows Firewall — see Troubleshooting below.

## 4. Build the APK with that IP baked in

```bash
flutter build apk --release --dart-define=API_HOST=<LAN_IP>
```

Takes roughly 5–8 minutes. Output lands at
`build/app/outputs/flutter-apk/app-release.apk`.

**Forgetting `--dart-define` is the single most common mistake.** Without it the
app falls back to an emulator-only address and a real phone silently fails to
connect, with no error explaining why.

## 5. Install it

**By cable (most reliable):**

```bash
flutter install
```

**Over Wi-Fi (no cable):** serve the APK and download it on the phone.

```bash
cp build/app/outputs/flutter-apk/app-release.apk build/web/wedpilot.apk
```

then serve `build/web` on port 8080 and open
`http://<LAN_IP>:8080/wedpilot.apk` in the phone's browser.

If you use a static file server, make sure it sends a `Content-Length` header
and the `application/vnd.android.package-archive` content type. Without them
Android can truncate the download and report a bare **"App not installed"** with
no hint that the file was simply incomplete.

---

## When it stops connecting

Almost always the IP moved. Re-check step 2 — if the IP differs from what you
last built with, rebuild (step 4) and reinstall (step 5).

Quick check of whether the phone is reaching the laptop at all: watch the
backend terminal while you use the app. Requests appear there if it's getting
through. Silence means it isn't, and the problem is network or the baked-in IP —
not the app.

## Troubleshooting

**`curl http://<LAN_IP>:3000/health` fails but localhost works**
Windows Firewall is blocking inbound connections. You need an inbound rule
allowing TCP 3000 (and 8080 if serving the APK). Creating one needs an
administrator terminal:

```powershell
New-NetFirewallRule -DisplayName "WedPilot Backend API (3000)" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

Also check the network is classified **Private**, not Public — Windows blocks
most inbound traffic on Public networks:

```powershell
Get-NetConnectionProfile -InterfaceAlias 'WiFi'
```

**"App not installed" when installing from the browser**
In order of likelihood: the download truncated (see the header note in step 5);
the phone is low on storage (a 70MB APK needs several hundred MB free to
install); or an existing copy is signed with a different key — uninstall the old
app first, then install.

**App installs but shows no data / login fails**
The baked-in IP no longer matches the laptop. Rebuild with the current IP.

---

## Optional: stop the IP from moving

On a **router** you control, add a DHCP reservation mapping your laptop's Wi-Fi
MAC to a fixed IP. Find the MAC with:

```powershell
(Get-NetAdapter -Name 'WiFi').MacAddress
```

On a **phone hotspot** this generally isn't available — Android hotspots don't
expose DHCP reservations, which is why the IP keeps moving in that setup.

A static IP on the Windows adapter also works, but it applies to the adapter
rather than to one network, so it will break internet access on any *other*
network you join until you set it back:

```powershell
# set static (needs an admin terminal)
netsh interface ip set address name="WiFi" static <LAN_IP> 255.255.255.0 <GATEWAY>

# back to automatic
netsh interface ip set address name="WiFi" dhcp
netsh interface ip set dns name="WiFi" dhcp
```

Given how often laptops move between networks, rebuilding when the IP changes is
usually less hassle than maintaining a static address.
