#!/usr/bin/env bash

# constants
EXIT_CODE_GENERAL=1
EXIT_CODE_INVALID_STATE=2
EXIT_CODE_INVALID_ARGUMENT=3
EXIT_CODE_INVALID_COMMAND=4
EXIT_CODE_ABORT=5
EXIT_CODE_INVALID_STATE=6
PRINT_USAGE=true
PROJECT_NAME_REGEX="^[a-zA-Z][a-zA-Z0-9_-]*$"

# only enable colors when supported
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# Color Constants
	C_RESET="\033[0m"
	C_LOG_DATE="\033[0;36m"
	C_DRY_RUN_COMMAND="\033[1;35m"
	C_HIGHLIGHT="\033[1;34m"
	C_INFO="\033[0;32m"
	C_VERBOSE="\033[0;36m"
	C_WARNING="\033[1;33m"
	C_ERROR="\033[0;31m"
	C_STATUS="\033[1m"
else
	C_RESET=''
	C_LOG_DATE=''
	C_HIGHLIGHT=''
	C_VERBOSE=''
	C_INFO=''
	C_WARNING=''
	C_ERROR=''
	C_DRY_RUN_COMMAND=''
	C_STATUS=''
fi

self=$(basename "$0")

# define variables
ide_sync_config_file=~/.ide-sync
settings_directory=
init_settings_directory=
project_name=
project_directory=
is_dry_run=false
dry_run=
verbose=false
command=

usage() {
	echo -e
	echo -e "IDE Settings Sync"
	echo -e
	echo -e "Usage: ${self} init [options] <settings-directory>"
	echo -e "       ${self} track [options] <project-name>"
	echo -e "       ${self} link [options] <project-name>"
	echo -e "       ${self} commit [options]"
	echo -e "       ${self} sync [options]"
	echo -e "       ${self} list"
	echo -e "       ${self} --help"
	echo -e
	echo -e "Arguments:"
	echo -e "  $(highlight settings-directory)    The location where the repository will be created."
	echo -e "  $(highlight project-name)          The name used a reference for the project"
	echo -e
	echo -e "Options:"
	echo -e "  $(highlight "--config <v>")     The path to load the configuration file. This can be used to support"
	echo -e "                   multiple repositories. Default: ${ide_sync_config_file}"
	echo -e
	echo -e "  $(highlight "--verbose, -v")    Show more verbose output of actions performed"
	echo -e
	echo -e "  $(highlight "--dry-run")        Do not perform actions that will have consequences. Providing this"
	echo -e "                   options also assumes $(highlight "--verbose")."
	echo -e
	echo -e "  $(highlight "--help")           Show this usage message and exit"
	echo -e
}

highlight() {
	echo "${C_HIGHLIGHT}${@}${C_RESET}"
}

message() {
	message=$(date '+%Y/%m/%d %H:%M:%S')
	message="[${C_LOG_DATE}${message}${C_RESET}] ${@}"
	echo -e "${message}"
}

info_message() {
	message "${C_INFO}   [INFO]${C_RESET} ${@}"
}

verbose_message() {
	if ${verbose}; then
		message "${C_VERBOSE}[VERBOSE]${C_RESET} ${@}"
	fi
}

warning() {
	message "${C_WARNING}[WARNING]${C_RESET} ${@}"
}

error() {
	>&2 message "${C_ERROR}  [ERROR]${C_RESET} ${1}"

	if [[ ${3} ]]; then
		>&2 usage
	fi

	if [[ ! -z ${2} ]]; then
		exit "$2"
	fi
}

dry_run_message() {
	message "${C_DRY_RUN_COMMAND}[DRY RUN]${C_RESET} ${@}"
}

argument_error() {
	error "Unexpected argument: $(highlight "${@}")" ${EXIT_CODE_INVALID_ARGUMENT} ${PRINT_USAGE}
}

abort() {
	error "User aborted" ${EXIT_CODE_ABORT}
}

check_existing_symlink() {
	# .idea path already a symlink
	if [[ -h ".idea" ]]; then
		error "Project appears to already be tracked" ${EXIT_CODE_INVALID_STATE}
	fi
}

command_init() {
	local remote
	if [[ -z "${settings_directory}" ]]; then
		error "Settings directory was not provided" ${EXIT_CODE_INVALID_ARGUMENT} ${PRINT_USAGE}
	fi

	if [[ ! -d "${settings_directory}" ]]; then
		warning "Settings directory does not exist; creating"
		${dry_run} mkdir -p "${settings_directory}"
	fi

	if [[ -z ${dry_run} ]] && [[ -d "${settings_directory}/.git" ]]; then
		error "${settings_directory} is already a git repository" ${EXIT_CODE_INVALID_STATE}
	fi

	verbose_message "Changing to settings directory"
	${dry_run} cd "${settings_directory}"

	echo -e
	echo -e "To continue you will need to enter a remote git repository."
	echo -e "You can use the shorthand $(highlight "gh:username/repo") for a GitHub repository or $(highlight "bb:username/repo") for Bitbucket."
	echo -e "By default $(highlight "git+ssh") will be used, to use another protocol provide the fully qualified git url."
	echo -e

	while read -p "Enter remote repository: " remote; do
		if [[ ! -z remote ]]; then
			break;
		fi
	done
	echo

	case "${remote}" in
		gh:*)
			remote="git@github.com:${remote#gh:}.git"
			;;
		bb:*)
			remote="git@bitbucket.org:${remote#bb:}.git"
			;;
	esac

	verbose_message "Creating git repository in $(highlight "${settings_directory}")"
	${dry_run} git init --quiet ./ || error "Creation of git repo failed" ${EXIT_CODE_GENERAL}
	verbose_message "Adding remote repository: $(highlight "${remote}")"
	${dry_run} git remote add origin "${remote}" || error "Error adding remote" ${EXIT_CODE_GENERAL}
	verbose_message "Fetching remote repository"
	${dry_run} git fetch origin --quiet || error "Error fetching remote" ${EXIT_CODE_GENERAL}
	verbose_message "Checking for commits on remote"
	${dry_run} git rev-list --quiet --max-parents=0 origin/master 2> /dev/null

	# if initial commit found
	if [[ "$?" -eq "0" ]]; then
		verbose_message "Commits found, resetting $(highlight "master") to $(highlight "origin/master")"
		${dry_run} git reset --quiet --hard origin/master || error "Error resetting master" ${EXIT_CODE_GENERAL}
	else
		verbose_message "No commits found on remote; adding initial empty commit"
		${dry_run} git commit -m "Initial commit" --allow-empty --quiet || error "Failed creating initial commit" ${EXIT_CODE_GENERAL}
		info_message "Initial commit created successfully"
		info_message "To push changed to remote, run $(highlight "${self} commit")"
	fi

	verbose_message "Disabling merge backup files"
	${dry_run} git config mergetool.keepBackup false

	verbose_message "Writing config information to disk"
	if ${is_dry_run}; then
		${dry_run} "echo 'settings_directory=\"${settings_directory}'\" > \"${ide_sync_config_file}\""
	else
		# use full path to directory
		settings_directory=$(pwd)
		echo "settings_directory='${settings_directory}'" > "${ide_sync_config_file}"
	fi
}

command_track() {
	local project_directory="${settings_directory}/${project_name}"

	# can't link with existing project with the same name
	if [[ -e "$project_directory" ]]; then
		error "Project with the name, ${project_name}, already exists" ${EXIT_CODE_INVALID_STATE}
	fi

	check_existing_symlink

	# .idea path has to exist, and be a directory
	if [[ ! -d ".idea" ]]; then
		error "No .idea directory found in current directory" ${EXIT_CODE_INVALID_STATE}
	fi

	backup_path=".idea-"$(date +%s)
	# technically this will fail if the backup directory already exists, but this is unlikely enough to check for
	verbose_message "Creating backup copy of $(highlight ".idea")"
	${dry_run} cp -r ".idea/" "${backup_path}" || error "Error creating backup of .idea" ${EXIT_CODE_GENERAL}
	warning "A backup was created as $(highlight "${backup_path}"), you may wish to delete this directory"
	verbose_message "Moving .idea to $(highlight "${settings_directory}")"
	${dry_run} mv ".idea/" "${project_directory}" || error "Error moving .idea directory" ${EXIT_CODE_GENERAL}
	verbose_message "Creating symlink to $(highlight "${project_directory}")"
	${dry_run} ln -s "${project_directory}" ".idea" || error "Error linking .idea directory" ${EXIT_CODE_GENERAL}
	verbose_message "Moving to $(highlight "${settings_directory}")"
	${dry_run} cd "${settings_directory}" || error "Error moving to ${settings_directory}" ${EXIT_CODE_GENERAL}
	verbose_message "Adding $(highlight "${project_name}") to git repository"
	${dry_run} git add --all -- "${project_name}" || error "Error adding files to git repository" ${EXIT_CODE_GENERAL}
	verbose_message "Committing changes to git repository"
	${dry_run} git commit --quiet -m "Added initial ${project_name} settings" || error "Error commit changes to git repository" ${EXIT_CODE_GENERAL}
}

command_link() {
	if [[ ! -d "$project_directory" ]]; then
		error "Project with the name, ${project_name}, does not exists" ${EXIT_CODE_INVALID_STATE}
	fi

	check_existing_symlink

	# .idea path has to exist, and be a directory
	if [[ -d ".idea" ]]; then
		warning "Existing $(highlight ".idea") directory found in current directory"

		read -p "Remove existing [y/n]? " -n 1 -r
		echo

		[[ ! $REPLY =~ ^[Yy]$ ]] && error "Cannot continue with existing $(highlight ".idea") directory" ${EXIT_CODE_ABORT}

		verbose_message "Deleting $(highlight ".idea") directory"
		${dry_run} rm -rf ".idea"
	fi

	verbose_message "Linking $(highlight "${project_directory}") to $(highlight ".idea")"
	${dry_run} ln -s "${project_directory}" ".idea"
}

command_commit() {
	local changes

	verbose_message "Changing to $(highlight "$settings_directory")"
	cd "$settings_directory"
	for dir in $(ls -1); do
		if [[ -d "$dir" ]]; then
			changes=$(git status --short -- "$dir")
			if [[ ! -z "$changes" ]]; then
				verbose_message "Adding $(highlight "$dir")"
				${dry_run} git add -A "$dir" || error "Error adding changes" ${EXIT_CODE_GENERAL}
				verbose_message "Committing"
				${dry_run} git commit --quiet -m "Updated ${dir} settings" || error "Error committing changes" ${EXIT_CODE_GENERAL}
			fi
		fi
	done
}

command_sync() {
	verbose_message "Changing to $(highlight "$settings_directory")"
	cd "$settings_directory"

	verbose_message "Fetching from remote"
	${dry_run} git fetch origin --quiet || error "Error fetching from remote" ${EXIT_CODE_GENERAL}

	verbose_message "Rebasing against origin master"
	${dry_run} git rebase --quiet origin/master || error "Error rebasing against remote branch" ${EXIT_CODE_GENERAL}

	# dry run does not apply inside this block
	while true; do
		verbose_message "Checking for conflicts"
		conflicts=$(git diff --name-only --diff-filter=U | wc -l)
		verbose_message "${conflicts} conflicts found"
		if [[ "$conflicts" -gt 0 ]]; then
			verbose_message "Conflicts found; running merge tool"
			git mergetool --no-prompt

			verbose_message "Rechecking for conflicts"
			conflicts=$(git diff --name-only --diff-filter=U | wc -l)
			if [[ "$conflicts" -gt 0 ]]; then
				warning "Conflicts still exist, rolling back"
				git rebase --abort
				error "Cannot continue with sync" ${EXIT_CODE_ABORT}
			fi

			changes=$(git diff --cached --name-only --diff-filter=U | wc -l)
			verbose_message "${changes} changes found"
			if [[ "$changes" -gt 0 ]]; then
				verbose_message "Continuing rebase"
				git add "$(git diff --name-only --diff-filter=U -z)" ||  error "Error adding unmerged paths" ${EXIT_CODE_GENERAL}
				git rebase --continue
			else
				verbose_message "Empty commit found, skipping"
				git rebase --skip
			fi
		else
			break
		fi
	done
	verbose_message "Rebasing complete"

	verbose_message "Pushing changes"
	${dry_run} git push origin master || error "Error pushing changes" ${EXIT_CODE_GENERAL}
}

command_list() {
	verbose_message "Changing to $(highlight "$settings_directory")"
	cd "$settings_directory"
	# find all directories in current, remove everything but the directory name, and remove empty lines
	list_items=$(find . -type d -maxdepth 1 -not -path '*/\.*' | cut -c 3- | sed '/^$/d')

	for item in ${list_items}; do
		changes=
		if [[ "$(git status --short "$item" | wc -l)" -gt "0" ]]; then
			changes=" $(highlight [modified])"
		fi
		message "${item} ${changes}"

	done
}

# check for required commands
if ! hash git 2>/dev/null; then
	error "git wasn't found; please install and ensure it's on the PATH" ${EXIT_CODE_INVALID_STATE}
fi

command="$1"
shift

# check for help without command
if [[ ${command} == "--help" ]]; then
	usage
	exit 0
fi

# parse arguments
while (($#)); do
	case "$1" in
		--config=*)
			ide_sync_config_file="${1#--config=}"
			shift
			;;
		--config)
			ide_sync_config_file="$2"
			shift
			;;
		-v|--verbose)
			verbose=true
			;;
		--dry-run)
			verbose=true
			is_dry_run=true;
			dry_run=dry_run_message;
			;;
		--help)
			usage
			exit 0
			;;
		--)
			# skip this
			;;
		--*)
			argument_error "$1"
			;;
		*)
			case ${command} in
				init)
					[[ ! -z ${settings_directory} ]] && argument_error "$1"
					settings_directory=${1}
					;;
				track)
					[[ ! -z ${project_name} ]] && argument_error "$1"
					project_name=${1}
					;;
				*)
					error "Unexpected argument: $(highlight "$1")" ${EXIT_CODE_INVALID_ARGUMENT} ${PRINT_USAGE}
					;;
			esac
			;;
	esac
	shift
done

if [[ ${command} != "init" ]]; then
	[[ -z "${ide_sync_config_file}" ]] && error "Invalid: Config file path cannot be empty" ${EXIT_CODE_INVALID_ARGUMENT}

	if [[ -e "${ide_sync_config_file}" ]]; then
		verbose_message "Loading config file: $(highlight "${ide_sync_config_file}")"
		source "${ide_sync_config_file}"
	else
		error "Config file not found: $(highlight "${ide_sync_config_file}")"
		error "Run \`${self} init\` to generate config file" ${EXIT_CODE_INVALID_STATE}
	fi

	if [[ -z "${settings_directory}" ]]; then
		error "The provided settings directory value is empty"
		error "Run \`${self} init\` to setup settings" ${EXIT_CODE_INVALID_STATE}
	fi

	if [[ ! -d "${settings_directory}" ]]; then
		error "The settings directory provided is not a valid directory" ${EXIT_CODE_INVALID_STATE}
	fi

	if [[ ${command} != "commit" ]] && [[ ${command} != "sync" ]] && [[ ${command} != "list" ]]; then
		if [[ -z "${project_name}" ]]; then
			error "Must provide project name" ${EXIT_CODE_INVALID_ARGUMENT} ${PRINT_USAGE}
		elif [[ ! "${project_name}" =~ $PROJECT_NAME_REGEX ]]; then
			error "Invalid project name, must contain only alphanumeric, _ and - characters and must begin with a letter" ${EXIT_CODE_INVALID_ARGUMENT}
		fi
	fi
fi

case ${command} in
	init)
		info_message ${C_STATUS}"init starting"${C_RESET}
		command_init
		info_message ${C_STATUS}"init finished"${C_RESET}
		;;
	track)
		info_message ${C_STATUS}"track starting"${C_RESET}
		command_track
		info_message ${C_STATUS}"track finished"${C_RESET}
		;;
	link)
		info_message ${C_STATUS}"link starting"${C_RESET}
		command_link
		info_message ${C_STATUS}"link finished"${C_RESET}
		;;
	commit)
		info_message ${C_STATUS}"commit starting"${C_RESET}
		command_commit
		info_message ${C_STATUS}"commit finished"${C_RESET}
		;;
	sync)
		info_message ${C_STATUS}"sync starting"${C_RESET}
		command_sync
		info_message ${C_STATUS}"sync finished"${C_RESET}
		;;
	list)
		command_list
		;;
	*)
		error "Unknown command: $(highlight "${command}")" ${EXIT_CODE_INVALID_COMMAND} ${PRINT_USAGE}
		;;
esac
