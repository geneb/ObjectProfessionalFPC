# Object Professional for Free Pascal 3.2.2. Run `make` in src (needs GNU make).
# See also build.sh / build.cmd.
FPC ?= fpc
CPU ?= x86_64   # 64-bit by default; use CPU=i386 for 32-bit
export CPU
TARGET := $(CPU)-$(shell $(FPC) -iTO)
OUT ?= out/$(TARGET)

all:
	./build.sh $(OUT)

clean:
	rm -rf $(OUT)

.PHONY: all clean
