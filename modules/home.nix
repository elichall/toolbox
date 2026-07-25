{ ... }: {
  flake.homeModules.basics =
    {
      toolbox,
      pkgs,
      lib,
      ...
    }:
    {
      # ==========================================================================
      # GLOBAL ENVIRONMENT CONFIGURATION
      # ==========================================================================
      home.sessionVariables = {
        EDITOR = "nvim";
        FILEMANAGER = "yazi";
        TERM_FILE_CHOOSER = "yazi";
        VISUAL = "nvim";
        SUDO_EDITOR = "nvim";
      };

      programs.git = {
        enable = true;
        settings.user.name = "elichall";
        settings.user.email = "1elijah.hall@gmail.com";
      };

      # ==========================================================================
      # PACKAGES
      # ==========================================================================
      home.packages = lib.mkMerge [
        # conditional packages
        (lib.mkIf (toolbox.displayProvider == "wayland") [ pkgs.wl-clipboard ])
        (lib.mkIf (toolbox.displayProvider == "x11") [ pkgs.xclip ])
        (lib.mkIf (toolbox.isBash == true) [ pkgs.bash-language-server ])

        # Global LSP servers (always on PATH)
        [
          pkgs.nil # nix
          pkgs.marksman # markdown
          pkgs.lua-language-server # lua
          pkgs.texlab # latex
        ]

        # nvim dependancy
        [ pkgs.tree-sitter pkgs.gcc ]

        # Fonts
        [
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.noto-fonts
        ]
      ];

      fonts.fontconfig.enable = true;
      home.enableNixpkgsReleaseCheck = false;

      # ==========================================================================
      # PROGRAMS
      # ==========================================================================
      programs.zoxide = {
        enable = true;
        enableBashIntegration = toolbox.isBash;
        enableZshIntegration = !toolbox.isBash;
      };

      programs.fzf = {
        enable = true;
        enableBashIntegration = toolbox.isBash;
        enableZshIntegration = !toolbox.isBash;
        enableNushellIntegration = false;
      };

      programs.direnv = {
        enable = true;
        enableBashIntegration = toolbox.isBash;
        enableZshIntegration = !toolbox.isBash;
        nix-direnv.enable = true;
        silent = true;
        stdlib = ''
          # Load nix-direnv stdlib (provides use_nix, use flake)
          source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
          # Load user lib/*.sh (direnv does not auto-load these)
          direnv_config_dir_home="''${DIRENV_CONFIG_HOME:-''${XDG_CONFIG_HOME:-$HOME/.config}/direnv}"
          for lib in "$direnv_config_dir_home/lib/"*.sh; do
            source "$lib"
          done
          unset direnv_config_dir_home
        '';
      };

    };
}
