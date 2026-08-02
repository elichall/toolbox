{ inputs, self, ... }:
let
  toolbox = self.toolbox.linux;
in {
  flake.homeConfigurations."elichall@linux" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs toolbox; };
    modules = [
      {
        home.stateVersion = "25.05";
        home.homeDirectory = "/home/elichall";
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
