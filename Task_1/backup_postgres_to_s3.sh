#!/bin/bash

# Exit on any error
set -e

# Trap errors and cleanup
trap cleanup EXIT INT TERM

# Log file setup
LOG_DIR="/var/log/pg_backups"
LOG_FILE="${LOG_DIR}/backup_$(date +%Y-%m-%d).log"
LOCK_FILE="/tmp/pg_backup.lock"

# Configuration
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="postgres"  
BACKUP_DIR="/tmp/pg_backups"
S3_BUCKET="bucket_postgres_backup"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
TIMEOUT=1600
RETRY_ATTEMPTS=3
RETRY_DELAY=5

# Logging function
log() {
    local level=$1
    shift
    local message=$@
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    log "INFO" "Cleaning up..."
    
    # Remove lock file
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    
    # Clean partial backups on error
    if [ $exit_code -ne 0 ]; then
        log "WARNING" "Script failed, cleaning up partial backups..."
        find "$BACKUP_DIR" -type f -name "*_${DATE}*" -exec rm -f {} \;
    fi
    
    log "INFO" "Cleanup completed with exit code: $exit_code"
    exit $exit_code
}

check_requirements() {
    local missing_requirements=0

    log "INFO" "Checking requirements..."

    # Check PostgreSQL client tools
    if ! command -v psql &> /dev/null || ! command -v pg_dump &> /dev/null; then
        log "ERROR" "PostgreSQL client tools (psql, pg_dump) are not installed"
        echo "Install using: "
        echo "  - For Ubuntu/Debian: sudo apt-get install postgresql-client"
        echo "  - For MacOS: brew install postgresql"
        missing_requirements=1
    fi

    # Check gzip
    if ! command -v gzip &> /dev/null; then
        log "ERROR" "gzip is not installed"
        echo "Install using:"
        echo "  - For Ubuntu/Debian: sudo apt-get install gzip"
        echo "  - For MacOS: Should be installed by default, if not: brew install gzip"
        missing_requirements=1
    fi

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log "ERROR" "AWS CLI is not installed"
        echo "Install instructions:"
        echo "  - For Ubuntu/Debian: sudo apt-get install awscli"
        echo "  - For MacOS: brew install awscli"
        echo "  - Or follow AWS official guide: https://aws.amazon.com/cli/"
        missing_requirements=1
    else
        # Check AWS configuration
        if ! timeout 10 aws configure list &> /dev/null; then
            log "ERROR" "AWS CLI is not configured"
            echo "Please run 'aws configure' to set up your credentials"
            echo "You will need:"
            echo "  - AWS Access Key ID"
            echo "  - AWS Secret Access Key"
            echo "  - Default region name"
            missing_requirements=1
        fi
    fi

    # Check S3 bucket exists and is accessible
    if ! timeout 10 aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
        log "ERROR" "Cannot access S3 bucket: $S3_BUCKET"
        missing_requirements=1
    fi

    if [ $missing_requirements -eq 1 ]; then
        log "ERROR" "Missing requirements detected"
        exit 1
    fi
}

# Function to handle retries
retry_command() {
    local cmd=$1
    local attempts=$RETRY_ATTEMPTS
    local delay=$RETRY_DELAY
    
    while [ $attempts -gt 0 ]; do
        if eval "$cmd"; then
            return 0
        fi
        attempts=$((attempts - 1))
        if [ $attempts -gt 0 ]; then
            log "WARNING" "Command failed, retrying in $delay seconds... ($attempts attempts left)"
            sleep $delay
        fi
    done
    return 1
}

# Create required directories
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Start logging
log "INFO" "Starting PostgreSQL backup script"


# Check requirements
check_requirements

# Get list of all databases
log "INFO" "Retrieving database list"
databases=$(timeout $TIMEOUT psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -t -c "SELECT datname FROM pg_database" 2>> "$LOG_FILE")

if [ -z "$databases" ]; then
    log "ERROR" "No databases found or connection failed"
    exit 1
fi

# Process each database
for db in $databases; do
    db=$(echo "$db" | tr -d '[:space:]')  # Clean whitespace
    if [ -z "$db" ]; then continue; fi
    
    log "INFO" "Processing database: $db"
    
    # Create backup directory
    db_backup_dir="$BACKUP_DIR/$db"
    mkdir -p "$db_backup_dir"
    backup_file="$db_backup_dir/${db}_${DATE}.sql"
    compressed_file="$backup_file.gz"
    
    # Perform backup with timeout
    log "INFO" "Creating backup for $db"
    if timeout $TIMEOUT pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$db" -F p > "$backup_file" 2>> "$LOG_FILE"; then
        log "INFO" "Backup created successfully for $db"
        
        # Compress backup
        log "INFO" "Compressing backup for $db"
        if gzip -f "$backup_file"; then
            log "INFO" "Backup compressed successfully for $db"
            
            # Upload to S3 with retry
            log "INFO" "Uploading $db backup to S3"
            if retry_command "aws s3 cp '$compressed_file' 's3://$S3_BUCKET/$db/${db}_${DATE}.sql.gz'"; then
                log "SUCCESS" "Successfully uploaded $db backup to S3"
                # Remove local backup after successful upload
                rm -f "$compressed_file"
            else
                log "ERROR" "Failed to upload $db backup to S3 after $RETRY_ATTEMPTS attempts"
            fi
        else
            log "ERROR" "Failed to compress backup for $db"
        fi
    else
        log "ERROR" "Failed to create backup for $db"
    fi
done

# Cleanup old backups (both local and S3)
log "INFO" "Cleaning up old backups"
find "$BACKUP_DIR" -type f -mtime +7 -exec rm -f {} \;

# Cleanup old S3 backups (older than 7 days)
aws s3 ls "s3://$S3_BUCKET" --recursive | while read -r line; do
    createDate=$(echo "$line" | awk {'print $1" "$2'})
    createDate=$(date -d "$createDate" +%s)
    olderThan=$(date -d "7 days ago" +%s)
    if [[ $createDate -lt $olderThan ]]; then
        fileName=$(echo "$line" | awk {'print $4'})
        if [[ $fileName != "" ]]; then
            aws s3 rm "s3://$S3_BUCKET/$fileName"
        fi
    fi
done

log "INFO" "Backup process completed successfully"
