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

# Git settings and utilities
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

function update_local_repo {
    for remote in `git branch -r`; do git branch --track ${remote#origin/} $remote; done
}

function clone_repos_from_github_organisation {
    local organisation="${1:-dheerajchand}"
    local target_dir="${2:-.}"
    
    # Convert target_dir to absolute path
    target_dir=$(realpath "$target_dir")

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' not found."
        return 1
    fi

    echo "Cloning repositories from GitHub organisation '$organisation' into '$target_dir'..."
    
    # Clone repositories from the specified GitHub organisation
    gh repo list "$organisation" --limit 4000 | while read -r repo _; do
        local repo_name=$(basename "$repo")
        local repo_path="$target_dir/$repo_name"
        echo "Processing $repo..."
        
        if [ -d "$repo_path" ]; then
            echo "  Repository $repo_name already exists, updating..."
            (
                cd "$repo_path"
                # Handle case where local checkout is on a non-main/master branch
                # - ignore checkout errors because some repos may have zero commits
                git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null || true
                git pull -q 2>/dev/null || echo "  Warning: Could not pull updates for $repo_name"
            )
        else
            echo "  Cloning $repo..."
            gh repo clone "$repo" "$repo_path" 2>/dev/null || echo "  Warning: Could not clone $repo"
        fi
    done

    echo "Cloning complete."
}
