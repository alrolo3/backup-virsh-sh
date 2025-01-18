#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

BACKUP_DIR="/var/backups"
LOG_FILE="/var/log/backup_manager.log"

# Colors for GUI elements
RESET="\033[0m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"

# Display the main GUI menu
main_menu() {
    clear
    printf "${CYAN}=======================\n"
    printf "    Backup Manager\n"
    printf "=======================${RESET}\n"
    printf "${GREEN}1) Create Backup Plan\n"
    printf "2) View Backup Plans\n"
    printf "3) Remove Backup Plan\n"
    printf "4) Exit${RESET}\n\n"
    printf "${YELLOW}Choose an option:${RESET} "
}

# Function to create a new backup plan
create_backup_plan() {
    local plan_name src_dir dest_dir schedule
    
    printf "\n${CYAN}Enter a name for the backup plan:${RESET} "
    read -r plan_name

    if [[ -z "$plan_name" ]]; then
        printf "${RED}Plan name cannot be empty.${RESET}\n"
        return 1
    fi

    printf "${CYAN}Enter source directory:${RESET} "
    read -r src_dir

    if [[ ! -d "$src_dir" ]]; then
        printf "${RED}Source directory does not exist.${RESET}\n"
        return 1
    fi

    printf "${CYAN}Enter destination directory:${RESET} "
    read -r dest_dir

    if [[ ! -d "$dest_dir" ]]; then
        printf "${RED}Destination directory does not exist. Creating it now...${RESET}\n"
        mkdir -p "$dest_dir"
    fi

    printf "${CYAN}Enter cron schedule (e.g., '0 2 * * *' for daily at 2 AM):${RESET} "
    read -r schedule

    if [[ -z "$schedule" ]]; then
        printf "${RED}Invalid schedule.${RESET}\n"
        return 1
    fi

    # Create the cron job
    local cron_entry="$schedule rsync -a --delete \"$src_dir\" \"$dest_dir\" >> \"$LOG_FILE\" 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    printf "${GREEN}Backup plan '$plan_name' created successfully!${RESET}\n"
    return 0
}

# Function to display all backup plans
view_backup_plans() {
    printf "\n${CYAN}Current Backup Plans:${RESET}\n"
    local crontab_entries
    crontab_entries=$(crontab -l 2>/dev/null || true)
    
    if [[ -z "$crontab_entries" ]]; then
        printf "${YELLOW}No backup plans found.${RESET}\n"
    else
        printf "${GREEN}$crontab_entries${RESET}\n"
    fi
}

# Function to remove a backup plan
remove_backup_plan() {
    printf "\n${CYAN}Enter the exact cron job to remove (copy from the list of backup plans):${RESET} "
    read -r job_to_remove

    if [[ -z "$job_to_remove" ]]; then
        printf "${RED}Invalid input.${RESET}\n"
        return 1
    fi

    local crontab_entries
    crontab_entries=$(crontab -l 2>/dev/null || true)

    if [[ -z "$crontab_entries" ]]; then
        printf "${YELLOW}No backup plans to remove.${RESET}\n"
        return 1
    fi

    # Remove the specified cron job
    local updated_crontab
    updated_crontab=$(echo "$crontab_entries" | grep -vF "$job_to_remove")

    if [[ "$updated_crontab" == "$crontab_entries" ]]; then
        printf "${RED}Cron job not found.${RESET}\n"
        return 1
    fi

    printf "$updated_crontab" | crontab -
    printf "${GREEN}Backup plan removed successfully!${RESET}\n"
}

# Main function
main() {
    trap "printf '\n${RED}Script interrupted. Exiting...${RESET}\n'; exit 1" SIGINT SIGTERM

    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"

    while true; do
        main_menu
        read -r option

        case $option in
            1)
                create_backup_plan
                ;;
            2)
                view_backup_plans
                ;;
            3)
                remove_backup_plan
                ;;
            4)
                printf "${GREEN}Exiting Backup Manager. Goodbye!${RESET}\n"
                break
                ;;
            *)
                printf "${RED}Invalid option. Please try again.${RESET}\n"
                ;;
        esac
        printf "\nPress Enter to continue..."
        read -r
    done
}

main
