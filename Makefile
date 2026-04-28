PREFIX    ?= ~/.bin
IDENTITY  ?= -
ENTITLEMENTS = darwinvm.entitlements
VERSION   := $(shell /bin/cat VERSION)

MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
PATCH := $(word 3,$(subst ., ,$(VERSION)))

.PHONY: all clean lint test build sign install uninstall release version version/major version/minor version/patch

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

version:
	@echo $(VERSION)

version/major:
	@echo "$(shell echo $$(($(MAJOR)+1))).0.0" > VERSION
	@echo "VERSION updated: $(VERSION) -> $$(cat VERSION)"

version/minor:
	@echo "$(MAJOR).$(shell echo $$(($(MINOR)+1))).0" > VERSION
	@echo "VERSION updated: $(VERSION) -> $$(cat VERSION)"

version/patch:
	@echo "$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH)+1)))" > VERSION
	@echo "VERSION updated: $(VERSION) -> $$(cat VERSION)"
