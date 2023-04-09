# SAPFOR (System FOR Automated Parallelization)

SAPFOR is a software development suite that is focused on cost reduction of manual program parallelization. It was primarily designed to perform a source-to-source transformation of a sequential program for execution on heterogeneous clusters.

SAPFOR repository is intended to collect other repositories of this project that makes it easier to download separate repositories and to organize them in the required directory tree.

The simplest way to get SAPFOR is the use of Docker and Microsoft Visual Studio Code tools. You can build SAPFOR with all components (static and dynamic analyzers, interactive subsystem, testing automation system with a basic set of tests) inside the container and apply it using Microsoft Visual Studio Code.

The following tools must be installed in advance:

1. [Docker Desktop](https://docker.com), installation instructions can be found [here](https://docs.docker.com/get-docker/),
2. [Microsoft Visual Stuido Code](https://code.visualstudio.com/) with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension, this extension is a part of the [C/C++ Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack).

To create a container you need:

1. Run the Visual Studio Code command  `Dev Containers: Clone Repository in Container Volume`. To do this, open the `Command Palette` in Visual Studio Code with the `Ctrl + Shift + P` keyboard shortcut, enter the command name, and press `Enter`.
2. In the window that appears, enter the path to the umbrella SAPFOR repository https://github.com/dvm-system/sapfor and press `Enter`. As a result, a container based on Ubuntu will be created and the necessary packages will be installed (downloading and installing the components may take some time).
3. Inside the container, run the `CMake: Build` command (using the `Command Palette` available by pressing `Ctrl + Shift + P`). As a result, SAPFOR will be built inside the container.
4. Inside the container, run the `CMake: Install` command. Now you can run the SAPFOR console application in the integrated terminal  (to open the terminal use the Ctr+\` keyboard shortcut). For example, type `tsar -help` to see all available options. To launch the SAPFOR interactive subsystem you can use the context menu which is available for C/C++ sources.

> __Note.__ If the build process may consume a great amount of RAM, you can reduce the number of simultaneously running tasks. Open the Visual Studio Code settings panel (use the `Preferences: Open Settings (UI)` command) and explicitly specify the value of the `Cmake: Parallel Jobs` property for the `CMake Tools configuration` extension.
> __Note.__ Usually it is better to leave Kit for SAPFOR unspecified and let CMake guess what compilers and environment to use. To change a Kit, run the `CMake: Select a Kit` command.

To manually download all parts of SAPFOR at once, use the command:

```bash
git clone --recurse-submodules https://github.com/dvm-system/sapfor.git
```

Visit the [SAPFOR Wiki](https://github.com/dvm-system/tsar/wiki) (in Russian) for more information.

## References

#### Static analysis

Kataev, N.: Application of the LLVM Compiler Infrastructure to the Program Analysis in SAPFOR. In: Voevodin V., Sobolev S. (eds) Supercomputing. RuSCDays 2018.
Communications in Computer and Information Science, vol. 965, pp. 487--499. Springer, Cham (2018) DOI: 10.1007/978-3-030-05807-4_41

#### Automated parallelization

Kataev, N.: LLVM Based Parallelization of C Programs for GPU. In: Voevodin V., Sobolev S. (eds) Supercomputing. RuSCDays 2020. Communications in Computer and Information Science, vol 1331. Springer, Cham. pp. 436--448 (2020) DOI: 10.1007/978-3-030-64616-5_38

#### Dynamic analysis

Kataev, N., Smirnov, A., Zhukov A.: Dynamic data-dependence analysis in SAPFOR.
In: CEUR Workshop Proceedings, vol. 2543, pp 199--208 (2020)

#### Interactive subsystem

Kataev, N.: Interactive Parallelization of C Programs in SAPFOR. In: Scientific Services & Internet 2020. CEUR Workshop Proceedings, vol. 2784, pp. 139--148 (2020)
