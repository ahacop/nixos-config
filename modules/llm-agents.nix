{ inputs, ... }:
let
  system = "aarch64-linux";
  # Single source of truth for the LLM agent CLIs pulled from the numtide
  # llm-agents flake. The home-manager part below installs them, and the
  # Makefile reads the llmAgents output below to check versions, so the list
  # lives in exactly one place.
  llmAgentNames = [
    "ccusage"
    "claude-code"
    "codex"
    "crit"
    "herdr"
    "hunk"
    "pi"
    "plannotator"
  ];
  llmAgentPkgs = inputs.llm-agents.packages.${system};
in
{
  # Installs the CLIs for the user.
  flake.modules.homeManager.llm-agents = {
    home.packages = map (n: llmAgentPkgs.${n}) llmAgentNames;
  };

  # Installed llm-agents CLIs as an attrset of package name -> main-program
  # (binary) name, e.g. { claude-code = "claude"; ... }, derived from
  # llmAgentNames via each package's meta.mainProgram. `make check-versions`
  # reads this to map packages to binaries and to know which packages to
  # look up upstream, so the tool list only lives in llmAgentNames above.
  flake.llmAgents = builtins.listToAttrs (
    map (n: {
      name = n;
      value = llmAgentPkgs.${n}.meta.mainProgram or n;
    }) llmAgentNames
  );
}
