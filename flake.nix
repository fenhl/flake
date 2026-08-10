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
                    pkgs = attrs.nixpkgs.legacyPackages.${system};
                in builtins.mapAttrs (_: devShell: pkgs.mkShell (devShell {
                    inherit pkgs;
                })) devShells);
            })
        ];
    };
}
