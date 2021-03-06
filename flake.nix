{
  description = "Holup: Give it a thought, will ya?";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    devshell-flake.url = "github:numtide/devshell";
    naersk.url = "github:nmattia/naersk";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils , devshell-flake, naersk, ... }:
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "i686-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ] (system:
      let
        version = "0.3.0";
        name = "holup";
        overlays = [ (import rust-overlay) devshell-flake.overlay ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustc-version = "latest";
        rust = pkgs.rust-bin.nightly.${rustc-version}.default;
        # Override the version used in naersk
        naersk-lib = naersk.lib."${system}".override {
          cargo = rust;
          rustc = rust;
        };
      in rec {

        # `nix build`
        packages."${name}" = naersk-lib.buildPackage {
          root = ./.;
          doCheck = true;
          cargoTestCommands = inputList: inputList ++ [ ''cargo $cargo_options clippy --all --all-features --profile test''];
        };
        defaultPackage = packages."${name}";

        # docker image
        packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
          inherit name;
          contents = [ packages."${name}" ];
          config.Entrypoint = [ "${name}" ];
        };

        # `nix run`
        apps."${name}" = flake-utils.lib.mkApp { drv = packages."${name}"; };
        defaultApp = apps."${name}";

        # `nix develop`
        devShell = with pkgs; let
          esc = "";

          orange = "${esc}[38;5;202m";
          reset = "${esc}[0m";
          bold = "${esc}[1m";
        in
          devshell.mkShell {
            imports = [
              (devshell.importTOML ./nix/commands.toml)
              (devshell.importTOML ./nix/env.toml)
            ];

            motd = ''
                  ${orange}$(${pkgs.figlet}/bin/figlet ${name})${reset}
                  $(type -p menu &>/dev/null && menu)
          '';

            packages = with pkgs; [
              # linking
              gcc
              # dev
              rust-analyzer  # rust lsp
              cargo-audit    # check for known vulnerabilities
              cargo-edit     # add, remove deps from the command line
              cargo-outdated # show outdated rust deps
              # build
              act # run github actions locally
              rust
            ];

            # commands = with pkgs; [
            # ];
          };

        checks = {

          rust-fmt = with import nixpkgs { inherit system overlays; };
            stdenv.mkDerivation {
              name = "${name}-cargo-fmt-check";
              inherit version;

              phases = [ "unpackPhase" "buildPhase" ];

              src = self;

              buildInputs = [ pkgs.rustfmt ];

              buildPhase = ''
                ${rust}/bin/cargo fmt -- --check | tee $out
              '';
            };

        };

      });
}
