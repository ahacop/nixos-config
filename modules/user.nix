{ lib, ... }:
{
  # The login name of the one user account. A flake-parts module reads it as
  # config.user.
  options.user = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "ahacop";
  };
}
