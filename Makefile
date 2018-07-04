TEMPORARY_FOLDER?=/tmp/GitCommit.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

XCODEFLAGS=-project 'GitCommit.xcodeproj' \
	-scheme 'GitCommit-Package' \
	DSTROOT=$(TEMPORARY_FOLDER) \
	OTHER_LDFLAGS=-Wl,-headerpad_max_install_names

SWIFT_BUILD_FLAGS=--configuration release
UNAME=$(shell uname)
ifeq ($(UNAME), Darwin)
SWIFT_BUILD_FLAGS+= -Xswiftc -static-stdlib
endif

GIT_COMMIT_EXECUTABLE=$(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/git-commit

TSAN_LIB=$(subst bin/swift,lib/swift/clang/lib/darwin/libclang_rt.tsan_osx_dynamic.dylib,$(shell xcrun --find swift))
TSAN_SWIFT_BUILD_FLAGS=-Xswiftc -sanitize=thread
TSAN_TEST_BUNDLE=$(shell swift build $(TSAN_SWIFT_BUILD_FLAGS) --show-bin-path)/GitCommittPackageTests.xctest
TSAN_XCTEST=$(shell xcrun --find xctest)

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin
PRODUCTS_FOLDER=Products
LICENSE_PATH="$(shell pwd)/LICENSE"
COMMIT_MSG_HOOK_PATH=Scripts/hooks/bin/commit-msg

OUTPUT_PACKAGE=$(PRODUCTS_FOLDER)/GitCommit.pkg

GIT_COMMIT_PLIST=GitCommit.xcodeproj/git-commit_info.plist
GITCOMMITFRAMEWORK_PLIST=GitCommit.xcodeproj/GitCommitFramework_Info.plist

VERSION_STRING=$(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(GIT_COMMIT_PLIST)")

.PHONY: all bootstrap clean build install package test uninstall

all: build

bootstrap: install
	@# install "$(GIT_COMMIT_EXECUTABLE)" "$(PRODUCTS_FOLDER)/bin/"
	@# if which ./.git/hooks/ >/dev/null; then; else; mkdir ./.git/hooks/; fi
	install "$(COMMIT_MSG_HOOK_PATH)" "./.git/hooks/"

test: clean_xcode bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

test_tsan:
	swift build --build-tests $(TSAN_SWIFT_BUILD_FLAGS)
	DYLD_INSERT_LIBRARIES=$(TSAN_LIB) $(TSAN_XCTEST) $(TSAN_TEST_BUNDLE)

clean:
	rm -f "$(PRODUCTS_FOLDER)/bin/git-commit"
	rm -f "$(PRODUCTS_FOLDER)/GitCommit.pkg"
	rm -f "$(PRODUCTS_FOLDER)/git-commit.zip"
	swift package clean

clean_xcode: clean
	$(BUILD_TOOL) $(XCODEFLAGS) -configuration Test clean

build:
	swift build $(SWIFT_BUILD_FLAGS)

build_with_disable_sandbox:
	swift build --disable-sandbox $(SWIFT_BUILD_FLAGS)

install: clean build
	install -d "$(BINARIES_FOLDER)"
	install "$(GIT_COMMIT_EXECUTABLE)" "$(BINARIES_FOLDER)"
	install "$(GIT_COMMIT_EXECUTABLE)" "$(PRODUCTS_FOLDER)/bin/"

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/GitCommitFramework.framework"
	rm -f "$(BINARIES_FOLDER)/git-commit"
	rm -f "$(PRODUCTS_FOLDER)/bin/git-commit"

installables: clean build
	install -d "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	install "$(GIT_COMMIT_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"

prefix_install: clean build_with_disable_sandbox
	install -d "$(PREFIX)/bin/"
	install "$(GIT_COMMIT_EXECUTABLE)" "$(PREFIX)/bin/"

portable_zip: installables
	cp -f $(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/git-commit $(TEMPORARY_FOLDER)
	cp -f $(LICENSE_PATH) $(TEMPORARY_FOLDER)
	(cd "$(TEMPORARY_FOLDER)"; zip -yr - "git-commit" "LICENSE") > "$(PRODUCTS_FOLDER)/git-commit.zip"

package: installables
	pkgbuild \
		--identifier "com.devedbox.git-commit" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"

archive:
	carthage build --no-skip-current --platform mac
	carthage archive GitCommitFramework

release: package archive portable_zip

docker_test:
	@# docker run -v `pwd`:`pwd` -w `pwd` --name git-commit --rm norionomura/swift:40 swift test --parallel

docker_htop:
	@# docker run -it --rm --pid=container:git-commit terencewestphal/htop || reset

# http://irace.me/swift-profiling/
display_compilation_time:
	$(BUILD_TOOL) $(XCODEFLAGS) OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies" clean build-for-testing | grep -E ^[1-9]{1}[0-9]*.[0-9]+ms | sort -n

publish:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) git-commit
	# pod trunk push GitCommitFramework.podspec --swift-version=4.0
	# pod trunk push GitCommit.podspec --swift-version=4.0

get_version:
	@echo $(VERSION_STRING)

push_version:
	$(eval NEW_VERSION_AND_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval NEW_VERSION := $(shell echo $(NEW_VERSION_AND_NAME) | sed 's/:.*//' ))
	@sed -i '' 's/## Master/## $(NEW_VERSION_AND_NAME)/g' CHANGELOG.md
	# @sed 's/__VERSION__/$(NEW_VERSION)/g' script/Version.swift.template > Source/GitCommitFramework/Models/Version.swift
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(NEW_VERSION)" "$(GITCOMMITFRAMEWORK_PLIST)"
	@/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(NEW_VERSION)" "$(GIT_COMMIT_PLIST)"
	git commit -a -m "release: $(NEW_VERSION)"
	git tag -a $(NEW_VERSION) -m "$(NEW_VERSION_AND_NAME)"
	git push origin master
	git push origin $(NEW_VERSION)

%:
	@:
