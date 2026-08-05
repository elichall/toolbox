{ inputs, self, ... }:
let
  toolbox = self.toolbox.wsl;
  user = let u = builtins.getEnv "TOOLBOX_USER"; in if u == "" then "elichall" else u;
in {
  flake.homeConfigurations."${user}@wsl" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs toolbox; };
    modules = [
      {
        home.stateVersion = "25.05";
        home.homeDirectory = "/home/${user}";
        home.username = user;
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
