# SLSF Random Generation

## Introduction

 - TODO

## Current Work

 - In a loop, we can generate random C code using csmith, then use a hard-
coded S-function to call the `main` function generated by csmith.

 - We compile the code and may run it (hazards - unsafe math operation
crashes and there's also infinitely running code.

 - Unsafe math operation at runtime: For some reason, I can not build with
`mex` command. I've put a log in the logs folder. To get around this, I
commented out line 100 of `csmith/runtime/random_inc.h`. So, run-time
unsafe math operation (i.e. division by 0) leads to crash.

## TODO

 - Refactor to run the loop outside Matlab
 - Fix safe_math.h compilation problem
 - Try out different compilers and optimization flags to eventually check 
"Wrong Code" (as mentioned at csmith - when run time output of same source 
file is different changing compilers and optimization levels duet to 
compiler bug.
 - Figure out how to calculate "checksum" (this is how csmith checks "wrong
code" for our case. 

## How to run

 - Call testrun module from Matlab

### Building and installing csmith

 - Follow official doc at https://embed.cs.utah.edu/csmith/.
 - We have to ensure csmith executable and include directory is in path.

### Set up environment variables

In linux, we can set up this way:

export PATH=$PATH:/path-to-csmith/src
export CSMITH_PATH=/path-to-csmith
export C_INCLUDE_PATH=/path-to-csmith/runtime

