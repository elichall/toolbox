{ self, ... }: {
  flake.homeModules.nvim = { pkgs, ... }: {
    home.packages = [ pkgs.neovim ];
    xdg.configFile."nvim".source = "${self}/nvim";
  };
}
