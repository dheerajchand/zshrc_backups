# Module: Docker

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Docker status, cleanup, and convenience helpers.

## Environment
- None

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `docker_status` | Summary of Docker health | `docker` | Docker daemon running |
| `docker_cleanup` | Remove stopped containers + dangling images | `docker` | User has permission |
| `docker_deep_clean` | Aggressive cleanup | `docker` | Interactive confirmation |
| `docker_shell` | Shell into running container | `docker` | Container exists |
| `docker_logs` | Stream or view logs | `docker` | Container exists |
| `docker_restart_container` | Restart a container | `docker` | Container exists |
| `docker_quick_run` | Run an interactive container | `docker` | Image available or pullable |

## Notes
- Includes aliases: `d`, `dc`, `dps`, `dpsa`, `dimg`, `dstop`, `dexec`, `dlogs`.
