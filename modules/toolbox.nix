{ inputs, ... }: {
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
    };
    macos = {
      hostType = "macos";
      enableBlesh = false;
      isBash = false;
      displayProvider = "macos";
      clipboard = {
        pasteText = "pbpaste";
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
    };
  };
}
