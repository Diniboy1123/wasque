# wasque

Lightweight, unofficial [Docker](https://www.docker.com/) container for the official [Cloudflare WARP Linux CLI client](https://developers.cloudflare.com/warp-client/get-started/linux/). Easily expose a SOCKS5 proxy from within a container—**no elevated privileges required**!

## Table of Contents

- [wasque](#wasque)
  - [Table of Contents](#table-of-contents)
  - [Disclaimer](#disclaimer)
  - [Usage](#usage)
  - [What does it contain?](#what-does-it-contain)
  - [Why the `bind_redirect.c` hack?](#why-the-bind_redirectc-hack)
  - [Why `dbus`?](#why-dbus)
  - [Can I use a paid WARP+ account?](#can-i-use-a-paid-warp-account)
  - [Why was this built?](#why-was-this-built)
  - [Known issues](#known-issues)
  - [Disclaimer #2](#disclaimer-2)

## Disclaimer

This project was created for my own research and development purposes. I needed a way to run the WARP client in proxy mode without installing it on my host system. As a result, the [entrypoint](entrypoint.sh) script isn't highly flexible. If you need a different setup, feel free to fork this repository and customize it.

## Usage

Pre-built images are available on [GHCR](https://github.com/Diniboy1123/wasque/pkgs/container/wasque). Pull the latest image with:

```
docker pull ghcr.io/diniboy1123/wasque:latest
```

Run the container with:

```
docker run -d --name wasque --rm \
  -p 40000:40000 \
  ghcr.io/diniboy1123/wasque:latest
```

> [!NOTE]  
> Only `linux/amd64` and `linux/arm64` architectures are supported at the moment. I’m not aware of other architectures that the WARP client has builds for on Linux.

## What does it contain?

The image aims to be lightweight. I couldn’t use Alpine as a base, since all official [WARP Linux releases](https://pkg.cloudflareclient.com/) are built against `glibc`. Debian was too old, so I chose a less common base: [Void Linux with glibc and BusyBox](https://github.com/void-linux/void-containers/pkgs/container/void-glibc-busybox). It’s relatively lightweight and has more up-to-date packages.

Currently, the build process extracts the latest Ubuntu 24.02.2 (Noble Numbat) `.deb` package, pulls the necessary files, strips debug symbols, and copies the binaries into the image.

The image is rebuilt daily at 4 PM UTC. I plotted their release times for fun and it seems that most releases are done before 4 PM. However, there are no guarantees—things can break. If you encounter issues, feel free to open an issue.

## Why the `bind_redirect.c` hack?

By default, the WARP client binds only to `127.0.0.1`, which makes it inaccessible via `-p 40000:40000` from the host. I couldn’t find a CLI flag to change the bind address *(Cloudflare folks, if you’re reading—this would be a great feature 😌)*.

I didn’t want to patch a closed-source binary, so instead, I created an `LD_PRELOAD` hack. It intercepts `bind()` calls, and if the IP is `127.0.0.1`, it rewrites it to `INADDR_ANY`. It’s a simple trick, but it works.

## Why `dbus`?

While not essential for proxy functionality (based on my testing), the WARP client spams log errors if `dbus` isn’t running. So I included a minimal `dbus` setup in the image to avoid noisy logs.

## Can I use a paid WARP+ account?

Probably—but I haven’t tested it. You’d likely need to mount the config directory. By default, the entrypoint script registers a new free account on every launch.

## Why was this built?

I maintain my own unofficial Cloudflare WARP client, [usque](https://github.com/Diniboy1123/usque), which is open source. I needed a way to run the official client reproducibly for comparison and research purposes.

## Known issues

- No way to change the bind address or port.
- The entrypoint script is hardcoded. To customize behavior, replace the script or use `docker exec -it wasque /bin/sh` to make changes on the fly.
- The `h2-only` MASQUE fallback doesn’t seem to work. This appears to be a general issue within the official clients; I couldn’t get it working on Android either.
- If you don't have internet when the container is launched, the container will exit.

## Disclaimer #2

**This tool is not affiliated with Cloudflare in any way.** It has not been reviewed or endorsed by Cloudflare. This is an independent research project.

Cloudflare Warp, Warp+, 1.1.1.1™, Cloudflare Access™, Cloudflare Gateway™, and Cloudflare One™ are registered trademarks or wordmarks of Cloudflare, Inc. If you’re a Cloudflare employee and believe this project is harmful or violates your policies, please open an issue—I’ll do my best to resolve it.
