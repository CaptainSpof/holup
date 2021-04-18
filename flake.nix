{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };

  outputs = { self, nixpkgs, utils, naersk }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
      naersk-lib = naersk.lib."${system}";
    in rec {
      # `nix build`
      packages.holup = naersk-lib.buildPackage {
        pname = "holup";
        root = ./.;
      };
      defaultPackage = packages.holup;

      # `nix run`
      apps.holup = utils.lib.mkApp {
        drv = packages.holup;
      };
      defaultApp = apps.holup;

      # `nix develop`
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ rustc cargo ];
      };
    });
}
