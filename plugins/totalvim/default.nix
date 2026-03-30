{
  lib,
  vimUtils,
}:
vimUtils.buildVimPlugin {
  pname = "totalvim";
  version = "dev";
  src = lib.cleanSource ./.;
  nvimRequireCheck = "totalvim.health";
  doCheck = false;
}
