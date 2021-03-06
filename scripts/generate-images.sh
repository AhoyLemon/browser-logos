#!/bin/bash

# This script automatically generates:
#
#    * all the different sized versions of a logo
#    * archive.gif
#    * main-desktop.png
#    * main-mobile.png
#
# Usage: generate-images.sh [dir] [dir] ...
#   e.g: generate-images.sh edge archive/arora

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare -r CONVERT_BASE_OPTIONS="\
    -colorspace RGB \
    +sigmoidal-contrast 11.6933 \
    -define filter:filter=Sinc \
    -define filter:window=Jinc \
    -define filter:lobes=3 \
    -sigmoidal-contrast 11.6933 \
    -colorspace sRGB \
    -background transparent \
    -gravity center \
"

declare -r -a IMAGE_SIZES=(
    "16x16"
    "24x24"
    "32x32"
    "48x48"
    "64x64"
    "128x128"
    "256x256"
    "512x512"
)

declare -r -a MAIN_DESKTOP_BROWSERS=(
    "chrome"
    "edge"
    "firefox"
    "opera"
    "safari"
)

declare -r -a MAIN_MOBILE_BROWSERS=(
    "android"
    "chrome"
    "edge-tile"
    "opera-mini"
    "safari-ios"
    "samsung-internet"
    "uc"
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

array_contains() {

    declare -r -a A1=("${!1}"); shift
    declare -r -a A2=("$@")

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -z "$(printf "%s\n" "${A1[@]}" "${A2[@]}" | sort | uniq -d)" ]; then
        return 0
    fi

    return 1

}

generate_archive_gif() {

    # Check if something changed in the `archive/`.

    git diff --quiet "../archive/**/*_256x256.png" \
        && return 0

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If so, regenerate the preview GIF.

    convert -background white \
            -alpha remove \
            -delay 30 \
            -loop 0 \
            ../archive/**/*_256x256.png \
            ../archive.gif \
        1> /dev/null

    print_result $? "archive.gif"

}

generate_different_sized_images() {

    local basename="$(basename "$1")"
    local path="$1"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the main image exists.

    if [ ! -f "../$path/$basename.png" ]; then
        print_error "$path/$basename.png does not exist!"
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Remove any existing outdated images.

    rm "../${path}/${basename}_*" &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Generate the different sized images
    # based on the main image.

    for imageSize in "${IMAGE_SIZES[@]}"; do

        convert "../$path/$basename.png" \
                $CONVERT_BASE_OPTIONS \
                -resize "$imageSize" \
                "../$path/${basename}_$imageSize.png" \
            1> /dev/null

        print_result $? "$path/${basename}_$imageSize.png"

    done

}

generate_group_image() {

    declare -r -a GROUP_IMAGES=("${!1}"); shift;
    declare -r GROUP_IMAGE_NAME="$1"; shift;

    local tmp=()

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if any of the specified names
    # are part of the specified group.

    if ! array_contains "GROUP_IMAGES[@]" "$@"; then
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If so, regenerate the group image.

    for i in "${GROUP_IMAGES[@]}"; do
        tmp+=("../$i/$i.png")
    done

    convert "${tmp[@]}" \
            $CONVERT_BASE_OPTIONS \
            -resize 512x512 \
            -extent 562x562 \
            +append \
            "../$GROUP_IMAGE_NAME" \
        1> /dev/null

    print_result $? "$GROUP_IMAGE_NAME"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    # Check if ImageMagick's `convert`
    # command-line tool is available.

    if ! cmd_exists "convert"; then
        print_error "Please install ImageMagick's 'convert' command-line tool!"
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    for i in "$@"; do
        printf "\n"
        generate_different_sized_images "$i"
    done

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    printf "\n"

    generate_archive_gif "$@"

    generate_group_image \
        "MAIN_DESKTOP_BROWSERS[@]" \
        "main-desktop.png" \
        "$@"

    generate_group_image \
        "MAIN_MOBILE_BROWSERS[@]" \
        "main-mobile.png" \
        "$@"

    printf "\n"

}

main "${@%/}"
