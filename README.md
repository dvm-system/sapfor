# SAPFOR (System FOR Automated Parallelization)

SAPFOR is a software development suite that is focused on cost reduction of manual program parallelization. It was primarily designed to perform a source-to-source transformation of a sequential program for execution on heterogeneous clusters.

SAPFOR repository is intended to collect other repositories of this project that makes it easier to download separate repositories and to organize them in the required directory tree.

The simplest way to get SAPFOR is the use of Docker and Microsoft Visual Studio Code tools. You can build SAPFOR with all components (static and dynamic analyzers, interactive subsystem, testing automation system with a basic set of tests) inside the container and apply it using Microsoft Visual Studio Code.

The following tools must be installed in advance:

1. [Docker Desktop](https://docker.com), installation instructions can be found [here](https://docs.docker.com/get-docker/),
2. [Microsoft Visual Stuido Code](https://code.visualstudio.com/) with the [Remote Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension, this extension is a part of the [C/C++ Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack).

To create a container you need:

1. Run the Visual Studio Code command  `Remote-Containers: Clone Repository in Container Volume`. To do this, open the `Command Palette` in Visual Studio Code with the `Ctrl + Shift + P` keyboard shortcut, enter the command name, and press `Enter`.
2. In the window that appears, enter the path to the umbrella SAPFOR repository https://github.com/dvm-system/sapfor and press `Enter`. As a result, a container based on Ubuntu will be created and the necessary packages will be installed (downloading and installing the components may take some time).
3. Inside the container, run the `CMake: Build` command (using the `Command Palette` available by pressing `Ctrl + Shift + P`). As a result, SAPFOR will be built inside the container.
4. Inside the container, run the `CMake: Install` command. Now you can run the SAPFOR console application in the integrated terminal  (to open the terminal use the Ctr+\` keyboard shortcut). For example, type `tsar -help` to see all available options. To launch the SAPFOR interactive subsystem you can use the context menu which is available for C/C++ sources.

> __Note.__ If the build process may consume a great amount of RAM, you can reduce the number of simultaneously running tasks. Open the Visual Studio Code settings panel (use the `Preferences: Open Settings (UI)` command) and explicitly specify the value of the `Cmake: Parallel Jobs` property for the `CMake Tools configuration` extension.

To manually download all parts of SAPFOR at once, use the command:

```bash
git clone --recurse-submodules https://github.com/dvm-system/sapfor.git
```

Visit the [SAPFOR Wiki](https://github.com/dvm-system/tsar/wiki) (in Russian) for more information.
