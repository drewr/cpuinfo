{
  description = "Print host CPU information";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "cpuinfo";
            version = "0.0.0";
            src = ./.;
            nativeBuildInputs = [ pkgs.zig ];
            buildPhase = ''
              zig build -Doptimize=ReleaseSafe \
                --cache-dir $TMPDIR/zig-cache \
                --global-cache-dir $TMPDIR/zig-global-cache
            '';
            installPhase = ''
              install -Dm755 zig-out/bin/cpuinfo $out/bin/cpuinfo
            '';
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/cpuinfo";
        };
      });
    };
}
