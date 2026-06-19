{
  vscode-langservers-extracted,
}:

# vscode-langservers-extracted 4.10.0 has broken Babel output: the server files
# use import.meta.url (ESM syntax) causing Node 24 to load them as ESM, but they
# also use top-level require() (CJS syntax). Patch import.meta.url -> CJS equivalent.
vscode-langservers-extracted.overrideAttrs (old: {
  postFixup = (old.postFixup or "") + ''
    for f in \
      $out/lib/node_modules/vscode-langservers-extracted/lib/css-language-server/node/cssServerMain.js \
      $out/lib/node_modules/vscode-langservers-extracted/lib/html-language-server/node/htmlServerMain.js \
      $out/lib/node_modules/vscode-langservers-extracted/lib/json-language-server/node/jsonServerMain.js; do
      substituteInPlace "$f" \
        --replace-fail 'import.meta.url' '"file://" + __filename'
    done
  '';
})
