
# UxPlay-Web

A lightweight, **AirPlay Mirroring server** running inside a Docker container. This project utilizes [UxPlay](https://github.com/FDH2/UxPlay) for AirPlay 1/2 support and the [Selkies base image](https://github.com/linuxserver/docker-baseimage-selkies) to provide a low-latency web interface for viewing the stream directly in your browser. Tested for local network only.

## 🚀 Features

* **AirPlay Mirroring:** Stream your iPhone, iPad, or Mac screen to any device running a modern web browser.
* **Web-Based Viewing:** View the AirPlay stream in any modern web browser via Port 3001 (HTTPS) or Port 3000 (HTTP/Reverse Proxy).
* **Optimized Footprint:** Built on Alpine Linux to minimize image size and resource overhead.
* **Auto-Discovery:** Integrated Avahi/mDNS daemon for seamless "plug-and-play" discovery by iOS devices.

---

## 🛠️ Prerequisites

* **Docker** installed on your host machine.
* **Host Networking:** As far as I know, you pretty much need to run the container with **Host** networking for UxPlay to work.
* **Hardware Acceleration (Optional):** Recommended for smooth 60fps mirroring; **CPU usage will be significantly higher if a GPU is not used for hardware acceleration, even when idle**.

---

## ⚡ Quick Start

### 1. Build the Image

```bash
docker build -t uxplay-web .

```

### 2. Run the Container

```bash
docker run -d \
  --name=uxplay-web \
  --net=host \
  --device /dev/dri:/dev/dri \
  -e AIRPLAY_NAME="UxPlay-Web" \
  uxplay-web

```

### 3. Connect

1. **Open your Browser:** Go to https://<your-host-ip>:3001.
2. **Reverse Proxy (Optional):** For a more permanent setup, it is recommended to use a reverse proxy (e.g., Nginx, Traefik) pointing to port 3000 to manage SSL certificates.
3. **Start Mirroring:** On your iOS device, open the Control Center, tap **Screen Mirroring**, and select **"Docker-Mirror"**.

Open your Browser: 

Reverse Proxy (Optional): For a more permanent setup, it is recommended to use a reverse proxy (e.g., Nginx, Traefik) pointing to port 3000 to manage SSL certificates.

Start Mirroring: On your iOS device, open the Control Center, tap Screen Mirroring, and select "UxPlay-Web".

---

## ⚙️ Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `AIRPLAY_NAME` | `Docker-UxPlay` | The name that appears in your iOS Screen Mirroring list. |
| `CUSTOM_PORT` | `3000` | HTTP port the web interface will be running at, you must use HTTPS if you're not using a reverse proxy. |
| `CUSTOM_HTTPS_PORT` | `3001` | HTTPS port of the web interface using a self-signed certificate. |
| `HARDEN_OPENBOX` | `true` | Can be set to false for testing. [Selkies](https://github.com/linuxserver/docker-baseimage-selkies) config. |
| `HARDEN_DESKTOP` | `true` | Can be set to false for testing. [Selkies](https://github.com/linuxserver/docker-baseimage-selkies) config. |


---

## 📁 Network Requirements

**NOT TESTED** UxPlay requires several ports to be open. Since this container uses `--net=host`, these are handled automatically, but ensure your firewall allows:

* **UDP 5353:** mDNS (Avahi) discovery.
* **TCP 7000, 7001, 7100:** AirPlay mirroring and control.
* **UDP 5000-5005:** Real-time media streaming.
* **TCP 3001 / 3000:** Selkies Web Interface (HTTPS / HTTP).

---

### 📦 Example Docker Compose

This `docker-compose.yml` includes the necessary device mapping and host networking required for AirPlay discovery.

```yaml
services:
  uxplay-web:
    image: uxplay-selkies:latest # Change to your built image name or use pre-build image
    container_name: uxplay-web
    network_mode: host
    restart: unless-stopped
    # only needed when not running as host
    #ports:
    #  - "3000:3000" # HTTP (Internal/Reverse Proxy)
    #  - "3001:3001" # HTTPS (Direct Access)
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - AIRPLAY_NAME=UxPlay-Web
    devices:
      - /dev/dri:/dev/dri # Optional: Enables Hardware Acceleration

```

---

## 🏗️ Architecture Note

This image is optimized for size while maintaining the heavy dependencies required for video decoding:

* **Base:** `alpine323` via Selkies.
* **Service Manager:** S6-overlay (manages D-Bus, Avahi, and UxPlay).
* **Video Stack:** GStreamer (Base/Good/Ugly) + Libavcodec.

---

## 🔧 Troubleshooting

* **Not appearing in AirPlay list:** Ensure the host and the iOS device are on the same WiFi/VLAN. Check that a firewall isn't blocking UDP 5353.
* **Lags or Stuttering:** Ensure you have passed `--device /dev/dri` to enable GPU acceleration for GStreamer. Running without a GPU will result in high CPU load and potential frame drops.
* **D-Bus Errors:** The container automatically starts D-Bus. If errors persist, check the container logs: `docker logs uxplay-web`.

---

