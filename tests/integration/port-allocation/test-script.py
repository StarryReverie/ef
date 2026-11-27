ef_page = machine.wait_until_succeeds("open-ef", timeout=60)
assert "ef - a fairy tale of modules" in ef_page, ef_page
assert "ef is an eDSL over Nix module system" in ef_page, ef_page

hello_page = machine.wait_until_succeeds("open-hello", timeout=60)
assert "Hello World" in hello_page, hello_page
