{ ... }: {
  flake.homeModules.cmdLine =
    {
      pkgs,
      toolbox,
      lib,
      ...
    }:
    let
      osSymbols = {
        nixos = "❄️ ";
        ubuntu = " ";
        arch = " ";
        macos = " ";
      };
      osNames = {
        nixos = "NixOS";
        ubuntu = "Ubuntu";
        arch = "Arch";
        macos = "Macos";
      };
    in
    {
      # Enable bash or zsh
      programs.bash.enable = toolbox.isBash;
      programs.zsh.enable = !toolbox.isBash;

      programs.starship = {
        enable = true;
        enableBashIntegration = toolbox.isBash;
        enableZshIntegration = !toolbox.isBash;

        settings = {
          format = "$os$directory$nix_shell$git_branch$git_status$character";
          add_newline = false;
          line_break.disabled = true;
          cmd_duration.disabled = true;

          os = {
            disabled = false;
            format = "[$symbol]($style) ";
            style = "bold #74c7ec";
            symbols = {
              ${osNames.${toolbox.hostType}} = osSymbols.${toolbox.hostType};
            };
          };

          nix_shell = {
            symbol = "❄️";
            format = "via [$symbol$state](bold blue) ";
            pure_msg = "pure";
            impure_msg = "";
            unknown_msg = "";
            heuristic = false;
            disabled = false;
          };
        };
      };
    };
}
