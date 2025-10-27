# Check for OS, if not macos assume linux
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	shasum = shasum -a 512
else
	shasum = sha512sum
endif

IMAGE=ghcr.io/tillitis/tkey-builder:5rc1

OBJCOPY ?= llvm-objcopy

P := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LIBDIR ?= $(P)/../tkey-libs

CC = clang

INCLUDE = $(LIBDIR)/include

# If you want libcommon's debug_puts() et cetera to output something
# on the QEMU debug port, use -DQEMU_DEBUG, or -DTKEY_DEBUG if you
# want it on the TKey HID debug endpoint
CFLAGS = -target riscv32-unknown-none-elf -march=rv32iczmmul -mabi=ilp32 -mcmodel=medany \
   -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf \
   -fno-builtin-putchar -nostdlib -mno-relax -flto -g \
   -Wall -Werror=implicit-function-declaration \
   -I $(INCLUDE) -I $(LIBDIR) #-DTKEY_DEBUG #-DQEMU_DEBUG

ifneq ($(TKEY_GENERATOR_APP_NO_TOUCH),)
CFLAGS := $(CFLAGS) -DTKEY_GENERATOR_APP_NO_TOUCH
endif

AS = clang
ASFLAGS = -target riscv32-unknown-none-elf -march=rv32iczmmul -mabi=ilp32 -mcmodel=medany -mno-relax

LDFLAGS=-T $(LIBDIR)/app.lds -L $(LIBDIR) -lcommon -lcrt0


.PHONY: all
all: generator/app.bin check-generator-hash

# Create compile_commands.json for clangd and LSP
.PHONY: clangd
clangd: compile_commands.json
compile_commands.json:
	$(MAKE) clean
	bear -- make generator/app.bin

# Turn elf into bin for device
%.bin: %.elf
	$(OBJCOPY) --input-target=elf32-littleriscv --output-target=binary $^ $@
	chmod a-x $@

show-%-hash: %/app.bin
	@echo "Device app digest:"
	@$(shasum) $$(dirname $^)/app.bin

check-generator-hash: generator/app.bin show-generator-hash
	@echo "Expected device app digest: "
	@cat generator/app.bin.sha512
	$(shasum) -c generator/app.bin.sha512

.PHONY: check
check:
	clang-tidy -header-filter=.* -checks=cert-* generator/*.[ch] -- $(CFLAGS)

# Simple password generator app
GENERATOROBJS=generator/main.o generator/app_proto.o
generator/app.elf: $(GENERATOROBJS)
	$(CC) $(CFLAGS) $(GENERATOROBJS) $(LDFLAGS) -L $(LIBDIR)/monocypher -lmonocypher -I $(LIBDIR) -o $@
$(GENERATOROBJS): $(INCLUDE)/tkey/tk1_mem.h generator/app_proto.h

.PHONY: clean
clean:
	rm -f generator/app.bin generator/app.elf $(GENERATOROBJS)

# Uses ../.clang-format
FMTFILES=generator/*.[ch]

.PHONY: fmt
fmt:
	clang-format --dry-run --ferror-limit=0 $(FMTFILES)
	clang-format --verbose -i $(FMTFILES)
.PHONY: checkfmt
checkfmt:
	clang-format --dry-run --ferror-limit=0 --Werror $(FMTFILES)

.PHONY: podman
podman:
	podman run --arch=amd64 --rm --mount type=bind,source=$(CURDIR),target=/src --mount type=bind,source=$(LIBDIR),target=/tkey-libs -w /src -it $(IMAGE) make -j
