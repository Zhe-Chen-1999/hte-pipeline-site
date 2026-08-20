# How to edit this website

No installation, no git commands. Everything below happens in a web browser, and
the site rebuilds itself about a minute after you save.

The pattern is always the same: open the file on GitHub → click the pencil
icon (top right) → change the text → click **Commit changes** at the bottom.

---

## Which file controls what

| What you see on the site | File to edit |
|---|---|
| Home page | `index.qmd` |
| Tutorial page | `tutorial.qmd` |
| Full analysis page | `analysis.qmd` |
| People — names, roles, links | `people.yml` |
| Publications | `publications.yml` |
| Preprints | `preprints.yml` |
| The menu bar at the top | `_quarto.yml` |
| The big rendered analysis itself | `output/full-analysis.html` |
| Colours, fonts, spacing | `styles.scss` |

---

## Recipe 1 — Change some words

Say the home page reads "randomized trials" and you want "clinical trials".

1. Open `index.qmd`, click the pencil.
2. Find the line. Change the words. Leave the punctuation and symbols around it
   alone.
3. Commit.

The formatting marks mean:

| You type | You get |
|---|---|
| `## Something` | a heading |
| `**bold**` | **bold** |
| `*italic*` | *italic* |
| `[click here](https://example.com)` | a link |
| `- item` | a bullet |

Anything you don't touch stays exactly as it was.

---

## Recipe 2 — Add a GitHub link

**In the middle of a sentence**, anywhere in a `.qmd` file:

```markdown
The code is [on GitHub](https://github.com/harhay-lab/your-repo).
```

**As a button**, on its own line:

```markdown
[View the source code](https://github.com/harhay-lab/your-repo){.btn .btn-primary}
```

**In the top menu bar** — open `_quarto.yml` and add a `- href:` line under
`left:`, keeping the indentation identical to its neighbours:

```yaml
  navbar:
    left:
      - href: index.qmd
        text: Home
      - href: tutorial.qmd
        text: Tutorial
      - href: https://github.com/harhay-lab/your-repo    # <- added
        text: Source code                                 # <- added
```

**As the small GitHub icon on the right** — that already exists in `_quarto.yml`;
just change the address:

```yaml
    right:
      - icon: github
        href: https://github.com/harhay-lab      # <- change this
```

---

## Recipe 3 — Delete a module

Every block on a page starts with a `##` heading and runs until the next `##`.
To remove one, delete from its heading down to (but not including) the next
heading.

**To remove a whole page** — say the People page — do both of these:

1. Delete the file `people.qmd` (open it, click the **trash icon**, commit).
2. Remove its two lines from the `navbar` in `_quarto.yml`:

   ```yaml
         - href: people.qmd     # <- delete
           text: People         # <- delete
   ```

Miss step 2 and the menu will link to a page that no longer exists.

---

## Recipe 4 — Add or edit a person

Open `people.yml`. Copy one block, paste it where you want the person to appear,
and change the values:

```yaml
- name: Zhe Chen, PhD
  role: Research Assistant Professor
  affiliation: University of Pennsylvania
  email: zhe.chen@pennmedicine.upenn.edu
  url: https://example.com
  github: https://github.com
```

People appear in the same order as the file. Only `name` and `role` are required
— delete any other line you don't need.

**The two rules that matter:** every entry starts with `- ` in the first column,
and every line under it is indented by exactly **two spaces**. Getting this wrong
is the usual cause of a failed build.

---

## Recipe 5 — Add a publication

Open `publications.yml`. Copy one block, paste it at the **top** (newest first),
and change the values:

```yaml
- title: The paper's title
  authors: Smith A, Jones B, Harhay MO
  journal: Journal Name, 2026;12(3):123-145
  pdf: https://pmc.ncbi.nlm.nih.gov/articles/PMC1234567/pdf/
  journal_url: https://doi.org/10.1000/example
  code: https://github.com/harhay-lab/the-repo
  pmid: "12345678"
```

Each line adds one link to the card — **PDF**, **Journal**, **Code**, **PubMed**.
Leave out any you don't have and that link simply won't appear. Only `title` is
required.

For an open-access paper in PubMed Central, the PDF link is
`https://pmc.ncbi.nlm.nih.gov/articles/PMCxxxxxxx/pdf/` — find the PMC number on
the paper's PubMed page.

**Preprints** work identically but live in `preprints.yml`. When a preprint is
published, move its block across into `publications.yml` and update the journal
details.

---

## Recipe 6 — Update the rendered analysis

When you re-knit the pipeline, replace the file on the site:

1. Open the `output` folder on GitHub.
2. **Add file → Upload files**, drag in the new HTML.
3. Rename it to `full-analysis.html` so it replaces the old one, then commit.

Nothing else changes — `analysis.qmd` already points at that filename.

Note that the underlying trial data (`shamroc_cart.csv`) is **not** in this
repository and never should be. Only the rendered output is published.

---

## Recipe 7 — Add a photo

1. Open the `assets` folder → **Add file → Upload files** → drag the image in →
   commit. Square, around 400×400 pixels, works best.
2. Add one line to that person's entry in `people.yml`:

   ```yaml
     photo: assets/zhe-chen.jpg
   ```

---

## When something goes wrong

Every commit triggers a build. Open the **Actions** tab of the repository:

- **Green tick** — the site updated. Reload the page (hold Shift while clicking
  reload if you still see the old version).
- **Red cross** — the build failed and the site was left exactly as it was. Click
  the failed run to read the error.

Almost every failure is YAML indentation in `people.yml` or `_quarto.yml`. If you
can't spot it, open the **commit history**, find your change, and click **Revert**
— the site returns to its last working state and nothing is lost.

---

## For maintainers: pages that run R

Pages containing R code are rendered **locally** and their output committed under
`_freeze/`. The GitHub Action installs Quarto only and never runs R.

```bash
quarto preview                    # live preview while editing
quarto render                     # build everything into _site/
git add _freeze && git commit -m "update" && git push
```

This is deliberate: the analyses take hours, need patient-level data, and must
never execute on a public runner.

