{
  description = "Cross Platform Development Toolbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager";
    # home-manager inherits the same git hash as nikpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # pure data repo (no flake.nix) — fetched as a plain source tree
    tinted-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
