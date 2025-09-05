#!/usr/bin/env zsh

# =====================================================
# DATABASE CONFIGURATION MODULE
# =====================================================
# 
# Secure database connection management with credential integration
# Supports PostgreSQL, MySQL, Snowflake, and other databases
# Maintains backward compatibility with existing environment variables
# =====================================================

# Load credential management system
if [[ -f "$HOME/.config/zsh/config/credentials.zsh" ]]; then
    source "$HOME/.config/zsh/config/credentials.zsh"
fi

# =====================================================
# POSTGRESQL CONFIGURATION
# =====================================================

# PostgreSQL connection settings (maintain existing workflow)
export PGHOST="${PGHOST:-localhost}"
export PGUSER="${PGUSER:-dheerajchand}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-gis}"

# Secure password management for PostgreSQL
setup_postgres_credentials() {
    # Set up PostgreSQL credentials securely
    #
    # Maintains compatibility with existing PGPASSWORD workflow
    # while adding secure credential backend support
    #
    # Usage:
    #     setup_postgres_credentials
    #     setup_postgres_credentials --interactive  # Prompt for password
    local interactive="${1:-}"
    
    echo "🐘 PostgreSQL Credential Setup"
    echo ""
    echo "Host: $PGHOST"
    echo "User: $PGUSER"
    echo "Port: $PGPORT"
    echo "Database: $PGDATABASE"
    echo ""
    
    # Check if PGPASSWORD is already set
    if [[ -n "$PGPASSWORD" ]]; then
        echo "✅ PGPASSWORD already configured"
        return 0
    fi
    
    # Try to get from credential system
    local password
    if password=$(get_credential "postgres" "$PGUSER" "PASSWORD" 2>/dev/null); then
        export PGPASSWORD="$password"
        echo "✅ PostgreSQL credentials loaded from secure storage"
        return 0
    fi
    
    # Interactive setup if requested or no credentials found
    if [[ "$interactive" == "--interactive" ]]; then
        echo "Enter PostgreSQL password for $PGUSER@$PGHOST:"
        read -s password
        echo ""
        
        if [[ -n "$password" ]]; then
            export PGPASSWORD="$password"
            
            # Offer to store securely
            echo -n "Store password securely? (y/n): "
            read store_password
            if [[ "$store_password" == "y" || "$store_password" == "Y" ]]; then
                if store_credential "postgres" "$PGUSER" "$password"; then
                    echo "🔐 Password stored securely for future use"
                fi
            fi
            
            echo "✅ PostgreSQL credentials configured"
            return 0
        fi
    fi
    
    echo "⚠️  PostgreSQL password not configured"
    echo "💡 Options:"
    echo "   1. Set PGPASSWORD environment variable"
    echo "   2. Run: setup_postgres_credentials --interactive"
    echo "   3. Store in 1Password/Keychain and use credential system"
    return 1
}

# PostgreSQL connection helpers
pg_test_connection() {
    # Test PostgreSQL connection
    #
    # Returns:
    #     0: Connection successful
    #     1: Connection failed
    echo "🧪 Testing PostgreSQL connection..."
    echo "Connecting to: $PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
    
    if command -v psql >/dev/null 2>&1; then
        if psql -c "SELECT version();" >/dev/null 2>&1; then
            echo "✅ PostgreSQL connection successful"
            return 0
        else
            echo "❌ PostgreSQL connection failed"
            echo "💡 Try: setup_postgres_credentials --interactive"
            return 1
        fi
    else
        echo "❌ psql command not found"
        echo "💡 Install PostgreSQL client tools"
        return 1
    fi
}

psql_quick() {
    # Quick psql connection with current settings
    #
    # Args:
    #     database (str, optional): Database name (default: PGDATABASE)
    #
    # Examples:
    #     psql_quick
    #     psql_quick mydb
    local database="${1:-$PGDATABASE}"
    
    # Ensure credentials are set up
    if [[ -z "$PGPASSWORD" ]]; then
        setup_postgres_credentials >/dev/null 2>&1
    fi
    
    psql -h "$PGHOST" -U "$PGUSER" -p "$PGPORT" -d "$database"
}

# =====================================================
# GEODJANGO CONFIGURATION
# =====================================================

# GeoDjango template database settings
export GEODJANGO_TEMPLATE_SQL_DATABASE="${GEODJANGO_TEMPLATE_SQL_DATABASE:-geodjango_template_db}"
export GEODJANGO_TEMPLATE_SQL_USER="${GEODJANGO_TEMPLATE_SQL_USER:-dheerajchand}"
export GEODJANGO_TEMPLATE_SQL_PORT="${GEODJANGO_TEMPLATE_SQL_PORT:-5432}"

setup_geodjango_credentials() {
    # Set up GeoDjango template database credentials
    echo "🌍 GeoDjango Credential Setup"
    
    # Use same credentials as main PostgreSQL by default
    if [[ -z "$GEODJANGO_TEMPLATE_SQL_PASSWORD" ]]; then
        if password=$(get_credential "postgres" "$GEODJANGO_TEMPLATE_SQL_USER" "PASSWORD" 2>/dev/null); then
            export GEODJANGO_TEMPLATE_SQL_PASSWORD="$password"
            echo "✅ GeoDjango credentials configured"
        else
            echo "⚠️  GeoDjango credentials not found"
            echo "💡 Configure PostgreSQL credentials first"
        fi
    fi
}

# =====================================================
# SNOWFLAKE CONFIGURATION
# =====================================================

# Snowflake connection helpers
export SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-}"
export SNOWFLAKE_USER="${SNOWFLAKE_USER:-dheerajchand}"
export SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_WAREHOUSE:-}"
export SNOWFLAKE_DATABASE="${SNOWFLAKE_DATABASE:-}"
export SNOWFLAKE_SCHEMA="${SNOWFLAKE_SCHEMA:-PUBLIC}"

setup_snowflake_credentials() {
    # Set up Snowflake credentials
    #
    # Args:
    #     --interactive: Prompt for missing configuration
    local interactive="${1:-}"
    
    echo "❄️  Snowflake Credential Setup"
    echo ""
    
    # Check required settings
    if [[ -z "$SNOWFLAKE_ACCOUNT" ]]; then
        if [[ "$interactive" == "--interactive" ]]; then
            echo -n "Snowflake Account ID: "
            read SNOWFLAKE_ACCOUNT
            export SNOWFLAKE_ACCOUNT
        else
            echo "❌ SNOWFLAKE_ACCOUNT not set"
            echo "💡 Run: setup_snowflake_credentials --interactive"
            return 1
        fi
    fi
    
    echo "Account: $SNOWFLAKE_ACCOUNT"
    echo "User: $SNOWFLAKE_USER"
    echo "Warehouse: ${SNOWFLAKE_WAREHOUSE:-not set}"
    echo "Database: ${SNOWFLAKE_DATABASE:-not set}"
    echo ""
    
    # Set up password
    if [[ -z "$SNOWFLAKE_PASSWORD" ]]; then
        local password
        if password=$(get_credential "snowflake" "$SNOWFLAKE_USER" "PASSWORD" 2>/dev/null); then
            export SNOWFLAKE_PASSWORD="$password"
            echo "✅ Snowflake credentials loaded"
        elif [[ "$interactive" == "--interactive" ]]; then
            echo "Enter Snowflake password for $SNOWFLAKE_USER:"
            read -s password
            echo ""
            
            if [[ -n "$password" ]]; then
                export SNOWFLAKE_PASSWORD="$password"
                
                # Offer to store securely
                echo -n "Store password securely? (y/n): "
                read store_password
                if [[ "$store_password" == "y" || "$store_password" == "Y" ]]; then
                    store_credential "snowflake" "$SNOWFLAKE_USER" "$password"
                fi
                
                echo "✅ Snowflake credentials configured"
            fi
        else
            echo "⚠️  Snowflake password not configured"
            return 1
        fi
    fi
}

# =====================================================
# MYSQL CONFIGURATION
# =====================================================

# MySQL connection helpers
export MYSQL_HOST="${MYSQL_HOST:-localhost}"
export MYSQL_USER="${MYSQL_USER:-$USER}"
export MYSQL_PORT="${MYSQL_PORT:-3306}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-}"

setup_mysql_credentials() {
    # Set up MySQL credentials
    echo "🐬 MySQL Credential Setup"
    echo ""
    echo "Host: $MYSQL_HOST"
    echo "User: $MYSQL_USER"
    echo "Port: $MYSQL_PORT"
    echo ""
    
    if [[ -z "$MYSQL_PASSWORD" ]]; then
        local password
        if password=$(get_credential "mysql" "$MYSQL_USER" "PASSWORD" 2>/dev/null); then
            export MYSQL_PASSWORD="$password"
            echo "✅ MySQL credentials loaded"
        else
            echo "⚠️  MySQL password not configured"
            echo "💡 Use credential system or set MYSQL_PASSWORD"
        fi
    fi
}

mysql_quick() {
    # Quick MySQL connection
    #
    # Args:
    #     database (str, optional): Database name
    local database="${1:-$MYSQL_DATABASE}"
    
    # Ensure credentials are set up
    if [[ -z "$MYSQL_PASSWORD" ]]; then
        setup_mysql_credentials >/dev/null 2>&1
    fi
    
    local mysql_cmd="mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD"
    
    if [[ -n "$database" ]]; then
        mysql_cmd="$mysql_cmd $database"
    fi
    
    eval "$mysql_cmd"
}

# =====================================================
# DATABASE STATUS & TESTING
# =====================================================

database_status() {
    # Show status of all configured databases
    echo "🗄️  Database Configuration Status"
    echo ""
    
    # PostgreSQL
    echo "PostgreSQL:"
    echo "  Host: $PGHOST:$PGPORT"
    echo "  User: $PGUSER"
    echo "  Database: $PGDATABASE"
    if [[ -n "$PGPASSWORD" ]]; then
        echo "  Credentials: ✅ Configured"
    else
        echo "  Credentials: ❌ Not configured"
    fi
    echo ""
    
    # GeoDjango
    echo "GeoDjango Template:"
    echo "  Database: $GEODJANGO_TEMPLATE_SQL_DATABASE"
    echo "  User: $GEODJANGO_TEMPLATE_SQL_USER"
    if [[ -n "$GEODJANGO_TEMPLATE_SQL_PASSWORD" ]]; then
        echo "  Credentials: ✅ Configured"
    else
        echo "  Credentials: ❌ Not configured"
    fi
    echo ""
    
    # Snowflake
    echo "Snowflake:"
    if [[ -n "$SNOWFLAKE_ACCOUNT" ]]; then
        echo "  Account: $SNOWFLAKE_ACCOUNT"
        echo "  User: $SNOWFLAKE_USER"
        if [[ -n "$SNOWFLAKE_PASSWORD" ]]; then
            echo "  Credentials: ✅ Configured"
        else
            echo "  Credentials: ❌ Not configured"
        fi
    else
        echo "  Not configured"
    fi
    echo ""
    
    # MySQL
    echo "MySQL:"
    echo "  Host: $MYSQL_HOST:$MYSQL_PORT"
    echo "  User: $MYSQL_USER"
    if [[ -n "$MYSQL_PASSWORD" ]]; then
        echo "  Credentials: ✅ Configured"
    else
        echo "  Credentials: ❌ Not configured"
    fi
}

test_all_databases() {
    # Test connections to all configured databases
    echo "🧪 Testing Database Connections"
    echo ""
    
    # Test PostgreSQL
    if [[ -n "$PGPASSWORD" ]]; then
        pg_test_connection
    else
        echo "⏭️  PostgreSQL: Skipping (no credentials)"
    fi
    
    echo ""
    
    # Test MySQL
    if [[ -n "$MYSQL_PASSWORD" ]] && command -v mysql >/dev/null 2>&1; then
        echo "🧪 Testing MySQL connection..."
        if mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" >/dev/null 2>&1; then
            echo "✅ MySQL connection successful"
        else
            echo "❌ MySQL connection failed"
        fi
    else
        echo "⏭️  MySQL: Skipping (no credentials or mysql not installed)"
    fi
    
    echo ""
    echo "💡 Use individual setup functions for interactive configuration:"
    echo "   setup_postgres_credentials --interactive"
    echo "   setup_snowflake_credentials --interactive"
}

# =====================================================
# MIGRATION HELPERS
# =====================================================

migrate_to_secure_credentials() {
    # Help migrate from plaintext to secure credential storage
    echo "🔐 Database Credential Migration"
    echo ""
    echo "This will help you migrate existing plaintext credentials"
    echo "to secure storage (1Password/Keychain)."
    echo ""
    
    local migrated=0
    
    # PostgreSQL
    if [[ -n "$PGPASSWORD" ]]; then
        echo "Found PostgreSQL credentials in environment"
        echo -n "Store PostgreSQL password securely? (y/n): "
        read store_pg
        if [[ "$store_pg" == "y" || "$store_pg" == "Y" ]]; then
            if store_credential "postgres" "$PGUSER" "$PGPASSWORD"; then
                echo "💡 You can now remove PGPASSWORD from environment"
                ((migrated++))
            fi
        fi
        echo ""
    fi
    
    # Snowflake
    if [[ -n "$SNOWFLAKE_PASSWORD" ]]; then
        echo "Found Snowflake credentials in environment"
        echo -n "Store Snowflake password securely? (y/n): "
        read store_sf
        if [[ "$store_sf" == "y" || "$store_sf" == "Y" ]]; then
            if store_credential "snowflake" "$SNOWFLAKE_USER" "$SNOWFLAKE_PASSWORD"; then
                echo "💡 You can now remove SNOWFLAKE_PASSWORD from environment"
                ((migrated++))
            fi
        fi
        echo ""
    fi
    
    if [[ $migrated -gt 0 ]]; then
        echo "✅ Migrated $migrated credential(s) to secure storage"
        echo "💡 Restart your shell to use the secure credentials"
    else
        echo "No credentials found to migrate"
    fi
}

# =====================================================
# ALIASES AND SHORTCUTS
# =====================================================

# PostgreSQL shortcuts
alias pg='psql_quick'
alias pgtest='pg_test_connection'
alias pgsetup='setup_postgres_credentials --interactive'

# MySQL shortcuts  
alias mysetup='setup_mysql_credentials'
alias mytest='mysql_quick'

# Snowflake shortcuts
alias sfsetup='setup_snowflake_credentials --interactive'

# General database management
alias db-status='database_status'
alias db-test='test_all_databases'
alias db-migrate='migrate_to_secure_credentials'

# =====================================================
# INITIALIZATION
# =====================================================

# Auto-setup credentials if environment variables exist
if [[ "$DATABASE_AUTO_SETUP" == "true" ]]; then
    setup_postgres_credentials >/dev/null 2>&1
    setup_geodjango_credentials >/dev/null 2>&1
    setup_mysql_credentials >/dev/null 2>&1
fi