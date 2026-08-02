{ inputs, ... }: {
  flake.homeModules.theme =
    {
      pkgs,
      toolbox,
      lib,
      config,
      ...
    }:
    let
      # ==========================================================================
      # THEME SYSTEM — source of truth: tinted-theming/schemes (base16)
      # ==========================================================================
      schemesDir = "${inputs.tinted-schemes}/base16";
      stateDir = "${config.home.homeDirectory}/.local/share/theme";

      schemesRaw = toolbox.theme.schemes or [ ];
      defaultScheme = toolbox.theme.default or "rose-pine";
      schemes =
        assert lib.elem defaultScheme schemesRaw;
        schemesRaw;

      # --- pure-Nix YAML subset parser (spec-0.11 base16) ------------------------
      trim = s:
        let
          m = builtins.match "[ \t]*([^ \t].*[^ \t]|[^ \t])([ \t]*)" s;
        in
        if m == null then "" else builtins.elemAt m 0;

      parseLine = line:
        let
          quoted = builtins.match "([^:]+): *\"([^\"]*)\".*" line;
        in
        if quoted == null then null else {
          name = trim (builtins.elemAt quoted 0);
          value = builtins.elemAt quoted 1;
        };

      schemeFromYAML = slug: content:
        let
          lines = builtins.filter (l: l != "") (lib.strings.splitString "\n" content);
          pairs = builtins.filter (p: p != null) (map parseLine lines);
          attrs = lib.foldl'
            (acc: p:
              if lib.strings.hasPrefix "base" p.name then
                acc // {
                  palette = (acc.palette or { }) // { ${p.name} = lib.removePrefix "#" p.value; };
                }
              else
                acc // { ${p.name} = p.value; })
            { } pairs;
        in
        {
          inherit slug;
          name = attrs.name or slug;
          author = attrs.author or "unknown";
          variant = attrs.variant or "dark";
          palette = attrs.palette;
        };

      schemesList = map (
        slug: schemeFromYAML slug (builtins.readFile "${schemesDir}/${slug}.yaml")
      ) schemes;
      schemesMap = lib.listToAttrs (map (s: lib.nameValuePair s.slug s) schemesList);

      defaultSchemeObj = schemesMap.${defaultScheme};

      # --- ANSI palette derivation ----------------------------------------------
      # base16 slots -> terminal ANSI 0-15 (base16 terminal template convention)
      ansiBase = s: [
        s.palette.base00 #  0 black
        s.palette.base08 #  1 red
        s.palette.base0B #  2 green
        s.palette.base0A #  3 yellow
        s.palette.base0D #  4 blue
        s.palette.base0E #  5 magenta
        s.palette.base0C #  6 cyan
        s.palette.base05 #  7 white (default fg)
      ];
      ansiBright = s: [
        s.palette.base03 #  8 gray / bright black (comment)
        s.palette.base09 #  9 bright red
        s.palette.base01 # 10
        s.palette.base02 # 11
        s.palette.base04 # 12
        s.palette.base06 # 13
        s.palette.base0F # 14
        s.palette.base07 # 15
      ];

      # 10-key palette used by nvim lean_sync and the tmux/terminal emitters
      paletteFor = s: {
        bg = s.palette.base00;
        fg = s.palette.base05;
        black = s.palette.base00;
        red = s.palette.base08;
        green = s.palette.base0B;
        yellow = s.palette.base0A;
        blue = s.palette.base0D;
        magenta = s.palette.base0E;
        cyan = s.palette.base0C;
        white = s.palette.base05;
        gray = s.palette.base03;
      };

      # --- per-scheme emitters ---------------------------------------------------
      emitNvim = s:
        let
          p = paletteFor s;
        in
        ''
          return {
            bg       = "#${p.bg}",
            fg       = "#${p.fg}",
            black    = "#${p.black}",
            red      = "#${p.red}",
            green    = "#${p.green}",
            yellow   = "#${p.yellow}",
            blue     = "#${p.blue}",
            magenta  = "#${p.magenta}",
            cyan     = "#${p.cyan}",
            white    = "#${p.white}",
            gray     = "#${p.gray}",
          }
        '';

      emitTmux = s:
        let
          p = paletteFor s;
        in
        ''
          set -g status-style "bg=#${p.bg},fg=#${p.fg}"
          set -g status-left "#[fg=#${p.bg},bg=#${p.green},bold] 󰨖 #S #[bg=default,fg=default] "
          # status-right intentionally omitted — continuum prepends its save
          # interpolation there; overwriting it breaks auto-save.
          set -g window-status-format "#[fg=#${p.gray},bg=default] #I:#W "
          set -g window-status-current-format "#[fg=#${p.green},bg=#${p.gray},bold] #I:#W "
          set -g window-status-separator ""
          set -g pane-border-style "fg=#${p.gray}"
          set -g pane-active-border-style "fg=#${p.green}"
          set -g message-style "bg=#${p.gray},fg=#${p.green},bold"
        '';

      emitGhostty = s:
        let
          p = paletteFor s;
          colors = lib.imap0 (i: c: "palette = ${toString i}=#${c}") (ansiBase s ++ ansiBright s);
        in
        lib.concatStringsSep "\n" ([
          "background = #${p.bg}"
          "foreground = #${p.fg}"
          "cursor-color = #${p.fg}"
        ] ++ colors);

      emitJson = s:
        builtins.toJSON {
          slug = s.slug;
          name = s.name;
          author = s.author;
          variant = s.variant;
          background = "#${s.palette.base00}";
          foreground = "#${s.palette.base05}";
          cursor = "#${s.palette.base05}";
          ansi = map (c: "#${c}") (ansiBase s ++ ansiBright s);
        };

      emitFiles = s: [
        {
          name = ".local/share/theme/palettes/${s.slug}/nvim.lua";
          value = { text = emitNvim s; };
        }
        {
          name = ".local/share/theme/palettes/${s.slug}/colors.tmux";
          value = { text = emitTmux s; };
        }
        {
          name = ".local/share/theme/palettes/${s.slug}/palette.json";
          value = { text = emitJson s; };
        }
        {
          name = ".local/share/theme/palettes/${s.slug}/ghostty.conf";
          value = { text = emitGhostty s; };
        }
      ];

      # --- runtime CLI -----------------------------------------------------------
      themeCli = pkgs.writeShellScriptBin "theme" ''
        set -euo pipefail

        THEME_DIR="${stateDir}"
        ACTIVE="$THEME_DIR/active.json"
        JQ=${pkgs.jq}/bin/jq

        apply() {
          local slug="$1"
          local name
          name=$("$JQ" -r '.name' "$THEME_DIR/palettes/$slug/palette.json")
          "$JQ" -n --arg slug "$slug" --arg name "$name" '{slug: $slug, name: $name}' > "$ACTIVE"
          cp -f "$THEME_DIR/palettes/$slug/nvim.lua"     "$THEME_DIR/active/nvim-palette.lua"
          cp -f "$THEME_DIR/palettes/$slug/colors.tmux"  "$HOME/.config/tmux/colors.tmux"
          cp -f "$THEME_DIR/palettes/$slug/palette.json" "$THEME_DIR/active/palette.json"
          cp -f "$THEME_DIR/palettes/$slug/ghostty.conf" "$THEME_DIR/active/ghostty.conf"
        }

        reload() {
          if [ -n "''${TMUX:-}" ]; then
            tmux source-file "$HOME/.config/tmux/tmux.conf"
          fi
          if [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
            find "$XDG_RUNTIME_DIR" -type s 2>/dev/null | grep "nvim" | while read -r server; do
              nvim --server "$server" --remote-expr "execute('lua package.loaded[\"lean.core.palette\"] = nil; vim.cmd(\"colorscheme lean_sync\")')" >/dev/null 2>&1 &
            done || true
          fi
        }

        case "''${1:-}" in
          switch)
            slug="''${2:-}"
            if [ -z "$slug" ]; then
              echo "Usage: theme switch <slug>"
              echo "Available:"
              ls -1 "$THEME_DIR/palettes/"
              exit 1
            fi
            if [ ! -f "$THEME_DIR/palettes/$slug/palette.json" ]; then
              echo "Error: theme '$slug' not found."
              echo "Available:"
              ls -1 "$THEME_DIR/palettes/"
              exit 1
            fi
            apply "$slug"
            echo "Switched to theme: $slug"
            reload
            ;;
          list)
            echo "Available themes:"
            for d in "$THEME_DIR/palettes/"*/; do
              [ -d "$d" ] || continue
              echo "  $(basename "$d")"
            done
            echo ""
            if [ -f "$ACTIVE" ]; then
              echo "Active: $("$JQ" -r '.slug' "$ACTIVE")"
            else
              echo "Active: (none)"
            fi
            ;;
          current)
            if [ -f "$ACTIVE" ]; then
              "$JQ" -r '"\(.slug) [\(.name)]"' "$ACTIVE"
            else
              echo "No active theme"
              exit 1
            fi
            ;;
          reload)
            if [ -f "$ACTIVE" ]; then
              apply "$("$JQ" -r '.slug' "$ACTIVE")"
              reload
            else
              echo "No active theme"
              exit 1
            fi
            ;;
          *)
            echo "Usage: theme <command>"
            echo ""
            echo "Commands:"
            echo "  switch <slug>  Switch to a theme"
            echo "  list           List available themes and show active"
            echo "  current        Show the active theme"
            echo "  reload         Re-apply active theme without switching"
            ;;
        esac
      '';
    in
    {
      # ==========================================================================
      # INSTALLED FILES + CLI
      # ==========================================================================
      home.file = lib.mkMerge [
        (lib.listToAttrs (lib.flatten (map emitFiles schemesList)))
      ];

      home.packages = [
        themeCli
        pkgs.jq
      ];

      # ==========================================================================
      # ACTIVATION — seed state dir + default active theme
      # ==========================================================================
      home.activation.initTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/mkdir -p "${stateDir}/active" "$HOME/.config/tmux"

        if [ ! -f "${stateDir}/active.json" ]; then
          ${pkgs.coreutils}/bin/printf '%s\n' '${
            builtins.toJSON {
              slug = defaultScheme;
              name = defaultSchemeObj.name;
            }
          }' > "${stateDir}/active.json"
        fi

        ${pkgs.coreutils}/bin/cp -f "${stateDir}/palettes/${defaultScheme}/nvim.lua" "${stateDir}/active/nvim-palette.lua"
        ${pkgs.coreutils}/bin/cp -f "${stateDir}/palettes/${defaultScheme}/colors.tmux" "$HOME/.config/tmux/colors.tmux"
        ${pkgs.coreutils}/bin/cp -f "${stateDir}/palettes/${defaultScheme}/palette.json" "${stateDir}/active/palette.json"
        ${pkgs.coreutils}/bin/cp -f "${stateDir}/palettes/${defaultScheme}/ghostty.conf" "${stateDir}/active/ghostty.conf"
      '';
    };
}
