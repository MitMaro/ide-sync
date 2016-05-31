# IDE Sync

A script that allows the sharing a tracking of project configurations for the various JetBrain's IDEs using a git
repository.

## Install

Clone the repository to a directory of your choice

    git clone https://github.com/MitMaro/ide-sync.git /path/to/install/directory

Create an alias to `ide-sync.sh` by adding the following to your shell profile

    alias ide-sync=/path/to/install/directory/ide-sync.sh

## Instructions

### Remote repository

First you will need to create a remote repository on GitHub, GitLab, Bitbucket, etc. This can also be a local bare
repository if you wish. It is recommended to use a private repository, or be careful to add to .gitignore to ignore
files that may contain sensitive information.

### Initial setup

The `init` command will initialize the repository at the directory provided.

    ide-sync init /path/to/repository/directory

You will be prompted for a remote repository. Following the instructions provided. A configuration file will be written
to your home directory with the settings you provide.

### Tracking Project Settings

From your project root (directory that contains `.idea`) run the `track` command providing a unique project name.

    ide-sync track name-of-project

The `.idea` directory will be copied to the directory provided in the `init` command, and then symlinked back to the
project root.

### Deleting Project Settings

Delete a tracked project using the `delete` command. The `list` command can be used to find the available projects to
delete.

    ide-sync delete name-of-project

You will be prompted to confirm the deletion.

### Syncing Changes to Remote

To push the changes to the remote repository use the `sync` command.

    ide-sync sync

The command will merge in changes from the remote, and you may be prompted to merge the changes. After the merge is
successful the local changes will be pushed to the remote repository. 

### Committing Project Settings

When you make changes to your project settings you will need to commit these changes. The `commit` command will handle
this.

    ide-sync commit

This will commit the changes to the project settings to the git repository.

### Linking Existing Settings

To link existing settings into a project use the `link` command providing the unique project name provided in the
`track` command.

    ide-sync link name-of-project

### Listing Project

To list the available projects use the `list` command.

    ide-sync list

## License

IDE Sync is released under the ISC license. See [LICENSE](LICENSE).
