{
  inputs,
  ...
}:
let
  themeSchemes = [
    "rose-pine"
    "catppuccin-mocha"
    "catppuccin-latte"
    "tokyo-night-dark"
    "chalk"
    "dracula"
    "ayu-dark"
    "gruvbox-dark"
    "everforest"
    "nord"
  ];
in
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  flake.toolbox = {
    linux = {
      hostType = "nixos";
      enableBlesh = true;
      isBash = true;
      displayProvider = "wayland";
      clipboard = {
        pasteText = "wl-paste";
      };
      theme = {
        schemes = themeSchemes;
        default = "rose-pine";
      };
    };
    macos = {
      hostType = "macos";
      enableBlesh = false;
      isBash = false;
      displayProvider = "macos";
      clipboard = {
        pasteText = "pbpaste";
      };
      theme = {
        schemes = themeSchemes;
        default = "rose-pine";
      };
    };
    wsl = {
      hostType = "ubuntu";
      enableBlesh = true;
      isBash = true;
      displayProvider = "wsl";
      clipboard = {
        pasteText = "win32yank -o";
      };
      theme = {
        schemes = themeSchemes;
        default = "rose-pine";
      };
    };
  };
}
