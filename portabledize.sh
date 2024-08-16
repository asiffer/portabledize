#!/bin/sh

# Constants
TRUE=0
FALSE=1
readonly TRUE
readonly FALSE
OWNER="$(id -u):$(id -g)"
readonly OWNER

log() {
    printf "%s\n" "$@"
}

success() {
    printf "\e[32m%s\e[0m\n" "$@"
}

error() {
    printf "\e[31m%s\e[0m\n" "$@"
}

debug() {
    [ "$DEBUG" -eq 0 ] && printf "\e[2m%s\e[0m\n" "$@"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# List of required commands
required_commands="id sudo e2fsck resize2fs dumpe2fs mkfs.ext4 grep \
awk truncate wc mkdir basename uname touch dd bc \
dirname cp umount"
readonly required_commands

# Check all required commands
for cmd in $required_commands; do
    if ! command_exists "$cmd"; then
        error "${cmd} is not available on this system"
        exit 1
    fi
done

success "All required commands are available"

trim_image() {
    img=$1
    sudo e2fsck -p -f "${img}" >/dev/null 2>&1
    sudo resize2fs -M "${img}" >/dev/null 2>&1

    # Get the actual size after resize
    block_count=$(sudo dumpe2fs -h "${img}" 2>/dev/null | grep "Block count:" | awk '{print $3}')
    block_size=$(sudo dumpe2fs -h "${img}" 2>/dev/null | grep "Block size:" | awk '{print $3}')
    actual_size=$((block_size * block_count))
    # Trim the image
    truncate -s ${actual_size} "${img}"
}

max_trim_image() {
    img=$1
    size=1
    new_size=0

    while [ "${new_size}" -lt "${size}" ]; do
        size=$(($(wc -c "${img}" | awk '{print $1}')))
        trim_image "${img}"
        new_size=$(($(wc -c "${img}" | awk '{print $1}')))
    done

}

build_skeleton() {
    # See https://systemd.io/PORTABLE_SERVICES/#requirements-on-images
    # /usr/bin/minimald                            # a statically compiled binary
    # /usr/lib/systemd/system/minimal-test.service # the unit file for the service, with ExecStart=/usr/bin/minimald
    # /usr/lib/os-release                          # an os-release file explaining what this is
    # /etc/resolv.conf                             # empty file to mount over with host's version
    # /etc/machine-id                              # ditto
    # /proc/                                       # empty directory to use as mount point for host's API fs
    # /sys/                                        # ditto
    # /dev/                                        # ditto
    # /run/                                        # ditto
    # /tmp/                                        # ditto
    # /var/tmp/                                    # ditto
    mountpoint=$1
    mkdir -p "${mountpoint}/usr/bin/" && debug "Create /usr/bin/"
    mkdir -p "${mountpoint}/usr/lib/systemd/system/" && debug "Create /usr/lib/systemd/system/"
    mkdir -p "${mountpoint}/etc/" && debug "Create /etc/"
    mkdir -p "${mountpoint}/proc/" && debug "Create /proc/"
    mkdir -p "${mountpoint}/sys/" && debug "Create /sys/"
    mkdir -p "${mountpoint}/dev/" && debug "Create /dev/"
    mkdir -p "${mountpoint}/run/" && debug "Create /run/"
    mkdir -p "${mountpoint}/tmp/" && debug "Create /tmp/"
    mkdir -p "${mountpoint}/var/tmp/" && debug "Create /var/tmp/"

    printf "NAME=linux\nID=linux\nARCHITECTURE=%s\n" "$(uname -m)" >"${mountpoint}/usr/lib/os-release"
    debug "Create /usr/lib/os-release"

    touch "${mountpoint}/etc/resolv.conf" && debug "Create /etc/resolv.conf"
    touch "${mountpoint}/etc/machine-id" && debug "Create /etc/machine-id"
}

ensure_starts_with_slash() {
    input_string="$1"

    # Check if the string starts with a slash
    case "$input_string" in
    /*)
        # If it already starts with a slash, return it as is
        echo "$input_string"
        ;;
    *)
        # If it doesn't start with a slash, add a slash at the beginning
        echo "/$input_string"
        ;;
    esac
}

get_file_size_in_mb() {
    file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "File not found!"
        return 1
    fi

    # Get the file size in bytes
    file_size_bytes=$(wc -c <"$file_path")

    # Convert bytes to megabytes (1 MB = 1048576 bytes)
    file_size_mb=$(echo "scale=2; $file_size_bytes / 1048576" | bc)

    echo "$file_size_mb"
}

usage() {
    bin=$(basename "$0")
    echo "Usage: $bin [-s SERVICE_FILE] [-d OUTPUT_DIR] [-f INSTALL_FILE] [-m MOUNTPOINT] [-i INITIAL_DISK_SIZE (MiB)] [-v]"
    exit 1
}

# Initialize variables
OUTPUT_DIR="$(pwd)"
INITIAL_DISK_SIZE="200" # Initial size in MiB
MOUNTPOINT="/mnt/portabledize"
DEBUG=$FALSE
INSTALL_FILE=""
SERVICE_FILE=""

# Parse options using getopts
while getopts "s:d:i:f:m:v" opt; do
    case "$opt" in
    d) OUTPUT_DIR=$OPTARG ;;
    v) DEBUG=$TRUE ;;
    i) INITIAL_DISK_SIZE=$OPTARG ;;
    f) INSTALL_FILE=$OPTARG ;;
    m) MOUNTPOINT=$OPTARG ;;
    s) SERVICE_FILE=$OPTARG ;;
    ?) usage ;;
    esac
done

# Adjust positional parameters
shift $((OPTIND - 1))

# Check required arguments
# if [ -z "$ENTRYPOINT" ] || [ -z "$SERVICE_FILE" ]; then
#     usage
# fi
if [ -z "$SERVICE_FILE" ]; then
    usage
fi
# if [ -z "${INSTALL_FILE}" ]; then
#     usage
# fi

# final image path
SERVICE_NAME=$(basename "${SERVICE_FILE}")
IMAGE="${OUTPUT_DIR}/${SERVICE_NAME%.*}.raw"

# Create an empty file
log "Creating image file ${IMAGE}"
dd if=/dev/zero of="${IMAGE}" bs=1M count="${INITIAL_DISK_SIZE}" >/dev/null 2>&1

# Format the file as ext4
log "Creating ext4 filesystem on ${IMAGE}"
mkfs.ext4 "${IMAGE}" >/dev/null 2>&1

# Create a mount point
sudo mkdir -p "${MOUNTPOINT}"
trap 'sudo rmdir '"${MOUNTPOINT}" EXIT
debug "Creating mount point ${MOUNTPOINT}"

# Mount the image
log "Mounting ${IMAGE} to ${MOUNTPOINT}"
sudo mount -o loop "${IMAGE}" "${MOUNTPOINT}"

sudo chown -R "${OWNER}" "${MOUNTPOINT}"

log "Populating image disk"
build_skeleton "${MOUNTPOINT}"

# install service file
log "Installing service file"
cp "${SERVICE_FILE}" "${MOUNTPOINT}/usr/lib/systemd/system/${SERVICE_NAME}"

# installation files
if [ -e "${INSTALL_FILE}" ]; then
    base_source=$(dirname "${INSTALL_FILE}")
    log "Installing extra files"
    while IFS=' ' read -r source destination; do
        destination=$(ensure_starts_with_slash "${destination}")
        absolute_destination="${MOUNTPOINT}${destination}"
        destination_directory=$(dirname "${absolute_destination}")
        if [ -n "${source}" ] && [ -n "${destination}" ]; then
            mkdir -p "${destination_directory}" && debug "Creating directory ${destination_directory}"
            cp "${base_source}/${source}" "${MOUNTPOINT}${destination}" && debug "${base_source}/${source} -> ${MOUNTPOINT}${destination}"
        fi
    done <"${INSTALL_FILE}"
fi

# Unmount the image
log "Unmounting ${MOUNTPOINT}"
sudo umount "${MOUNTPOINT}"

# Resize the filesystem to minimal size
log "Reducing the image size"
max_trim_image "${IMAGE}"

final_size=$(get_file_size_in_mb "${IMAGE}")
success "Raw disk image created and trimmed: ${IMAGE} (${final_size} MB)"

# github action
if [ -n "${GITHUB_OUTPUT}" ]; then
    echo "image=${IMAGE}" >>"$GITHUB_OUTPUT"
fi

exit 0
