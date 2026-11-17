# Producing ebooks for Standard Ebooks. se-new creates a book and se-init
# sets up an existing one, each with an .envrc for the standardebooks-nix
# flake, which has the toolset.
{
  flake.modules.homeManager.ebook-production = {
    programs.zsh.shellAliases = {
      se-new = "nix run github:ahacop/standardebooks-nix -- new";
      se-init = "nix run github:ahacop/standardebooks-nix -- init";
    };
  };
}
