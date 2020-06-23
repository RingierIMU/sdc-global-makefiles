# sdc-global-makeFiles

A collection of makefiles for all sdc repos. This is to allow make commands to be re-usable and be able to change on place.

## How to use

1. add a submodule in the makefiles dir. This will add this repo inside your project so the included makefiles can be used
2. Create a Makefile in the route of your repo
3. Ensure the Makefile includes the new `.mk` files like this `include makefiles/*.mk` or individual makefiles like `include makefiles/test.mk` etc. Make sure to always include base.mk
4. you can then use make commands like before `make test` 
