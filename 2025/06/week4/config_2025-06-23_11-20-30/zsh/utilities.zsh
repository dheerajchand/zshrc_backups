# =====================================================
# UTILITY FUNCTIONS & DATABASE CONFIG
# =====================================================

# Database settings
export PGHOST="localhost"
export PGUSER="dheerajchand"
export PGPASSWORD="dessert"
export PGPORT="5432"
export PGDATABASE="gis"
export GEODJANGO_TEMPLATE_SQL_DATABASE="geodjango_template_db"
export GEODJANGO_TEMPLATE_SQL_USER="dheerajchand"
export GEODJANGO_TEMPLATE_SQL_PASSWORD="dessert"
export GEODJANGO_TEMPLATE_SQL_PORT="5432"

# Docker & GIS
export DEFAULT_DOCKER_CONTEXT="rancher-desktop"
if command -v gdal-config &>/dev/null; then
    export GDAL_LIBRARY_PATH="$(gdal-config --prefix)/lib/libgdal.dylib"
fi
if command -v geos-config &>/dev/null; then
    export GEOS_LIBRARY_PATH="$(geos-config --prefix)/lib/libgeos_c.dylib"
fi

# Git settings
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Utility functions
function is_online {
    ping -c 1 google.com &> /dev/null && echo "online" || echo "offline"
}

function cleanvenv {
    pip freeze | grep -v "^-e" | xargs pip uninstall -y
}

function remove_python_cruft {
    find . -name "*.pyc" -delete
    find . -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
}

function delpycache() {
    local target_dir="${1:-.}" # Use current directory if no argument is provided

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' not found."
        return 1
    fi

    echo "Searching for and deleting __pycache__ directories in '$target_dir'..."
    # Find all directories named __pycache__ and delete them recursively
    find "$target_dir" -name "__pycache__" -type d -exec rm -rf {} +
    echo "Deletion complete."
}

function update_local_repo {
    for remote in `git branch -r`; do git branch --track ${remote#origin/} $remote; done
}
