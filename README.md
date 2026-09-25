# xatc documentation

Source for the xatc documentation site: automated FAA-style voice ATC for X-Plane 12.
Built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published
to GitHub Pages on every push to `main`.

## Build locally

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

`mkdocs build --strict` runs on every pull request, so a broken link fails the build.
