{ inputs, self, ... }:
let
  toolbox = self.toolbox.macos;
in {
  flake.homeConfigurations."elichall@macos" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    extraSpecialArgs = { inherit inputs toolbox; };
    modules = [
      {
        home.stateVersion = "25.05";
        home.homeDirectory = "/Users/elichall";
        home.username = "elichall";
      }
      self.homeModules.basics
      self.homeModules.tmux
      self.homeModules.yazi
      self.homeModules.cmdLine
      self.homeModules.nvim
      self.homeModules.theme
    ];
  };
}
