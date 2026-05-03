# CornucopiaSymbols — convenience targets.
#
# Quick iteration on the menu bar app:
#   make run        # rebuild executable, swap it into the .app, relaunch
#
# Full app bundle (slow — runs actool on all 7 catalogs, ~5 min):
#   make app
#
# Regenerate Swift enums + asset catalogs from Vendor/open-symbols:
#   make symbols
#
# Sync upstream then regenerate:
#   make sync

APP        := SymbolBrowser.app
EXE        := SymbolBrowser
CONFIG     ?= debug
BUILD_DIR  := .build/$(CONFIG)

.PHONY: run build relaunch kill app clean symbols sync test help

help:
	@echo "Targets:"
	@echo "  run        Rebuild executable and relaunch $(APP) (fast iteration)"
	@echo "  app        Build a fresh $(APP) from scratch (slow: invokes actool)"
	@echo "  build      swift build the executable only"
	@echo "  kill       Kill any running $(EXE)"
	@echo "  test       Run the package test suite"
	@echo "  symbols    Regenerate Swift enums + .xcassets from Vendor/open-symbols"
	@echo "  sync       Re-clone upstream into Vendor/, then regenerate"
	@echo "  clean      Remove .build and $(APP)"

run: build kill
	@if [ ! -d "$(APP)" ]; then \
	    echo "$(APP) not found — running full build (this is slow on first run)..."; \
	    $(MAKE) app; \
	else \
	    cp "$(BUILD_DIR)/$(EXE)" "$(APP)/Contents/MacOS/$(EXE)"; \
	    echo "Swapped in fresh executable."; \
	fi
	open "$(APP)"
	@sleep 1
	@pgrep -lf '$(APP)/Contents/MacOS/$(EXE)' || echo "(launch failed)"

build:
	swift build -c $(CONFIG) --product $(EXE)

kill:
	-killall -9 $(EXE) 2>/dev/null || true

app:
	bash Scripts/build-app.sh $(CONFIG)

test:
	swift test

symbols:
	python3 Scripts/generate.py

sync:
	bash Scripts/sync-symbols.sh
	python3 Scripts/generate.py

clean:
	rm -rf .build $(APP)
