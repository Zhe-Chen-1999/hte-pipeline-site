# harhay-lab.github.io

Website for the Harhay Lab and NHLBI **R01HL168202** — Bayesian causal inference
and machine learning for critical care trials.

Live at <https://harhay-lab.github.io>.

## Editing

See **[HOW-TO-UPDATE.md](HOW-TO-UPDATE.md)**. Adding a person or an analysis is a
few lines in a YAML file, editable in the browser; the site rebuilds itself.

| To change | Edit |
|---|---|
| People | `people.yml` |
|  People | `people.yml` |
| Home page text | `index.qmd` |
| Look and feel | `styles.scss` |
| Navigation bar | `_quarto.yml` |

## Building locally

Requires [Quarto](https://quarto.org) (bundled with RStudio):

```bash
quarto preview     # live preview at localhost
quarto render      # build into _site/
```

Pages containing R code are rendered locally and their output committed under
`_freeze/`; the publish workflow installs Quarto only and never executes R.
