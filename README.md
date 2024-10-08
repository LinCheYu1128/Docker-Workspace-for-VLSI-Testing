# Docker Workspace for NYCU VLSI Testing
- Modify by ACAL/Playlab Curriculum
- A dockerized [Ubuntu 20.04](https://hub.docker.com/_/ubuntu/) workspace with all required tools installed for students to enjoy the journey of the ACAL/Playlab curriculum.
## Envrionment Requirements
   1. A Linux or Unix-equivelent system (including cygwin).
   2. GCC 3.X.
   3. make 3.8+.
   3. flex 1.875+.
   3. bison 2.5.4+.
   3. readline 5.0.4+ and ncurses 5.4.2+ library.
## User Guides
- If you are working on Windows systems, use the following commands in Bash-like shells such as [Git Bash](https://git-scm.com/download/win).
- Use `run` to manage the Docker image and container of this workspace.
    ```
    $ ./run

        This script will help you manage the Docker Workspace for VLSI Testing Workspace.
        You can execute this script with the following options.

        start     : build and enter the workspace
        stop      : terminate the workspace
        prune     : remove the docker image
        rebuild   : remove and build a new image to apply new changes
    ```
- `./run start`
    - First execution: Build the Docker image, create a container, and enter the terminal.
    - Image exists but no running container: Create a container and enter the terminal.
    - Container is running: Enter the terminal.
- Users can put all permanent files in `~/projects` of the workspace, which is mounted to `docker-base-workspace/projects` on the host machine.
- The container won't be stopped after type `exit` in the last terminal of the workspace. Users should also use `./run stop` command on the host machine to stop and remove the container.
