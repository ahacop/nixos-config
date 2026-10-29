{
  flake.templates = {
    ruby = {
      path = ../devflakes/ruby;
      description = "Ruby dev shell (pinned ruby + gem build deps)";
    };
    rails = {
      path = ../devflakes/rails;
      description = "Rails dev shell (ruby + postgres, node, vips, flyctl, etc.)";
    };
    rust = {
      path = ../devflakes/rust;
      description = "Rust dev shell (stable toolchain + clippy/rustfmt/rust-analyzer)";
    };
    prolog = {
      path = ../devflakes/prolog;
      description = "Prolog dev shell (SWI-Prolog + GUI, prolog_ls, just)";
    };
    lean = {
      path = ../devflakes/lean;
      description = "Lean 4 dev shell (lean + lake, pinned by this flake)";
    };
  };
}
