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
            overlays ? [],
            devShells ? {
                default = { pkgs, ... }: {
                    packages = with pkgs; [
                        cargo
                    ];
                };
            },
        }: let
            merge = builtins.foldl' (a: b: a // b) {};
            eachSystem = f: merge (builtins.map (system: {
                ${system} = f system;
            }) systems);
        in merge [
            (if devShells == {} then {} else {
                devShells = eachSystem (system: let
                    pkgs = if overlays == [] then attrs.nixpkgs.legacyPackages.${system} else import attrs.nixpkgs {
                        inherit overlays system;
                    };
                in builtins.mapAttrs (_: devShell: pkgs.mkShell (devShell {
                    inherit pkgs;
                })) devShells);
            })
        ];
    };
}
