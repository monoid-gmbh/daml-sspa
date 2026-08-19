{
  description = "Nix packaging for the SSPA structured products DAML project (daml-finance based)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # -- DAML SDK release tarball ---------------------------------------
        damlSdkVersion = "2.10.0";

        os = if pkgs.stdenv.hostPlatform.isDarwin then "macos" else "linux";

        damlSdkHashes = {
          linux = "sha256-JYJ6pOsJf+m3ymForJO54dVTgLS0lyXoxOA6YOck0KY=";
          # Not independently verified for this project; update if/when building on macOS.
          macos = pkgs.lib.fakeHash;
        };

        damlSdkTarball = pkgs.fetchurl {
          url = "https://github.com/digital-asset/daml/releases/download/v${damlSdkVersion}/daml-sdk-${damlSdkVersion}-${os}.tar.gz";
          hash = damlSdkHashes.${os};
        };

        # DAML SDK 2.10.x's Canton runtime is tested against JDK 11.
        jdk = pkgs.jdk11_headless;

        damlSdk = pkgs.stdenv.mkDerivation {
          pname = "daml-sdk";
          version = damlSdkVersion;
          src = damlSdkTarball;
          dontUnpack = true;

          propagatedBuildInputs = [ jdk ];

          buildPhase = ''
            runHook preBuild

            mkdir extracted
            tar xzf $src -C extracted --strip-components 1
            patchShebangs extracted

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            cd extracted
            export DAML_HOME=$out
            ./daml/daml install \
              --install-assistant yes \
              --install-with-custom-version ${damlSdkVersion} \
              $src

            runHook postInstall
          '';

          preFixup = ''
            mkdir -p $out/nix-support
            echo "export DAML_HOME=$out" > $out/nix-support/setup-hook
          '';

          meta = {
            description = "Digital Asset DAML SDK (self-contained release tarball)";
            platforms = [
              "x86_64-linux"
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          };
        };

        # -- daml-finance prebuilt dar bundle -------------------------------
        damlFinanceVersion = "sdk/2.10.0";

        damlFinanceTarball = pkgs.fetchurl {
          url = "https://github.com/digital-asset/daml-finance/releases/download/${damlFinanceVersion}/daml-finance-bundle-sdk-2.10.0.tar.gz";
          hash = "sha256-8WwVajnNzuQDfvtS0NNvSRt8HIqR3OupC8GVtnFjeWQ=";
        };

        # Flat archive of *.dar / *.dar.asc files, no nesting.
        damlFinanceDars = pkgs.runCommand "daml-finance-dars-${damlSdkVersion}" { } ''
          mkdir -p $out
          tar xzf ${damlFinanceTarball} -C $out
        '';

        # -- data-dependencies closure needed by daml/Sspa -------------------
        # file -> PackageName/version, used to populate .lib/daml-finance/...
        # matching the relative paths referenced from daml.yaml.
        damlFinanceDeps = [
          {
            file = "contingent-claims-core-v3-3.0.0.dar";
            pkg = "ContingentClaims.Core.V3";
            ver = "3.0.0";
          }
          {
            file = "daml-finance-account-v4-4.0.0.dar";
            pkg = "Daml.Finance.Account.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-claims-v3-3.0.0.dar";
            pkg = "Daml.Finance.Claims.V3";
            ver = "3.0.0";
          }
          {
            file = "daml-finance-data-v4-4.0.0.dar";
            pkg = "Daml.Finance.Data.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-holding-v4-4.0.0.dar";
            pkg = "Daml.Finance.Holding.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-instrument-token-v4-4.0.0.dar";
            pkg = "Daml.Finance.Instrument.Token.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-account-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Account.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-claims-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Claims.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-data-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Data.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-holding-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Holding.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-instrument-base-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Instrument.Base.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-instrument-token-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Instrument.Token.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-instrument-types-v2-2.0.0.dar";
            pkg = "Daml.Finance.Interface.Instrument.Types.V2";
            ver = "2.0.0";
          }
          {
            file = "daml-finance-interface-lifecycle-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Lifecycle.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-settlement-v4-4.0.0.dar";
            pkg = "Daml.Finance.Interface.Settlement.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-interface-types-common-v3-3.0.0.dar";
            pkg = "Daml.Finance.Interface.Types.Common.V3";
            ver = "3.0.0";
          }
          {
            file = "daml-finance-interface-types-date-v3-3.0.0.dar";
            pkg = "Daml.Finance.Interface.Types.Date.V3";
            ver = "3.0.0";
          }
          {
            file = "daml-finance-interface-util-v3-3.0.0.dar";
            pkg = "Daml.Finance.Interface.Util.V3";
            ver = "3.0.0";
          }
          {
            file = "daml-finance-lifecycle-v4-4.0.0.dar";
            pkg = "Daml.Finance.Lifecycle.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-settlement-v4-4.0.0.dar";
            pkg = "Daml.Finance.Settlement.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-util-v4-4.0.0.dar";
            pkg = "Daml.Finance.Util.V4";
            ver = "4.0.0";
          }
          {
            file = "daml-finance-instrument-structuredproduct-v0-0.2.0.dar";
            pkg = "Daml.Finance.Instrument.StructuredProduct.V0";
            ver = "0.2.0";
          }
          {
            file = "daml-finance-interface-instrument-structuredproduct-v0-0.2.0.dar";
            pkg = "Daml.Finance.Interface.Instrument.StructuredProduct.V0";
            ver = "0.2.0";
          }
          {
            file = "daml-finance-interface-instrument-option-v0-0.4.0.dar";
            pkg = "Daml.Finance.Interface.Instrument.Option.V0";
            ver = "0.4.0";
          }
          {
            file = "daml-finance-instrument-option-v0-0.4.0.dar";
            pkg = "Daml.Finance.Instrument.Option.V0";
            ver = "0.4.0";
          }
        ];

        # Populates .lib/daml-finance/<Pkg>/<ver>/<file> from damlFinanceDars,
        # relative to the current working directory. Shared between the
        # interactive devShell (symlinks into the live working tree) and the
        # sandboxed `packages.dar` build (symlinks into the build's copy of
        # the source, which is writable).
        linkDarsScript = pkgs.lib.concatMapStrings (
          {
            file,
            pkg,
            ver,
          }:
          ''
            mkdir -p ".lib/daml-finance/${pkg}/${ver}"
            ln -sf "${damlFinanceDars}/${file}" ".lib/daml-finance/${pkg}/${ver}/${file}"
          ''
        ) damlFinanceDeps;

        # Minimal input closure: only daml.yaml + daml/ affect the compiled
        # DAR, so keep flake.nix/.gitignore/README/etc. out of the derivation
        # to avoid spurious rebuilds.
        projectSrc = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./daml.yaml
            ./daml
          ];
        };

        # Compiles the project to a .dar via `daml build`. DAML_HOME (set by
        # damlSdk's setup-hook) points at a read-only nix store path, but
        # that's fine: `daml build`'s writes (package-db cache, dependency
        # extraction under .daml/) all land under the project root, i.e. the
        # derivation's writable build directory, not under DAML_HOME. A
        # throwaway $HOME avoids the assistant looking for a real user
        # config/telemetry-consent file. No network access is needed or
        # attempted since the SDK and all data-dependency dars are already
        # local nix store inputs.
        sspaDar = pkgs.stdenv.mkDerivation {
          pname = "sspa-structured-products";
          version = "0.1.0"; # keep in sync with daml.yaml's `version:` field
          src = projectSrc;

          nativeBuildInputs = [ damlSdk ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            ${linkDarsScript}

            daml build

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp .daml/dist/*.dar $out/

            runHook postInstall
          '';

          meta = {
            description = "Compiled DAR for the SSPA structured products DAML project";
          };
        };
      in
      {
        packages = {
          inherit damlSdk damlFinanceDars;
          dar = sspaDar;
          default = sspaDar;
        };

        devShells.default = pkgs.mkShell {
          # Deliberately NOT including `sspaDar` here: buildInputs are realized eagerly when the
          # shell environment itself is built, so a hard dependency on the project's own DAR would
          # mean a DAML compile error blocks you from even entering the shell to fix it. Instead,
          # the shellHook below best-effort builds it as an ordinary (non-blocking) shell command.
          buildInputs = [
            damlSdk
            jdk
          ];

          shellHook = ''
            echo "Populating .lib/daml-finance dar symlinks..."
            ${linkDarsScript}

            echo "DAML_HOME=$DAML_HOME"
            echo "daml version:"
            daml version || true

            echo "Building project dar into dist/ (best effort)..."
            mkdir -p dist
            if darOut=$(nix --extra-experimental-features "nix-command flakes" build .#dar --no-link --print-out-paths 2>/tmp/sspa-dar-build.log); then
              for f in "$darOut"/*.dar; do
                ln -sf "$f" "dist/$(basename "$f")"
              done
              echo "compiled dar: dist/$(basename "$darOut"/*.dar)"
            else
              echo "dar build failed -- see /tmp/sspa-dar-build.log; fix daml/ sources, then run"
              echo "'daml build' directly or re-run 'nix build .#dar' to refresh dist/."
            fi
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
