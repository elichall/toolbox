{ ... }: {
  flake.homeModules.yazi =
    {
      inputs,
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

      xdg.configFile."yazi/plugins/clipboard.yazi".source = inputs.clipboard-yazi;

      xdg.configFile."yazi/keymap.toml" = {
        force = true;
        text = ''
          [[mgr.prepend_keymap]]
          on = "<C-d>"
          run = "shell 'ripdrag %s -A -x -i 2>/dev/null &' --confirm"
          desc = "Drag and drop"

          [[mgr.prepend_keymap]]
          on = "y"
          run = [ "yank", 'plugin clipboard -- --action=copy' ]
          desc = "Yank to Clipboard"

          [[mgr.prepend_keymap]]
          on = "x"
          run = [ "yank --cut", 'plugin clipboard -- --action=copy' ]
          desc = "Cut to Clipboard"

          [[mgr.prepend_keymap]]
          on = "p"
          run = [ 'plugin clipboard -- --action=paste', "unyank" ]
          desc = "Paste from Clipboard"
        '';
      };
    };
}
