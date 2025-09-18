#!/usr/bin/env zsh
# =====================================================
# DATABASE MODULE - Database connection and management
# =====================================================
#
# Purpose: Database connectivity and quick operations
# Provides: PostgreSQL, MySQL connection helpers
# Dependencies: centralized variables
# =====================================================

echo "🗄️ Loading Database module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# DATABASE FUNCTIONS
# =====================================================

# Purpose: Show database connection status and configuration
# Arguments: None
# Returns: 0 always
# Usage: database_status
database_status() {
    echo "🗄️ Database Connection Status"
    echo "============================="

    # PostgreSQL status
    echo "🐘 PostgreSQL:"
    if command -v psql >/dev/null 2>&1; then
        echo "✅ psql: Available"
        echo "🔧 Configuration:"
        echo "  Host: $PGHOST"
        echo "  Port: $PGPORT"
        echo "  User: $PGUSER"
        echo "  Database: $PGDATABASE"

        # Test connection
        if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' 2>/dev/null; then
            echo "✅ Connection: Success"
        else
            echo "❌ Connection: Failed"
        fi
    else
        echo "❌ psql: Not installed"
    fi

    echo ""

    # MySQL status
    echo "🐬 MySQL:"
    if command -v mysql >/dev/null 2>&1; then
        echo "✅ mysql: Available"
    else
        echo "❌ mysql: Not installed"
    fi
}

# Purpose: Quick PostgreSQL connection
# Arguments: $1 - optional database name
# Returns: 0 on success, 1 on error
# Usage: pg [database_name]
pg() {
    local database="${1:-$PGDATABASE}"

    if ! command -v psql >/dev/null 2>&1; then
        echo "❌ PostgreSQL client not installed"
        return 1
    fi

    echo "🐘 Connecting to PostgreSQL: $database@$PGHOST:$PGPORT"
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$database"
}

# Purpose: Setup PostgreSQL credentials interactively
# Arguments: None
# Returns: 0 on success
# Usage: setup_postgres_credentials
setup_postgres_credentials() {
    echo "🔧 PostgreSQL Credential Setup"
    echo "=============================="

    # Get credentials
    echo -n "Host [$PGHOST]: "
    read -r host
    [[ -n "$host" ]] && export PGHOST="$host"

    echo -n "Port [$PGPORT]: "
    read -r port
    [[ -n "$port" ]] && export PGPORT="$port"

    echo -n "Username [$PGUSER]: "
    read -r user
    [[ -n "$user" ]] && export PGUSER="$user"

    echo -n "Database [$PGDATABASE]: "
    read -r database
    [[ -n "$database" ]] && export PGDATABASE="$database"

    echo "✅ Credentials configured"
    echo "🧪 Testing connection..."

    if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' 2>/dev/null; then
        echo "✅ Connection successful!"
    else
        echo "❌ Connection failed. Please check credentials."
        return 1
    fi
}

# =====================================================
# ADVANCED DATABASE FEATURES
# =====================================================

# Purpose: Create database backup with optimal settings
# Arguments: $1 - database name, $2 - optional backup directory
# Returns: 0 on success, 1 on error
# Usage: db_backup mydb [/path/to/backups]
db_backup() {
    local database="$1"
    local backup_dir="${2:-./backups}"

    if [[ -z "$database" ]]; then
        echo "❌ Usage: db_backup <database_name> [backup_directory]"
        return 1
    fi

    if ! command -v pg_dump >/dev/null 2>&1; then
        echo "❌ Can't find PostgreSQL backup tools"
        echo "💡 Install PostgreSQL with: brew install postgresql"
        return 1
    fi

    mkdir -p "$backup_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${database}_${timestamp}.sql"

    echo "📦 Creating database backup..."
    echo "🗄️ Database: $database"
    echo "📁 Output: $backup_file"

    pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
            --clean --if-exists --create --verbose \
            "$database" > "$backup_file"

    if [[ $? -eq 0 ]]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo "✅ Backup created successfully ($size)"
        echo "📁 Location: $backup_file"

        # Compress backup
        echo "🗜️  Compressing backup..."
        gzip "$backup_file"
        echo "✅ Compressed: ${backup_file}.gz"
        return 0
    else
        echo "❌ Backup failed"
        return 1
    fi
}

# Purpose: Restore database from backup
# Arguments: $1 - backup file, $2 - target database name
# Returns: 0 on success, 1 on error
# Usage: db_restore backup.sql.gz mydb
db_restore() {
    local backup_file="$1"
    local database="$2"

    if [[ -z "$backup_file" || -z "$database" ]]; then
        echo "❌ Usage: db_restore <backup_file> <database_name>"
        return 1
    fi

    if [[ ! -f "$backup_file" ]]; then
        echo "❌ Backup file not found: $backup_file"
        return 1
    fi

    echo "🔄 Restoring database from backup..."
    echo "📁 Backup: $backup_file"
    echo "🗄️ Target: $database"

    # Handle compressed files
    if [[ "$backup_file" == *.gz ]]; then
        echo "🗜️  Decompressing backup..."
        gunzip -c "$backup_file" | psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$database"
    else
        psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$database" < "$backup_file"
    fi

    if [[ $? -eq 0 ]]; then
        echo "✅ Database restored successfully"
        return 0
    else
        echo "❌ Database restore failed"
        return 1
    fi
}

# Purpose: List all databases and their sizes
# Arguments: None
# Returns: 0 on success, 1 on error
# Usage: db_list
db_list() {
    if ! command -v psql >/dev/null 2>&1; then
        echo "❌ PostgreSQL client not installed"
        return 1
    fi

    echo "🗄️ Database List"
    echo "==============="

    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -c "
        SELECT
            datname as \"Database\",
            pg_size_pretty(pg_database_size(datname)) as \"Size\",
            (SELECT count(*) FROM pg_stat_activity WHERE datname = pg_stat_activity.datname) as \"Connections\"
        FROM pg_database
        WHERE datistemplate = false
        ORDER BY pg_database_size(datname) DESC;
    " 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to connect to PostgreSQL"
        echo "💡 Check connection with: database_status"
        return 1
    fi
}

# Purpose: Execute SQL query with formatted output
# Arguments: $1 - SQL query, $2 - optional database
# Returns: 0 on success, 1 on error
# Usage: db_query "SELECT * FROM users LIMIT 5" mydb
db_query() {
    local query="$1"
    local database="${2:-$PGDATABASE}"

    if [[ -z "$query" ]]; then
        echo "❌ Usage: db_query \"<SQL_QUERY>\" [database]"
        return 1
    fi

    echo "🔍 Executing query on database: $database"
    echo "📜 Query: $query"
    echo ""

    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$database" \
         -c "$query" \
         --field-separator='|' \
         --align \
         --border=2 \
         --header

    if [[ $? -ne 0 ]]; then
        echo "❌ Query execution failed"
        return 1
    fi
}

# Purpose: Database health check
# Arguments: None
# Returns: 0 if healthy, 1 if issues found
# Usage: db_health
db_health() {
    echo "🏥 Database Health Check"
    echo "======================="

    local issues=0

    # Check PostgreSQL client
    if command -v psql >/dev/null 2>&1; then
        echo "✅ PostgreSQL client installed"
    else
        echo "❌ Can't find PostgreSQL client tools"
        echo "💡 Install PostgreSQL with: brew install postgresql"
        ((issues++))
    fi

    # Check connection
    if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' 2>/dev/null; then
        echo "✅ Database connection successful"

        # Check database size
        local db_size=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
                        -t -c "SELECT pg_size_pretty(pg_database_size('$PGDATABASE'));" 2>/dev/null | tr -d ' ')
        echo "📊 Database size: $db_size"

        # Check active connections
        local active_conn=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres \
                           -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PGDATABASE';" 2>/dev/null | tr -d ' ')
        echo "🔗 Active connections: $active_conn"

    else
        echo "❌ Can't connect to your database"
        echo "💡 Check if PostgreSQL is running: brew services start postgresql"
        echo "💡 Check credentials with: database_status"
        ((issues++))
    fi

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "🎉 Database is healthy!"
        return 0
    else
        echo "⚠️  Found $issues issues"
        return 1
    fi
}

# =====================================================
# ALIASES
# =====================================================

alias db-status='database_status'
alias pg-setup='setup_postgres_credentials'
alias db-backup='db_backup'
alias db-restore='db_restore'
alias db-list='db_list'
alias db-query='db_query'
alias db-health='db_health'

echo "✅ Database module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DATABASE_MODULE_LOADED=true