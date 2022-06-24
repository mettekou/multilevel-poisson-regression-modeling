# Multilevel Poisson Regression Modelling

This repository contains the project for Bayesian Statistics (Spring 2022) at Ghent University.

## Prerequisites

### JAGS

### R

Although we perform most of our analysis in JAGS, we control it through R code.
In addition, we use R for anything JAGS cannot do, such as data visualization.

### renv

This project makes use of [the `renv` package](https://rstudio.github.io/renv/) to manage dependencies through a local R library.
You can install it by executing the following command in R:

```r
install.packages("renv")
```

To add a package to the local R library, proceed as usual, but update the renv as well:

```r
install.packages("somePackage")
renv::snapshot()
```

### pandoc

## Adding a chapter

To add a chapter to the report, create an RMarkdown file (i.e. with the file extension `.Rmd`) in the `src` directory

## Rendering the report

Any RMarkdown file (i.e. with the file extension `.Rmd`) in the `src` directory is first converted to LaTeX code, then this code is concatenated, and then XeLaTeX compiles it into a PDF file.

### Windows

On Windows, run `render.cmd` to render the report.

### macOS and Linux

On UNIX systems, such as macOS and Linux, execute `render.sh` to render the report.

## Oral exam feedback

- Formula for Poisson regression model is wrong
- Prefer posterior predictive checks for goodness-of-fit over minimizing DIC
