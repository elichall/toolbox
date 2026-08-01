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
        (lib.mkIf (toolbox.displayProvider == "wsl") [
          pkgs.wl-clipboard
          pkgs.xclip
        ])
        (lib.mkIf (toolbox.isBash == true) [ pkgs.bash-language-server ])

        # Global LSP servers (always on PATH)
        [
          pkgs.nil # nix
          pkgs.marksman # markdown
          pkgs.lua-language-server # lua
          pkgs.texlab # latex
        ]

        # nvim dependancy
        [
          pkgs.tree-sitter
          pkgs.gcc
        ]

        # Fonts
        [
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.noto-fonts
        ]
      ];

      fonts.fontconfig.enable = true;
      home.enableNixpkgsReleaseCheck = false;
    };
}
