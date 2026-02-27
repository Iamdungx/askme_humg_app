.PHONY: help get gen l10n setup run run-stg run-release run-ios run-ios-stg \
        build-apk build-aab build-ios icons splash clean fmt analyze check

help:
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

get:          ## flutter pub get
	flutter pub get

gen:          ## build_runner (Riverpod / Freezed / flutter_gen / go_router)
	dart run build_runner build --delete-conflicting-outputs

l10n:         ## flutter gen-l10n
	flutter gen-l10n

setup: get gen l10n ## sau khi clone

run:          ## Android debug
	flutter run -d android --debug --dart-define=APP_ENV=debug

run-stg:      ## Android stg
	flutter run -d android --debug --dart-define=APP_ENV=stg

run-release:  ## Android release
	flutter run -d android --release --dart-define=APP_ENV=release

run-ios:      ## iOS debug
	flutter run -d ios --debug --dart-define=APP_ENV=debug

run-ios-stg:  ## iOS stg
	flutter run -d ios --debug --dart-define=APP_ENV=stg

build-apk:    ## APK release
	flutter build apk --release --dart-define=APP_ENV=release

build-aab:    ## AAB release
	flutter build appbundle --release --dart-define=APP_ENV=release

build-ios:    ## IPA release (macOS)
	flutter build ipa --release --dart-define=APP_ENV=release

icons:        ## flutter_launcher_icons
	dart run flutter_launcher_icons

splash:       ## flutter_native_splash
	dart run flutter_native_splash:create

clean:        ## flutter clean
	flutter clean

fmt:          ## dart format
	dart format lib test

fix:          ## dart fix --apply
	dart fix --apply

analyze:      ## flutter analyze
	flutter analyze

check: fmt fix analyze ## fmt + fix + analyze
