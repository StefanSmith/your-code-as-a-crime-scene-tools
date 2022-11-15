# Your Code as a Crime Scene tools

Scripts for performing analyses described in the book [Your Code as a Crime Scene](https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

## Prerequisites

The scripts rely on a couple of tools provided by Adam Tornhill, the author of the book. The `cloc` command must also be installed. Follow the instructions below to configure your environment.

### maat-scripts

This has been checked in as a git submodule. To retrieve it, run the following from within the project directory.

```commandline
git submodule update --init --recursive
```

### code-maat

1. Ensure you have Java 8 or above installed
2. Download the [latest release](https://github.com/adamtornhill/code-maat/releases) of the standalone jar file
3. Move the jar file to `/opt/code-maat`
4. Rename the jar file `code-maat.jar`
5. In the same direactory, create a script called `maat` with the following lines:
    ```shell
    #!/bin/sh
    java -jar "$(cd "$(dirname "$0")"; pwd)/code-maat.jar" $@
   ```
6. Make the script executable with `chmod +x maat`
7. Add the directory to your path (e.g. `echo export PATH=\"\$PATH:/opt/code-maat\" >> ~/.zshrc && source ~/.zshrc`)

### cloc

Follow the installation instructions at https://github.com/AlDanial/cloc.

## Usage

To run an analysis, call one of the `make` recipes documented in [Analysis recipes](#analysis-recipes), specifying which repositories to analyse and over what time period, for example:

```
make -j change-summary repoUrls='git@github.com:org-1/repo-a.git' from=2021-05-01 to=2022-03-01
```

Note: passing `-j` instructs make to execute recipes in parallel where possible.

## Common recipe parameters

### `repoUrls` (required unless `repoUrlsFile` specified)

Takes a semicolon-separated list of ssh URLs for the repositories you wish to analyse.

Each repository will be cloned into a subdirectory under `data/repositories/` based on the repository URL and name. For example, `git@github.com:org-1/repo-a.git` will be cloned into `com/github/org-1/repo-a`.

Once cloned, a repository's `main` or `master` branch will be checked out.

#### Example

```
repoUrls='git@github.com:org-1/repo-a.git; git@github.com:org-2/repo-b.git; git@github.com:org-1/repo-3.git'
```

Optionally, you can specify a relative directory path per repository by adding a pipe-delimited suffix to the URL. For example, passing `git@github.com:org-1/repo-a.git|prefix/path/` will clone the repository into `prefix/path/github/org-1/repo-a`. This can be used to organise repositories into hierarchies, e.g. by org structure. This can be useful when generating a hierarchical visualistion such as [hotspots](#hotspots).

### `repoUrlsFile` (required unless `repoUrls` specified)

Takes the path to a file containing a list of git repositories to analyse. Useful for when you want to analyse a large number of repositories at once. Supports the same repository specification format as `repoUrls` but separates each repository using a new line instead of a semicolon.

### `from` and `to` (required)

Take dates of the form `YYYY-MM-DD` specifying the time period over which repository activity should be analysed.

Note: these parameters are not required by the `indentation` recipe.

### `groups` (optional)

Takes a semicolon-separated list of relative directory paths whose metrics will be aggregated. This allows you to perform architectural analysis by grouping at the level of packages, layers or even whole repositories.

If you are only analysing a single repository, file paths are relative to the repository root directory. If you are analysing multiple repositories, file paths are prefixed with their local repository path, e.g. `com/github/org-1/repo-1`. 

Each group is defined using the following syntax:

```
[relative directory path] => [group name]
``` 

Note this parameter has no effect on the behaviour of the following recipes:
- [indentation](#indentation)
- [indentation-trend](#indentation-trend)

#### Example 1: analysing application and test code

```
groups='src => Application Code; tests/unit => Unit Tests; tests/e2e => E2E Tests'
```

#### Example 2: analysing MVC code
```
groups='src/models => Models; src/controller => Controller; src/views => Views'
```

#### Example 3: analysing repositories

Note: assumes multiple repositories defined in `repoUrls`

```
groups='com/github/org-1/repo-a => Repo A; com/github/org-2/repo-b => Repo B'
```

### `groupByRepo` (optional)

Set to `true` to automatically group by repository. Each group is named according to the repository's name. To avoid collisions when analysing multiple repositories with the same name (but different URLs), see [fullyQualifiedRepoNames](#fullyqualifiedreponames-optional);

The following parameter combinations are equivalent

```
repoUrls='git@github.com:org-1/repo-a.git; git@github.com:org-2/repo-b.git' \
groupByRepo=true 
```
```
repoUrls='git@github.com:org-1/repo-a.git; git@github.com:org-2/repo-b.git' \
groups='com/github/org-1/repo-a => repo-a; com/github/org-2/repo-b => repo-b'
```

### `fullyQualifiedRepoNames` (optional)

Set to `true` whilst using `groupByRepo=true` to generate groups with fully-qualified repository names. This is useful for avoiding collisions when two repositories have the same name but different URLs. A repository with URL `git@github.com:org-1/repo-a.git` will have a group name of `com.github.org-1.repo-a`.

## Analysis recipes

### `change-summary`
Reports the number of commits, number of files, number of separate changes to files and number of authors involved.

### `change-frequency`
Reports how many commits each file has appeared in.

### `hotspots`
Opens an interactive "circle packing" diagram showing code files, with highlighted red hotspots. The larger the circle, the more lines of code (a rough proxy for complexity). The darker the circle, the higher the frequency of change (correlates with deminishing quality and higher defect rate).

You must set the `langs` parameter to a comma-separated list of programming languages that you would like `cloc` to count. For example, `langs=JavaScript,TypeScript'`. Valid values can be listed by running `cloc --show-lang`.

### `hotspots-table`
Prints a table of code files, sorted by change frequency. Each row includes the file's path, lines of code at the end of the analysed time period, and the number of commits it appeared in.

As with the [hotspots](#hotspots) recipe, you must specify the `langs` parameter.

### `indentation`
Indicates the code complexity of a file (specified by the mandatory `file` parameter) by reporting the `total`, `mean`, `standard deviation` and `maximum` number of indentations (tab or 4 spaces) for the file.

The number of indentations is a useful proxy for complexity as it correlates with the level of code nesting (e.g. nested `if` clauses). A high `maximum` (e.g. `6`) indicates areas of excessive complexity. If the `mean` is also high, the file may suffer from rampant complexity.

The `file` parameter is relative to a repository's root directory. If you have provided multiple URLs in `repoUrls`, prefix the `file` parameter with repository's local file path, e.g. `com/github/org-1/repo-a/src/code.js`. 

### `indentation-trend`
Generates and prints a CSV file that indicates the trend in complexity of a code file (specified by the mandatory `file` parameter). The CSV contains a row per commit over the analysed time period. Each row includes the `total`, `mean` and `standard deviation` number of indentations (tab or 4 spaces) at that point in time.

See [indentation](#indentation) for an explanation of why indentations are a useful proxy for complexity. The `file` parameter is treated the same way as in the `indentation` recipe. 

The location of the generated CSV is reported on the command line. After it is generated, paste its contents into your favourite spreadsheet software and chart how `total`, `mean` and `standard deviation` change over time. This provides a view of the trend in complexity. For example, if the `total` steadily increases but there has been work to refactor the code, you should see a decline in the `mean` and `standard deviation`.

### `sum-of-coupling`
For each file, prints the number of times it has shared a commit with another file.

### `coupling`
For pairs of files, prints the % of shared commits and their average number of commits. Only reports pairs that satisfy criteria specified by the following (optional) parameters:

- `minRevisions` (default: 5) - the minimum number commits each file must have appeared in
- `minSharedRevisions` (default: 5) - the minimum number of commits the pair of files must share
- `minCoupling` (default: 30) - the minimum % coupling of the file pair

The higher the average number of commits, the more we can rely on the reported % to inform our expectations about the future degree of coupling between these files.

By default, coupling analysis only considers changes within the same commit. For cross-repository analysis, you can instead consider changes within a given time frame (in days). Specify a number of days using the optional `couplingDays` parameter.

### `authors`
For each file, prints the number of unique authors.

### `main-devs`
Prints two lines for each file:

- One for the author who has added the most lines
- One for the author who has removed the most lines.

In both cases, the number of lines added or removed by the author is reported, alongside the total lines added or removed and the authors % contribution.

Removed lines is an approximate indication of the most prolific refactorer. This may be a more accurate indicator of the most knowledgeable developer for a given file, since lines added is subject to disruption from developers who practice copy-paste.

### `entity-ownership`
Reports the number of lines added and removed by per file, per author.

Useful for investigating who the authors are and whether they have used multiple different aliases that should be merged in the log of file changes.

## Clearing local data

File change history and lines of code counts are cached between executions. Results are also written to disk.

To clear the cache and results, run `make clean`.

To remove the cache, results _and_ the cloned repositories, run `make clean-all`.

## Fetching repositories

By default, repositories specified in `repoUrls` will be cloned just in time when executing an analysis recipe. If you are planning to work offline, you may wish to clone repositories upfront. Since analysis can takes time, there is a dedicated recipe for simply fetching repositories.

Just run `make -j fetch-source` and specify the `repoUrls` parameter as usual.

## Refreshing repository history

Currently, there is no way recipe for pulling down changes for a repository. You can either manually run `git pull` from inside the repository directory or delete the repository and re-run the analysis.