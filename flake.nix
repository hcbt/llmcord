{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    devenv.inputs.git-hooks.follows = "git-hooks";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, git-hooks, ... } @ inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
      pythonGitHooks = {
        check-merge-conflicts.enable = true;
        check-yaml.enable = true;
        end-of-file-fixer.enable = true;
        trim-trailing-whitespace.enable = true;
        ruff.enable = true;
        ruff-format.enable = true;
      };
    in
    {
      packages = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            pythonPackage = pkgs.python314Packages.buildPythonApplication {
              pname = "llmcord";
              version = "0.1.0";
              pyproject = true;
              src = ./.;

              nativeBuildInputs = with pkgs.python314Packages; [ hatchling ];
              nativeCheckInputs = with pkgs.python314Packages; [ pytestCheckHook ];
              propagatedBuildInputs = with pkgs.python314Packages; [
                discordpy
                httpx
                openai
                pyyaml
              ];

              pythonImportsCheck = [ "llmcord" ];
              pytestFlagsArray = [ "tests" ];
            };
          in
          {
            default = pythonPackage;
            llmcord = pythonPackage;
          });

      checks = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            package = self.packages.${system}.default;
            preCommitCheck = git-hooks.lib.${system}.run {
              src = ./.;
              package = pkgs.prek;
              hooks = pythonGitHooks;
            };
          in
          {
            default = package;
            llmcord = package;
            pre-commit-check = preCommitCheck;
          });

      apps = forEachSystem
        (system:
          let
            package = self.packages.${system}.default;
          in
          {
            default = {
              type = "app";
              program = "${package}/bin/llmcord";
            };
            llmcord = {
              type = "app";
              program = "${package}/bin/llmcord";
            };
          });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                ({ ... }: {
                  languages.python.enable = true;
                  languages.python.package = pkgs.python314;
                  languages.python.uv.enable = true;
                  languages.python.uv.sync.enable = true;

                  git-hooks.package = pkgs.prek;
                  git-hooks.hooks = pythonGitHooks;
                  git-hooks.install.enable = false;
                  tasks."devenv:git-hooks:install".status = "exit 0";

                })
              ];
            };
          });
    };
}
