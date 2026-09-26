# Versions

This site is versioned to match xatc's releases. Use the version selector next to the
site title to switch between them.

| Version | What it documents |
|---|---|
| **X.Y** (for example `0.7`) | The xatc release with that MAJOR.MINOR version, including its patch releases (0.7.0, 0.7.1, ...). |
| **latest** | An alias for the newest release. The site's front page opens this one. |
| **dev** | The `main` branch: features that are merged but not yet released. It can describe things your installed copy doesn't have. |

## Which version should I read?

Run `xatc --version` (or look at the first line of `xatc doctor`, or the radio panel
footer) and pick the docs for that MAJOR.MINOR. If you run xatc from a fresh checkout of
`main`, read **dev**.

Each doc version is published at the same time as the matching GitHub Release of xatc,
and every release's notes link to its version of these docs. xatc follows
[Semantic Versioning](https://semver.org/): patch releases (0.7.0 to 0.7.1) fix bugs
without changing behaviour you rely on, so they share one doc version.

!!! note "Before the first versioned release"
    Until the first release is published here, only **dev** exists and the front page
    opens it.
