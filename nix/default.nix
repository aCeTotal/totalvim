{inputs, ...}: {
  flake.overlays.default = final: _prev: {
    totalvim =
      inputs.mnw.lib.wrap
      {
        pkgs = final;
        inherit inputs;
      }
      ./mnw;
  };

  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    _module.args.pkgs =
      builtins.foldl' (p: o: p.extend o)
      inputs'.nixpkgs.legacyPackages
      [
        inputs.self.overlays.default
      ];

    packages.totalvim = pkgs.totalvim;
    packages.default = pkgs.totalvim;
  };
}
