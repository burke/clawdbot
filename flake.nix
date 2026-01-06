{
  description = "Clawdbot - WhatsApp gateway CLI with Pi RPC agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        clawdbot = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "clawdbot";
          version = "2026.1.5-3";

          src = ./.;

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            hash = "sha256-sQP1WkJES5mqMYuWAETE1jffP0Crg8KPgz0+hfSKHd4=";
            fetcherVersion = 3;  # For pnpm-lock.yaml v6+
          };

          nativeBuildInputs = with pkgs; [
            nodejs_22
            pnpm
            pnpmConfigHook
            pkg-config
            python3  # For node-gyp
            makeWrapper
          ];

          buildInputs = with pkgs; [
            vips  # For sharp
          ];

          buildPhase = ''
            runHook preBuild
            pnpm build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/clawdbot $out/bin
            cp -r dist $out/lib/clawdbot/
            cp -r node_modules $out/lib/clawdbot/
            cp -r ui $out/lib/clawdbot/
            cp package.json $out/lib/clawdbot/

            makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/clawdbot \
              --add-flags "$out/lib/clawdbot/dist/entry.js"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "WhatsApp gateway CLI with Pi RPC agent";
            license = licenses.mit;
            mainProgram = "clawdbot";
          };
        });
      in
      {
        packages.default = clawdbot;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            corepack_22
            # Native deps for sharp
            vips
            pkg-config
          ];

          shellHook = ''
            export COREPACK_ENABLE_STRICT=0
            corepack enable
            corepack prepare pnpm@10.23.0 --activate
          '';
        };
      });
}
