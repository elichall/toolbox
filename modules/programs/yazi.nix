{ ... }: {
  flake.homeModules.yazi =
    {
      toolbox,
      pkgs,
      lib,
      ...
    }:
    {
      # ==========================================================================
      # YAZI FILE MANAGER CONFIGURATION
      # ==========================================================================
      programs.yazi = {
        enable = true;
        shellWrapperName = "y";
        enableBashIntegration = toolbox.isBash;
        enableZshIntegration = !toolbox.isBash;

        settings = {
          manager = {
            show_hidden = true;
            sort_by = "natural";
          };
        };

      };

      home.packages = [ pkgs.ripdrag ];

      xdg.configFile."yazi/init.lua" = {
        force = true;
        text = ''
          require("session"):setup {
            sync_yanked = true,
          }
        '';
      };

      xdg.configFile."yazi/keymap.toml" = {
        force = true;
        text = ''
          [[mgr.prepend_keymap]]
          on = "<C-d>"
          run = "shell 'ripdrag %s -A -x -i 2>/dev/null &' --confirm"
          desc = "Drag and drop"

          [[mgr.prepend_keymap]]
          on = "y"
          run = "yank"
          desc = "Yank the selected files"

          [[mgr.prepend_keymap]]
          on = "x"
          run = "yank --cut"
          desc = "Cut the selected files"

          [[mgr.prepend_keymap]]
          on = "p"
          run = "paste"
          desc = "Paste the yanked files"
        '';
      };
    };
}
