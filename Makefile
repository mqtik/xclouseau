export PATH := /opt/homebrew/bin:$(PATH)

.PHONY: dev build release run test clean get gen fake-device analyze

dev:
	@cd app && exec fvm flutter run -d macos

build:
	cd app && fvm flutter build macos --debug

release:
	cd app && fvm flutter build macos --release

test:
	cd app && fvm flutter test

clean:
	cd app && fvm flutter clean

get:
	cd app && fvm flutter pub get

gen:
	cd app && fvm dart run build_runner build --delete-conflicting-outputs

fake-device:
	fvm dart run tools/fake_device.dart

analyze:
	cd app && fvm flutter analyze
