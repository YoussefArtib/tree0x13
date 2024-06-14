# Tree0x13:
Just a beautiful apple tree drawn using mode 0x13.

# Quick Start:
To start you need to install:
- [nasm](https://www.nasm.us/)
- [qemu](https://www.qemu.org/)

First build it:
```console
$ nasm tree.asm -o ./build/tree
```
then run it:
```console
$ qemu-system-i386 ./build/tree
```

# References:
- http://www.ctyme.com/intr/int.htm
