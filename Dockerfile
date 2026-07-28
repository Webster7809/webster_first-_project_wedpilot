# Containerized Flutter + Android SDK build environment — produces the same
# APK regardless of what's installed on the host machine. The project itself
# is NOT copied into the image; it's bind-mounted at `docker run` time (see
# below), so editing code never requires rebuilding this image.
FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

CMD ["flutter", "build", "apk", "--release"]
