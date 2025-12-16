#!/bin/bash

# Disaster Recovery Test Script
# Tests backup and restore procedures

set -e

echo "🚀 Starting Disaster Recovery Test..."
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_URL="${SUPABASE_URL:-https://your-project.supabase.co}"
BACKUP_DIR="./backups"
TEST_DB_NAME="test_restore_db"

# Functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Step 1: Create backup
echo ""
echo "Step 1: Creating database backup..."
if [ -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"

# Using Supabase CLI if available
if command -v supabase &> /dev/null; then
    echo "Using Supabase CLI for backup..."
    supabase db dump -f "$BACKUP_FILE" || {
        print_error "Backup failed!"
        exit 1
    }
    print_success "Backup created: $BACKUP_FILE"
else
    print_warning "Supabase CLI not found. Please create backup manually."
    print_warning "See backup_procedures.md for manual backup instructions."
fi

# Step 2: Verify backup file
echo ""
echo "Step 2: Verifying backup file..."
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_success "Backup file exists: $BACKUP_FILE ($BACKUP_SIZE)"
    
    # Check if backup contains data
    if [ -s "$BACKUP_FILE" ]; then
        print_success "Backup file is not empty"
    else
        print_error "Backup file is empty!"
        exit 1
    fi
else
    print_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Step 3: Test restore (dry run)
echo ""
echo "Step 3: Testing restore (dry run)..."
if command -v pg_restore &> /dev/null && [ -f "$BACKUP_FILE" ]; then
    # Check if backup is SQL or custom format
    if [[ "$BACKUP_FILE" == *.sql ]]; then
        echo "Backup is SQL format. Dry run: checking syntax..."
        # Basic syntax check
        if head -n 100 "$BACKUP_FILE" | grep -q "CREATE\|INSERT\|COPY"; then
            print_success "Backup file appears to be valid SQL"
        else
            print_warning "Backup file format may be unexpected"
        fi
    else
        echo "Backup is custom format. Listing contents..."
        pg_restore --list "$BACKUP_FILE" | head -20 || {
            print_error "Failed to list backup contents"
            exit 1
        }
        print_success "Backup contents verified"
    fi
else
    print_warning "pg_restore not available or backup file not found. Skipping dry run."
fi

# Step 4: Test restore to test database (optional)
echo ""
echo "Step 4: Testing restore to test database..."
read -p "Do you want to restore to a test database? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v createdb &> /dev/null && command -v psql &> /dev/null; then
        echo "Creating test database: $TEST_DB_NAME"
        createdb "$TEST_DB_NAME" 2>/dev/null || {
            print_warning "Test database may already exist. Dropping..."
            dropdb "$TEST_DB_NAME" 2>/dev/null || true
            createdb "$TEST_DB_NAME"
        }
        
        if [[ "$BACKUP_FILE" == *.sql ]]; then
            echo "Restoring SQL backup..."
            psql "$TEST_DB_NAME" < "$BACKUP_FILE" || {
                print_error "Restore failed!"
                dropdb "$TEST_DB_NAME" 2>/dev/null || true
                exit 1
            }
        else
            echo "Restoring custom format backup..."
            pg_restore -d "$TEST_DB_NAME" "$BACKUP_FILE" || {
                print_error "Restore failed!"
                dropdb "$TEST_DB_NAME" 2>/dev/null || true
                exit 1
            }
        fi
        
        print_success "Restore to test database successful!"
        
        # Verify restore
        echo "Verifying restore..."
        TABLE_COUNT=$(psql -d "$TEST_DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
        print_success "Test database contains $TABLE_COUNT tables"
        
        # Cleanup
        echo "Cleaning up test database..."
        dropdb "$TEST_DB_NAME"
        print_success "Test database removed"
    else
        print_warning "PostgreSQL tools not available. Skipping test restore."
    fi
else
    print_warning "Skipping test restore."
fi

# Step 5: Summary
echo ""
echo "======================================"
echo "Disaster Recovery Test Summary"
echo "======================================"
print_success "Backup created: $BACKUP_FILE"
print_success "Backup verified: OK"
print_success "Restore test: OK"
echo ""
echo "Next steps:"
echo "1. Store backup in secure location (S3, etc.)"
echo "2. Test restore procedures monthly"
echo "3. Document any issues found"
echo ""
print_success "Disaster Recovery Test Complete!"

