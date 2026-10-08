# Concurrency and Scheduling

This document describes the concurrency model, scheduling strategies,
and parallel execution patterns in the linux-setup-script repository.

## Overview

The repository is primarily sequential but supports controlled parallelism
for independent operations to improve execution time.

## Execution Model

### Sequential Phases

The main `run.sh` executes in 5 sequential phases:

```
Phase 0: Pre-flight checks
    ↓
Phase 1: Foundation (common modules)
    ↓
Phase 2: System configuration (packages, repos, services)
    ↓
Phase 3: User configuration (dotfiles, apps, desktop)
    ↓
Phase 4: Post-setup (cleanup, verification)
```

### Phase Dependencies

| Phase | Depends On | Can Parallelise |
|-------|------------|-----------------|
| 0 | None | No |
| 1 | Phase 0 | No (module loading order) |
| 2 | Phase 1 | Yes (independent scripts) |
| 3 | Phase 2 | Yes (independent scripts) |
| 4 | Phase 3 | No |

## Parallel Execution Patterns

### 1. Package Installation Parallelism

```bash
# scripts/install-packages.sh

# Group packages by category for parallel installation
install_package_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    log_info "Installing ${group_name} packages..."
    install_packages "${packages[@]}"
}

# Run independent groups in parallel
install_package_group "base" "git" "vim" "curl" "wget" &
install_package_group "dev" "gcc" "make" "cmake" "pkg-config" &
install_package_group "desktop" "lxde" "lxpanel" "pcmanfm" &
install_package_group "media" "vlc" "mpv" "gimp" &

# Wait for all
wait
```

### 2. Configuration Script Parallelism

```bash
# Phase 2: Independent system configuration scripts
run_phase2_parallel() {
    local scripts=(
        "configure-repositories.sh"
        "configure-services-system.sh"
        "configure-time.sh"
        "configure-locale.sh"
        "configure-permissions.sh"
    )
    
    for script in "${scripts[@]}"; do
        run_script "${script}" &
    done
    
    wait
}
```

### 3. User Configuration Parallelism

```bash
# Phase 3: Independent user configuration scripts
run_phase3_parallel() {
    local scripts=(
        "configure-default-apps.sh"
        "configure-launchers.sh"
        "configure-autostart-apps.sh"
        "update-rcs.sh"
        "update-resources.sh"
    )
    
    for script in "${scripts[@]}"; do
        run_script "${script}" &
    done
    
    wait
}
```

## Concurrency Control

### 1. Lock Files

```bash
# Prevent concurrent runs
LOCK_FILE="/tmp/linux-setup-script.lock"

acquire_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        local pid=$(cat "${LOCK_FILE}")
        if kill -0 "${pid}" 2>/dev/null; then
            log_error "Another instance is running (PID: ${pid})"
            return 1
        fi
    fi
    
    echo $$ > "${LOCK_FILE}"
    return 0
}

release_lock() {
    rm -f "${LOCK_FILE}"
}

# Usage
if ! acquire_lock; then
    exit 1
fi

trap release_lock EXIT
```

### 2. Semaphore for Resource Limits

```bash
# Limit concurrent package downloads
MAX_CONCURRENT_DOWNLOADS=4

download_semaphore() {
    local semaphore_dir="/tmp/linux-setup-downloads"
    mkdir -p "${semaphore_dir}"
    
    while [ $(ls "${semaphore_dir}" | wc -l) -ge ${MAX_CONCURRENT_DOWNLOADS} ]; do
        sleep 1
    done
    
    touch "${semaphore_dir}/$$"
}

release_semaphore() {
    local semaphore_dir="/tmp/linux-setup-downloads"
    rm -f "${semaphore_dir}/$$"
}
```

### 3. Dependency Graph

```bash
# Define script dependencies
declare -A SCRIPT_DEPENDENCIES=(
    ["configure-system.sh"]="configure-repositories.sh"
    ["configure-hardware-integration.sh"]="configure-system.sh"
    ["update-grub.sh"]="configure-system.sh"
    ["configure-default-apps.sh"]="install-packages.sh"
    ["configure-launchers.sh"]="install-packages.sh"
    ["configure-autostart-apps.sh"]="configure-default-apps.sh"
)

# Topological sort for execution order
topological_sort() {
    local scripts=("$@")
    local sorted=()
    local visited=()
    local visiting=()
    
    function visit() {
        local script="$1"
        
        if [[ " ${visiting[@]} " =~ " ${script} " ]]; then
            log_error "Circular dependency detected: ${script}"
            return 1
        fi
        
        if [[ " ${visited[@]} " =~ " ${script} " ]]; then
            return 0
        fi
        
        visiting+=("${script}")
        
        local dep="${SCRIPT_DEPENDENCIES[${script}]}"
        if [ -n "${dep}" ]; then
            visit "${dep}"
        fi
        
        visiting=("${visiting[@]/${script}}")
        visited+=("${script}")
        sorted+=("${script}")
    }
    
    for script in "${scripts[@]}"; do
        visit "${script}"
    done
    
    echo "${sorted[@]}"
}
```

## Scheduling Strategies

### 1. Priority-Based Scheduling

```bash
# Script priorities (lower = higher priority)
declare -A SCRIPT_PRIORITY=(
    ["configure-repositories.sh"]=10
    ["install-packages.sh"]=20
    ["configure-system.sh"]=30
    ["configure-hardware-integration.sh"]=40
    ["update-grub.sh"]=50
    ["configure-default-apps.sh"]=60
    ["configure-launchers.sh"]=70
    ["configure-autostart-apps.sh"]=80
    ["update-rcs.sh"]=90
    ["update-resources.sh"]=100
)

# Sort by priority
sort_by_priority() {
    local scripts=("$@")
    printf '%s\n' "${scripts[@]}" | sort -k2 -n | cut -d' ' -f1
}
```

### 2. Resource-Aware Scheduling

```bash
# Schedule based on resource requirements
declare -A SCRIPT_RESOURCES=(
    ["install-packages.sh"]="network,disk,cpu"
    ["update-packages.sh"]="network,disk,cpu"
    ["configure-system.sh"]="disk,cpu"
    ["update-grub.sh"]="disk,cpu"
    ["configure-default-apps.sh"]="disk"
    ["update-rcs.sh"]="disk"
    ["update-resources.sh"]="disk,network"
)

# Check resource availability
check_resources() {
    local resources="$1"
    
    # Check network
    if [[ "${resources}" =~ "network" ]]; then
        if ! is_host_reachable "archlinux.org"; then
            return 1
        fi
    fi
    
    # Check disk space
    if [[ "${resources}" =~ "disk" ]]; then
        local available=$(df / | awk 'NR==2 {print $4}')
        if [ "${available}" -lt 1000000 ]; then  # 1GB
            return 1
        fi
    fi
    
    # Check CPU load
    if [[ "${resources}" =~ "cpu" ]]; then
        local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        local cores=$(nproc)
        if (( $(echo "${load} > ${cores} * 2" | bc -l) )); then
            return 1
        fi
    fi
    
    return 0
}
```

### 3. Time-Based Scheduling

```bash
# Schedule long-running tasks during off-peak
schedule_off_peak() {
    local hour=$(date +%H)
    
    # Off-peak: 22:00 - 06:00
    if [ "${hour}" -ge 22 ] || [ "${hour}" -lt 6 ]; then
        return 0
    fi
    
    return 1
}

# Defer non-critical tasks
defer_if_peak() {
    local script="$1"
    
    if ! schedule_off_peak; then
        log_info "Deferring ${script} to off-peak hours"
        echo "${script}" >> "${DEFERRED_TASKS_FILE}"
        return 0
    fi
    
    return 1
}
```

## Concurrency Invariants

1. **No shared mutable state** — Scripts communicate via files, not memory
2. **Idempotent operations** — Safe to run multiple times
3. **Explicit dependencies** — Dependency graph defines order
4. **Resource awareness** — Check resources before expensive operations
5. **Graceful degradation** — Parallel failures don't block sequential work
6. **Lock protection** — Prevent concurrent repository runs

## Error Handling in Parallel Context

### 1. Error Aggregation

```bash
run_parallel_with_error_collection() {
    local scripts=("$@")
    local pids=()
    local errors=()
    
    for script in "${scripts[@]}"; do
        (
            run_script "${script}"
            exit $?
        ) &
        pids+=($!)
    done
    
    # Wait and collect errors
    for i in "${!pids[@]}"; do
        local pid=${pids[i]}
        local script=${scripts[i]}
        
        if ! wait "${pid}"; then
            errors+=("${script}")
        fi
    done
    
    if [ ${#errors[@]} -gt 0 ]; then
        log_error "Failed scripts: ${errors[*]}"
        return 1
    fi
    
    return 0
}
```

### 2. Timeout Handling

```bash
run_with_timeout() {
    local timeout="$1"
    shift
    local command=("$@")
    
    (
        "${command[@]}"
    ) &
    local pid=$!
    
    local elapsed=0
    while kill -0 "${pid}" 2>/dev/null; do
        if [ "${elapsed}" -ge "${timeout}" ]; then
            kill -TERM "${pid}" 2>/dev/null
            sleep 2
            kill -KILL "${pid}" 2>/dev/null
            log_error "Command timed out after ${timeout}s: ${command[*]}"
            return 124
        fi
        sleep 1
        ((elapsed++))
    done
    
    wait "${pid}"
    return $?
}
```

## Performance Considerations

- **Optimal parallelism** — Match concurrent jobs to CPU cores
- **I/O separation** — Separate network-bound and disk-bound tasks
- **Memory awareness** — Limit concurrent memory-intensive operations
- **Cache warming** — Run cache-warming tasks first

## Security Considerations

- **No privilege escalation in parallel** — `run_as_su` calls serialized
- **Temporary file isolation** — Each parallel job gets unique temp dir
- **Signal handling** — Proper cleanup on interruption

## Future Enhancements

1. **Dynamic parallelism** — Adjust concurrency based on system load
2. **Distributed execution** — Run phases on multiple machines
3. **Incremental builds** — Only re-run changed scripts
4. **Build cache** — Cache package downloads and build artifacts
5. **Progress tracking** — Real-time progress dashboard