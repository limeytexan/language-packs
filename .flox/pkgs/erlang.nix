{
  buildEnv,
  lib,
  makeBinaryWrapper,
  runCommand,
  elixir,
  elixir-ls,
  beamPackages,
  erlang-language-platform,
  rebar3,
}:

let
  inherit (beamPackages) erlang;

  packages = [
    elixir
    elixir-ls
    erlang
    # erlang-language-platform
    rebar3
  ];

  collectPropagated =
    pkg:
    [ pkg ]
    ++ (pkg.propagatedBuildInputs or [ ])
    ++ (lib.concatMap collectPropagated (pkg.propagatedBuildInputs or [ ]));

  allPackages = lib.unique (lib.concatMap collectPropagated packages);

in

buildEnv {
  name = "${erlang.pname}-with-packages-${erlang.version}";

  # paths = allPackages;
  paths = packages;

  nativeBuildInputs = [ makeBinaryWrapper ];

  postBuild = ''
    mkdir -p $out/bin

    # If only one package has a bin dir, buildEnv may decide to symlink $out/bin
    # directly to that. So we do this step to make sure we get a writable bin dir.
    mv $out/bin $out/bin-orig

    hex_home="$out/hex"
    mix_home="$out/mix"
    for binary in $out/bin-orig/*; do
      if [ -f "$binary" ] && [ -x "$binary" ]; then
        makeWrapper "$binary" "$out/bin/$(basename "$binary")" \
          --prefix PATH : "$mix_home/escripts" \
          --prefix HEX_HOME : "$hex_home" \
          --prefix MIX_HOME : "$mix_home"
      fi
    done

    rm -rf $out/bin-orig
  '';

  passthru = erlang.passthru // {
    unwrapped = erlang;
    packages = allPackages;
  };

  meta = erlang.meta;
}
