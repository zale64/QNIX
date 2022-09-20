#!/bin/bash
cd build/kernel
gdb -tui -q kernel.bin
