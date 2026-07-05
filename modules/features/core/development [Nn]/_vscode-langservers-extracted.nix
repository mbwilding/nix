{
  vscode-langservers-extracted,
}:

# vscode-langservers-extracted 4.10.0 has broken Babel output: the server files
# use import.meta.url (ESM syntax) causing Node 24 to load them as ESM, but they
# also use top-level require() (CJS syntax). Patch import.meta.url -> CJS equivalent.
vscode-langservers-extracted.overrideAttrs (old: {
  postFixup = (old.postFixup or "") + ''
    for f in \
      $out/lib/extensions/css-language-features/server/dist/node/cssServerMain.js \
      $out/lib/extensions/html-language-features/server/dist/node/htmlServerMain.js \
      $out/lib/extensions/json-language-features/server/dist/node/jsonServerMain.js; do
      substituteInPlace "$f" \
        --replace-fail 'import.meta.url' '"file://" + __filename'
    done
  '';
})
