# Use Alpine as the base for a tiny image size
FROM alpine:latest

# Install the necessary tools
RUN apk add --no-cache \
    ffmpeg \
    yt-dlp

# Set the working directory to the mount point
WORKDIR /downloads

# Set yt-dlp as the command that runs by default
ENTRYPOINT ["yt-dlp"]
