#!/bin/bash

# Configuration - Get passphrase from environment variable
PASSPHRASE="${TERRAFORM_ENCRYPTION_KEY}"

# Save the initial working directory (base directory)
BASE_DIR="$(pwd)"

# Terraform directory location (relative to base directory where script is run from)
TERRAFORM_DIR="terraform"

# Check if encryption key is set
if [ -z "$PASSPHRASE" ]; then
    echo "[ERROR] TERRAFORM_ENCRYPTION_KEY environment variable is not set"
    echo "[INFO] Please set the encryption key before running this script:"
    echo "       export TERRAFORM_ENCRYPTION_KEY='your-secure-passphrase'"
    exit 1
fi

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "[ERROR] Terraform directory not found at: $TERRAFORM_DIR"
    echo "[INFO] Please ensure you run this script from the project base directory"
    echo "[INFO] Usage: scripts/tfencrypt.sh [terraform arguments]"
    exit 1
fi

# Arrays to track files for cleanup
declare -a DECRYPTED_FILES=()

# Cleanup function to ensure re-encryption
cleanup() {
    echo -e "\n[INFO] Cleaning up and ensuring encryption..."
    
    # Always start from the base directory for cleanup
    cd "$BASE_DIR" 2>/dev/null || { echo "[ERROR] Could not return to base directory"; return 1; }
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR" 2>/dev/null || { echo "[ERROR] Terraform directory not found at: $BASE_DIR/$TERRAFORM_DIR"; return 1; }
    
    # Find all files (not directories) that don't end in .tf or .gpg and re-encrypt them
    for file in *; do
        # Skip directories
        [ -d "$file" ] && continue
        
        # Skip .tf files
        [[ "$file" == *.tf ]] && continue
        
        # Skip already encrypted .gpg files
        [[ "$file" == *.gpg ]] && continue
        
        # Skip if file doesn't exist (for glob patterns that don't match)
        [ ! -e "$file" ] && continue
        
        encrypted_file="${file}.gpg"
        
        echo "[INFO] Re-encrypting $file..."
        
        # Encrypt the file
        gpg --batch --yes --passphrase "$PASSPHRASE" \
            --cipher-algo AES256 \
            --symmetric \
            --armor \
            --output "$encrypted_file" \
            "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Successfully encrypted $file to $encrypted_file"
            
            # Remove the plaintext file
            rm -f "$file"
        else
            echo "[ERROR] Failed to encrypt $file"
        fi
    done
    
    # Also handle hidden files (like .terraform.lock.hcl)
    for file in .*; do
        # Skip special directories . and ..
        [[ "$file" == "." || "$file" == ".." ]] && continue
        
        # Skip directories
        [ -d "$file" ] && continue
        
        # Skip .tf files (if any hidden ones exist)
        [[ "$file" == *.tf ]] && continue
        
        # Skip already encrypted .gpg files
        [[ "$file" == *.gpg ]] && continue
        
        # Skip if file doesn't exist
        [ ! -e "$file" ] && continue
        
        encrypted_file="${file}.gpg"
        
        echo "[INFO] Re-encrypting $file..."
        
        # Encrypt the file
        gpg --batch --yes --passphrase "$PASSPHRASE" \
            --cipher-algo AES256 \
            --symmetric \
            --armor \
            --output "$encrypted_file" \
            "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Successfully encrypted $file to $encrypted_file"
            
            # Remove the plaintext file
            rm -f "$file"
        else
            echo "[ERROR] Failed to encrypt $file"
        fi
    done
    
    # Return to base directory
    cd "$BASE_DIR" >/dev/null 2>&1
    
    echo "[INFO] Cleanup complete"
}

# Set up signal traps to ensure cleanup on interruption
# Only set up traps for normal terraform operations, not for --help, --decrypt-only, or --encrypt-only
setup_traps() {
    trap cleanup EXIT
    trap 'echo "[WARN] Interrupted! Performing cleanup..."; cleanup; exit 130' INT
    trap 'echo "[WARN] Terminated! Performing cleanup..."; cleanup; exit 143' TERM
    trap 'echo "[WARN] Quit signal! Performing cleanup..."; cleanup; exit 131' QUIT
    trap 'echo "[WARN] Hangup signal! Performing cleanup..."; cleanup; exit 129' HUP
}

# Function to decrypt all .gpg files in the terraform directory
decrypt_state_files() {
    local found_encrypted=false
    
    # Always start from the base directory
    cd "$BASE_DIR" 2>/dev/null || { echo "[ERROR] Could not change to base directory"; return 1; }
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR" 2>/dev/null || { echo "[ERROR] Terraform directory not found at: $BASE_DIR/$TERRAFORM_DIR"; return 1; }
    
    # Decrypt all .gpg files (regular files)
    for encrypted_file in *.gpg; do
        # Skip if no matching files
        [ ! -e "$encrypted_file" ] && continue
        
        found_encrypted=true
        
        # Get the original filename (remove .gpg extension)
        decrypted_file="${encrypted_file%.gpg}"
        
        echo "[INFO] Decrypting $encrypted_file to $decrypted_file..."
        
        # Decrypt the file
        if gpg --batch --yes --passphrase "$PASSPHRASE" \
               --decrypt "$encrypted_file" > "$decrypted_file" 2>/dev/null; then
            echo "[INFO] Successfully decrypted $encrypted_file"
            DECRYPTED_FILES+=("$decrypted_file")
        else
            echo "[ERROR] Failed to decrypt $encrypted_file"
            cd - >/dev/null 2>&1
            return 1
        fi
    done
    
    # Also decrypt hidden .gpg files (like .terraform.lock.hcl.gpg)
    for encrypted_file in .*.gpg; do
        # Skip if no matching files
        [ ! -e "$encrypted_file" ] && continue
        
        found_encrypted=true
        
        # Get the original filename (remove .gpg extension)
        decrypted_file="${encrypted_file%.gpg}"
        
        echo "[INFO] Decrypting $encrypted_file to $decrypted_file..."
        
        # Decrypt the file
        if gpg --batch --yes --passphrase "$PASSPHRASE" \
               --decrypt "$encrypted_file" > "$decrypted_file" 2>/dev/null; then
            echo "[INFO] Successfully decrypted $encrypted_file"
            DECRYPTED_FILES+=("$decrypted_file")
        else
            echo "[ERROR] Failed to decrypt $encrypted_file"
            cd - >/dev/null 2>&1
            return 1
        fi
    done
    
    if [ "$found_encrypted" = false ]; then
        echo "[INFO] No encrypted files found to decrypt"
    fi
    
    # Return to base directory
    cd "$BASE_DIR" >/dev/null 2>&1
    
    return 0
}

# Function to encrypt any existing unencrypted files that don't end in .tf (first run)
encrypt_existing_state_files() {
    local found_unencrypted=false
    
    # Always start from the base directory
    cd "$BASE_DIR" 2>/dev/null || { echo "[ERROR] Could not change to base directory"; return 1; }
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR" 2>/dev/null || { echo "[ERROR] Terraform directory not found at: $BASE_DIR/$TERRAFORM_DIR"; return 1; }
    
    # Process regular files
    for file in *; do
        # Skip directories
        [ -d "$file" ] && continue
        
        # Skip .tf files
        [[ "$file" == *.tf ]] && continue
        
        # Skip already encrypted .gpg files
        [[ "$file" == *.gpg ]] && continue
        
        # Skip if file doesn't exist
        [ ! -e "$file" ] && continue
        
        # Check if encrypted version already exists
        encrypted_file="${file}.gpg"
        found_unencrypted=true
        
        echo "[INFO] Found unencrypted file: $file"
        echo "[INFO] Encrypting file..."
        
        # Encrypt the file
        gpg --batch --yes --passphrase "$PASSPHRASE" \
            --cipher-algo AES256 \
            --symmetric \
            --armor \
            --output "$encrypted_file" \
            "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Successfully encrypted $file"
            
            # Remove the unencrypted file
            rm -f "$file"
        else
            echo "[ERROR] Failed to encrypt $file"
        fi
    done
    
    # Process hidden files
    for file in .*; do
        # Skip special directories . and ..
        [[ "$file" == "." || "$file" == ".." ]] && continue
        
        # Skip directories
        [ -d "$file" ] && continue
        
        # Skip .tf files (if any hidden ones exist)
        [[ "$file" == *.tf ]] && continue
        
        # Skip already encrypted .gpg files
        [[ "$file" == *.gpg ]] && continue
        
        # Skip if file doesn't exist
        [ ! -e "$file" ] && continue
        
        # Check if encrypted version already exists
        encrypted_file="${file}.gpg"
        found_unencrypted=true
        
        echo "[INFO] Found unencrypted file: $file"
        echo "[INFO] Encrypting file..."
        
        # Encrypt the file
        gpg --batch --yes --passphrase "$PASSPHRASE" \
            --cipher-algo AES256 \
            --symmetric \
            --armor \
            --output "$encrypted_file" \
            "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Successfully encrypted $file"
            
            # Remove the unencrypted file
            rm -f "$file"
        else
            echo "[ERROR] Failed to encrypt $file"
        fi
    done
    
    if [ "$found_unencrypted" = false ]; then
        echo "[INFO] No unencrypted non-.tf files found"
    fi
    
    # Return to base directory
    cd "$BASE_DIR" >/dev/null 2>&1
}

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS] [terraform arguments]"
    echo ""
    echo "Options:"
    echo "  --decrypt-only    Decrypt files without running terraform"
    echo "  --encrypt-only    Encrypt files without running terraform"
    echo "  --help, -h        Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 plan                           # Decrypt, run terraform plan, then re-encrypt"
    echo "  $0 --decrypt-only                 # Decrypt files only"
    echo "  $0 --encrypt-only                 # Encrypt files only"
    echo "  $0 apply -auto-approve            # Decrypt, run terraform apply, then re-encrypt"
}

# Function to decrypt files only
decrypt_only() {
    echo "[INFO] Decrypting files only..."
    if ! decrypt_state_files; then
        echo "[ERROR] Failed to decrypt files"
        exit 1
    fi
    echo "[INFO] Files decrypted successfully"
}

# Function to encrypt files only
encrypt_only() {
    echo "[INFO] Encrypting files only..."
    if ! encrypt_existing_state_files; then
        echo "[ERROR] Failed to encrypt files"
        exit 1
    fi
    echo "[INFO] Files encrypted successfully"
}

# Main script logic
main() {
    echo "[INFO] Terraform State & Config Encryption Wrapper"
    echo "================================================"
    echo "[INFO] Current directory: $(pwd)"
    echo "[INFO] Working with terraform directory: $TERRAFORM_DIR"
    echo "[INFO] Will encrypt all files except *.tf files"
    
    # Check for special command-line options
    case "$1" in
        --decrypt-only)
            decrypt_only
            exit 0
            ;;
        --encrypt-only)
            encrypt_only
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        "")
            # No arguments - just run terraform with no args
            ;;
        *)
            # Continue with normal processing
            ;;
    esac
    
    # Set up signal traps for normal terraform operations
    setup_traps
    
    # First, encrypt any existing unencrypted files
    encrypt_existing_state_files
    
    # Decrypt all encrypted files
    echo "[INFO] Decrypting state and config files..."
    if ! decrypt_state_files; then
        echo "[ERROR] Failed to decrypt files"
        exit 1
    fi
    
    # Check if terraform is available
    if ! command -v terraform >/dev/null 2>&1; then
        echo "[ERROR] Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Run terraform with all provided arguments from the terraform directory
    if [ $# -gt 0 ]; then
        echo "[INFO] Running terraform with arguments: $@"
        echo "----------------------------------------"
        cd "$BASE_DIR/$TERRAFORM_DIR" && terraform "$@"
        terraform_exit_code=$?
        cd "$BASE_DIR" >/dev/null 2>&1
        echo "----------------------------------------"
        echo "[INFO] Terraform command completed with exit code: $terraform_exit_code"
    else
        echo "[INFO] No terraform arguments provided"
        echo "[INFO] Usage: $0 [terraform arguments]"
        echo "[INFO] Example: $0 plan"
        echo "[INFO] Example: $0 apply -auto-approve"
    fi
    
    # The cleanup function will handle re-encryption via the EXIT trap
    echo "[INFO] Preparing to re-encrypt state and config files..."
    
    # Return the terraform exit code
    exit ${terraform_exit_code:-0}
}

# Parse command line arguments to handle special options
# Check if first argument is a special option
if [[ "$1" == "--decrypt-only" || "$1" == "--encrypt-only" || "$1" == "--help" || "$1" == "-h" ]]; then
    main "$@"
else
    # Run the main function with all command-line arguments
    main "$@"
fi

# Cleanup will be called automatically via trap on EXIT