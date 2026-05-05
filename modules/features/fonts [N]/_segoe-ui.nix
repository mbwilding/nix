{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  rev = "a89213b7136da6dd5c3638db1f2c6e814c40fa84";
  base = "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/${rev}/font";
  fetch =
    name: sha256:
    fetchurl {
      url = "${base}/${name}.ttf";
      inherit sha256;
    };
in
stdenvNoCC.mkDerivation {
  pname = "segoe-ui";
  version = "unstable-2021-10-07";

  srcs = [
    (fetch "segoeui" "09994h56gzqhqb3zl3i29k9xjhzgwnv3r8a2l67y1c2iq053lqhk")
    (fetch "segoeuib" "0z9kzwn23b9alxphg7n08s9i1d3mn9jnpqg8hisc8dj1rdm1bhys")
    (fetch "segoeuii" "08n490k7ll4c56lic1zzrw91rsa3f3p69pzlzwvs0p6jb1xx1dvs")
    (fetch "segoeuiz" "16gq6xn55vc9gwpwd8fpavjl0hx6653a3s9hrd9nlwdb20nmfmnp")
    (fetch "segoeuil" "0l8133gy7zzs2r1g2cl8kkzm0i8ki0mds8hh5iwarp7hdnkcj903")
    (fetch "segoeuisl" "1i63midamkaxg309q1ka6rwr1qnsjqd7z0xim5vxwgbkf95agzdi")
    (fetch "seguisb" "1d27zp9zc11hkh0caqpp951wv0r8202dn9fbgg7q0qp541rpryfi")
    (fetch "seguisbi" "1sprkwlaz82ljigmpalnnafihxfqxhyvi12f71kc3xkhhgcf2dxn")
    (fetch "seguibl" "0daqi8pikwxj827dw43bdz6v8vz6vpy7syl68d22zc68jbq3hxz1")
    (fetch "seguibli" "0vxah1wz8m3k8chw2iscbngvr65pg0iif5v9rn2igmpshnm2y89k")
    (fetch "seguili" "13hbz9hijxyi2d6fbyk8sh6sfzspqz1vhzlik1cx8vnrj07w7qk7")
    (fetch "seguisli" "1sbdzjpq03nxgg6dl314l2rcnzx5kd2jki37klcc3a64p4k2fvh8")
    (fetch "seguisym" "047mjpaxc43z33pdkxvsc71p4w1yg5c7qlxhg0zdjmj46mm35y6j")
    (fetch "seguiemj" "0krb59lnk41k8z79a0kdlqcgq9rmhdcrwgzwrpg6nz7bivfl80kw")
    (fetch "seguihis" "115qx53xv6h8hj7pka85nsjd3p8s157nl7591k1p7xlgciy59ghw")
  ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    for src in $srcs; do
      name="$(stripHash "$src")"
      cp "$src" "$out/share/fonts/truetype/$name"
    done
  '';

  meta = with lib; {
    homepage = "https://github.com/mrbvrz/segoe-ui-linux";
    description = "Segoe UI font family for Linux";
    license = licenses.unfreeRedistributable;
    platforms = platforms.all;
  };
}
