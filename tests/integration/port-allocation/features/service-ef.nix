{ pkgs }:
import ../templates/web-service.nix {
  name = "ef";
  dist = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>ef-edsl</title>
      </head>
      <body>
        <h1>ef-edsl</h1>
        <blockquote>ef - a fairy tale of modules</blockquote>
        <p>ef is an eDSL over Nix module system.</p>
      </body>
    </html>
  '';
}
