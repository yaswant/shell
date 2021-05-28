# `ysh`
A collection of useful general purpose shell scripts

## Getting Started

Most of the scripts are written in bash (4.1.2(1)-release and mainly on GNU/Linux),
but they should function as intended in other shell environments too.

### Prerequisites

GNU/Linux operating system with bash.

* BASH_VERSION 4.1.2+
* GNU coreutils 8.28+

Very few scripts have been adjusted to work on mac OS (POSIX.2), some still in progress.

```sh
# Get your OS  from a terminal
echo "$OSTYPE"
linux-gnu
```

### Installing
The following commands from a terminal should install the scripts in `$HOME/ysh` directory (specify path to install in a different place). The install script will also append install path to shell `PATH`.

```sh
git clone https://github.com/yaswant/ysh.git
cd ysh
sh ./install.sh PATH  # default PATH=$HOME/ysh
```

### Uninstalling
The following commands will remove the ysh install path from the system.  At the moment the PATH setting in user profile has to be removed manually.

```sh
sh uninstall.sh PATH  # default PATH=$HOME/ysh
```
<!-- ## Running the tests


### Break down into end to end tests


### And coding style tests


## Deployment


## Built With


## Contributing


## Versioning
-->

## Authors

* **Yaswant Pradhan** - *Initial work* - [yaswant](https://github.com/yaswant)

See also the list of [contributors](https://github.com/yaswant/ysh/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgements
