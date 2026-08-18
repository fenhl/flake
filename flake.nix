{
    inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    outputs = attrs: {
        lib = {
            systems ? [
                "aarch64-darwin" # intercal
                "aarch64-linux" # reiwa, thermidor
                "x86_64-darwin" # bureflux
                "x86_64-linux" # bureflux, caturday, dushanbe, peterpc3, september
            ],
            config ? {},
            overlays ? [],
            devShells ? {
                default = { pkgs, ... }: {
                    packages = with pkgs; [
                        cargo
                    ];
                };
            },
            lib ? {},
            nixosConfigurations ? {},
            packages ? {},
        }: let
            merge = builtins.foldl' (a: b: a // b) {};
            eachSystem = f: merge (builtins.map (system: {
                ${system} = f system;
            }) systems);
            makePkgs = system: if config == {} && overlays == [] then attrs.nixpkgs.legacyPackages.${system} else import attrs.nixpkgs {
                inherit config overlays system;
            };
        in merge [
            (if devShells == {} then {} else {
                devShells = eachSystem (system: let
                    pkgs = makePkgs system;
                in builtins.mapAttrs (_: devShell: pkgs.mkShell (devShell {
                    inherit pkgs;
                })) devShells);
            })
            (if lib == {} then {} else { inherit lib; })
            (if nixosConfigurations == {} then {} else {
                nixosConfigurations = builtins.mapAttrs (_: config: if builtins.isFunction config then config {
                    inherit (attrs) nixpkgs;
                    inherit (attrs.nixpkgs) lib;
                } else config) nixosConfigurations;
            })
            (if packages == {} then {} else {
                packages = eachSystem (system: let
                    pkgs = makePkgs system;
                in builtins.mapAttrs (_: package: package {
                    inherit pkgs;
                    manifest = let
                        cargoToml = pkgs.lib.importTOML ./Cargo.toml;
                    in cargoToml.workspace.package or cargoToml.package;
                }) packages);
            })
        ];
    };
}
