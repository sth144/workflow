# Workflow
A set of dotfiles and utilities used to configure desktop environments and automate workflows on Linux machines running i3wm with X window systems.

## To Install Configs
* clone repository
* `cd /path/to/directory/.workflow`
* `$ make build` to merge local and shared configs into stage directory
    * examine the files in stage/. This set of files will be copied into ~/
        * note: if files exist in ~/ (or subdirectories like ~/.config/...), whose filenames
            match those in stage, and whose paths (relative to ~) match those in stage (relative
            to stage), they will be completely overwritten. No other files will be affected. Be
            sure to examine the files in stage before installing
* `$ make install` to copy configs from stage to home directory

## Structure
* Makefile
* admin/
    * installation scripts called by Makefile
* lib/
    * inactive config files for reference, notes
* src/
    * configs/
        * local/
            * configurations specific to local machine, not tracked by Git.
            * if a file exists in both local/ and shared/, the local file will
                be concatenated to the shared file during build process
        * shared/
            * configurations which can be used by any Linux machine with required
                dependencies installed.
            * note: some configs are incomplete, and will require a partial config
                with the same filename under local/ to work properly when installed
    * utils/
        * local/
            * utility scripts specific to local machine, not tracked by Git
        * shared/
            * utility scripts which can be used on any Linux machine
* stage/
    * staging for compiled config files, after build, install script copies from this directory to ~/
* cache/
    * temp files used by utils scripts
* log/
    * logs generated by utils scripts for testing/debugging

## Dependencies
* i3-gaps    (window manager)
    * NOTE: as of 29 Feb, 2020, this line requires using this fork of i3-gaps:
    * https://github.com/resloved/i3.git
* i3-blocks  (utility bar)
* compton    (X Window compositor)
* ranger     (terminal file manager)
* termite    (terminal emulator)
* rofi 	     (application launcher, window switcher)
* Python 3.x
* Node.js
* npm
* barrier    (keyboard/mouse share)

## TODO
* integrate crontab
* refactor to install utils so that scripts don't rely on .workflow/src code
* refactor to use ~/.cache/ instead of .workflow/cache
* make sure .bashrc works on multiple distros
* organize scratchpad bindings and brainstorm others
