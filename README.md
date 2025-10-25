# Tillitis TKey Signer

Was created during a hackathon. Should be used with the app `tkey-password-generator-client`.

## Building

You have two options for build tools: either you use our OCI image
`ghcr.io/tillitis/tkey-builder` or native tools.

An easy way to build is to use the provided scripts:

- `build.sh` for native tools.
- `build-podman.sh` for use with Podman.

These scripts automatilly clone the [tkey-libs device
libraries](https://github.com/tillitis/tkey-libs) in a directory next
to this one.

If you want to use a pre-built libraries, download the libraries tar
ball from

<https://github.com/tillitis/tkey-libs/releases>

unpack it, and specify where you unpacked it in `LIBDIR` when
building:

```
make LIBDIR=~/Downloads/tkey-libs-v0.1.2
```

Note that your `lld` might complain if they were built with a
different version. If so, either use the same version the release used
or use podman.

### Building with Podman

On Ubuntu 22.10, running

```
apt install podman rootlesskit slirp4netns
```

should be enough to get you a working Podman setup.

You can then either:

- Use `build-podman.sh` as described above, which clones and builds
  the tkey-libs libraries as well.

- Download [pre-built versions of the tkey-libs
  libraries](https://github.com/tillitis/tkey-libs/releases) and
  define `LIBDIR` to where you unpacked the tkey-libs, something
  like:

  ```
  make LIBDIR=$HOME/Downloads/tkey-libs-v0.1.2 podman
  ```

  Note that `~` expansion doesn't work.

### Building with host tools

To build with native tools you need at least the `clang`, `llvm`,
`lld`, packages installed. Version 15 or later of LLVM/Clang is for
support of our architecture (RV32_Zmmul). Ubuntu 22.10 (Kinetic) is
known to have this. Please see
[toolchain_setup.md](https://github.com/tillitis/tillitis-key1/blob/main/doc/toolchain_setup.md)
(in the tillitis-key1 repository) for detailed information on the
currently supported build and development environment.

Build everything:

```
make
```

If you cloned `tkey-libs` to somewhere else then the default set
`LIBDIR` to the path of the directory.

If your available `objcopy` is anything other than the default
`llvm-objcopy`, then define `OBJCOPY` to whatever they're called on
your system.
