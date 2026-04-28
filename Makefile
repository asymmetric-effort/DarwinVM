PREFIX ?= /usr/local
IDENTITY ?= -
ENTITLEMENTS = darwinvm.entitlements

.PHONY: build release sign install uninstall test clean

build:
	swift build

release:
	swift build -c release

sign: release
	codesign --force --sign $(IDENTITY) \
		--entitlements $(ENTITLEMENTS) \
		.build/release/darwinvm

install: sign
	install -d $(PREFIX)/bin
	install .build/release/darwinvm $(PREFIX)/bin/darwinvm

uninstall:
	rm -f $(PREFIX)/bin/darwinvm

test:
	swift test

clean:
	swift package clean
	rm -rf .build
