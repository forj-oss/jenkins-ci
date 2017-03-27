# Jenkins startup scripts

Before any jenkins app started, a collection of script can be executed to initialize anything on jenkins.

Those script are executed as jenkins user.

For those scripts to be executed, you must follow rules below:
- A script file have to be suffixed by a .sh extension.
- Any `*source.sh` will be executed through a bash source command. It gives you to set some Environment variables.
- Any other `*.sh` except `*source.sh` are executed as a sub bash process

RnD&IT Team
