PREFIX    ?= ~/.bin
IDENTITY  ?= -
ENTITLEMENTS = darwinvm.entitlements
VERSION   := $(shell /bin/cat VERSION)

.PHONY: all clean lint test build sign install uninstall release

all: clean lint test build

clean:
	swift package clean
	rm -rf .build

lint:
	DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/usr/lib swiftlint lint --strict

test:
	swift test

build:
	swift build -c release

sign: build
	codesign --force --sign $(IDENTITY) \
		--entitlements $(ENTITLEMENTS) \
		.build/release/darwinvm

install: sign
	install -d $(PREFIX)
	install .build/release/darwinvm $(PREFIX)/darwinvm

uninstall:
	rm -f $(PREFIX)/darwinvm

release:
	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
		echo "Error: tag v$(VERSION) already exists"; exit 1; \
	fi
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	git push origin "v$(VERSION)"
