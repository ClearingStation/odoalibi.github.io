#!/bin/bash

# Function to check and install dependencies
install_dependencies() {
    echo "Checking and installing dependencies..."

    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Please install it first from https://brew.sh"
            exit 1
        fi

        # Install dependencies via Homebrew
        if ! command -v cwebp &> /dev/null; then
            echo "Installing webp tools..."
            brew install webp
        fi

        if ! command -v mogrify &> /dev/null; then
            echo "Installing ImageMagick..."
            brew install imagemagick
        fi

        if ! command -v jpegoptim &> /dev/null; then
            echo "Installing jpegoptim..."
            brew install jpegoptim
        fi

        if ! command -v pngquant &> /dev/null; then
            echo "Installing pngquant..."
            brew install pngquant
        fi
    elif [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        sudo apt-get update

        if ! command -v cwebp &> /dev/null; then
            echo "Installing webp tools..."
            sudo apt-get install -y webp
        fi

        if ! command -v mogrify &> /dev/null; then
            echo "Installing ImageMagick..."
            sudo apt-get install -y imagemagick
        fi

        if ! command -v jpegoptim &> /dev/null; then
            echo "Installing jpegoptim..."
            sudo apt-get install -y jpegoptim
        fi

        if ! command -v pngquant &> /dev/null; then
            echo "Installing pngquant..."
            sudo apt-get install -y pngquant
        fi
    elif [[ -f /etc/fedora-release || -f /etc/redhat-release ]]; then
        # Fedora/RHEL/CentOS
        if ! command -v cwebp &> /dev/null; then
            echo "Installing webp tools..."
            sudo dnf install -y libwebp-tools
        fi

        if ! command -v mogrify &> /dev/null; then
            echo "Installing ImageMagick..."
            sudo dnf install -y ImageMagick
        fi

        if ! command -v jpegoptim &> /dev/null; then
            echo "Installing jpegoptim..."
            sudo dnf install -y jpegoptim
        fi

        if ! command -v pngquant &> /dev/null; then
            echo "Installing pngquant..."
            sudo dnf install -y pngquant
        fi
    elif [[ -f /etc/arch-release ]]; then
        # Arch Linux
        if ! command -v cwebp &> /dev/null; then
            echo "Installing webp tools..."
            sudo pacman -S --noconfirm libwebp
        fi

        if ! command -v mogrify &> /dev/null; then
            echo "Installing ImageMagick..."
            sudo pacman -S --noconfirm imagemagick
        fi

        if ! command -v jpegoptim &> /dev/null; then
            echo "Installing jpegoptim..."
            sudo pacman -S --noconfirm jpegoptim
        fi

        if ! command -v pngquant &> /dev/null; then
            echo "Installing pngquant..."
            sudo pacman -S --noconfirm pngquant
        fi
    else
        echo "Unsupported operating system. Please install these tools manually:"
        echo "- webp (cwebp command)"
        echo "- ImageMagick (mogrify command)"
        echo "- jpegoptim"
        echo "- pngquant"
        exit 1
    fi

    echo "All dependencies installed successfully!"
}

# Check if dependencies are installed
check_dependencies() {
    local missing_deps=0

    if ! command -v cwebp &> /dev/null; then
        echo "Missing dependency: cwebp (webp tools)"
        missing_deps=1
    fi

    if ! command -v mogrify &> /dev/null; then
        echo "Missing dependency: mogrify (ImageMagick)"
        missing_deps=1
    fi

    if ! command -v jpegoptim &> /dev/null; then
        echo "Missing dependency: jpegoptim"
        missing_deps=1
    fi

    if ! command -v pngquant &> /dev/null; then
        echo "Missing dependency: pngquant"
        missing_deps=1
    fi

    return $missing_deps
}

# Prompt user to install dependencies if missing
prompt_install_dependencies() {
    echo -n "Would you like to install missing dependencies? (y/n): "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        install_dependencies
    else
        echo "Cannot proceed without required dependencies. Exiting."
        exit 1
    fi
}

# Main script
main() {
    # Check for dependencies
    if ! check_dependencies; then
        prompt_install_dependencies
    fi

    # Define the assets folder
    ASSETS_FOLDER="./images"
    OPTIMIZED_FOLDER="$ASSETS_FOLDER/optimized"

    # Create the optimized folder if it doesn't exist
    mkdir -p "$OPTIMIZED_FOLDER"

    # Iterate through all images in the assets folder
    find "$ASSETS_FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | while IFS= read -r -d '' img; do
        echo "Processing $img..."

        # Get the file extension and file name without extension
        extension="${img##*.}"
        filename=$(basename "$img")
        filename_without_ext="${filename%.*}"

        # Get the relative path of the image
        relative_path="${img#$ASSETS_FOLDER/}"

        # Get the directory path of the image relative to the assets folder
        relative_dir=$(dirname "$relative_path")

        # Create the corresponding directory structure in the optimized folder
        mkdir -p "$OPTIMIZED_FOLDER/$relative_dir"

        # Define the output path for the optimized image
        optimized_img_path="$OPTIMIZED_FOLDER/$relative_dir/$filename_without_ext.webp"

        # Check if WebP version already exists
        if [[ -f "$optimized_img_path" ]]; then
            echo "$img is already optimized. Skipping."
            continue
        fi

        echo "Optimizing $img..."

        # Convert to WebP format
        cwebp -q 80 "$img" -o "$optimized_img_path"

        # Create a temporary copy for optimization
        temp_img="$OPTIMIZED_FOLDER/$relative_dir/$filename"
        cp "$img" "$temp_img"

        # Resize image if it's larger than 1920x1080 (common full HD resolution)
        mogrify -resize '1920x1080>' "$temp_img"

        # Compress original images based on type
        if [[ "$extension" == "jpg" || "$extension" == "jpeg" ]]; then
            jpegoptim --max=80 --strip-all "$temp_img"
        elif [[ "$extension" == "png" ]]; then
            pngquant --force --ext .png --speed 1 "$temp_img"
        fi

        echo "$img optimized and saved to $OPTIMIZED_FOLDER/$relative_dir"
    done

    echo "Image optimization completed!"
}

# Run the main function
main
