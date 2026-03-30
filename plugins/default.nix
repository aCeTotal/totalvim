{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    legacyPackages.vimPlugins = {
      totalvim = pkgs.callPackage ./totalvim {};
    };
  };
}
