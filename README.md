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

### Recipes

To run an analysis, call a `make` recipe and pass the URL of the repository you wish to analyse in the `repoUrl` parameter.

#### Summary of activity
Reports number of files, number of changes to files and number of authors involved during the specified time frame.
```shell
make change-summary repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD>
```

#### Change frequency
Print how many commits each file has appeared in during the specified time period.
```shell
make change-frequency repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [groups]
```
Notes:
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

#### Interactive hotspot diagram
Opens an interactive "circle packing" diagram showing code files, with highlighted red hotspots. The larger the circle, the more lines of code (a rough proxy for complexity). The darker the circle, the higher the frequency of change (correlates with deminishing quality and higher defect rate).
```shell
make hotspots repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> langs="<comma-separated language list>" excludeDirs="<excluded directory regex>"
```
Notes:
- Valid values for `langs` can be listed by running `cloc --show-lang`. Examples include `PHP`, `JavaScript` and `TypeScript`.
- `excludeDirs` takes a regex expression that is matched against the full path of each file's containing directory. Use `|` between alternative paths you wish to exclude. At a minimum, you should always exclude the path to third party libraries (e.g. `/node_modules/` in JavaScript or `./src/vendor` in PHP).  

#### Hotspot table
Prints a CSV of code files, sorted by frequency of change, and reporting the current number of lines of code and the number of changes in the specified time frame.
```shell
make hotspots-table repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> langs="<comma-separated language list>" excludeDirs="<excluded directory regex>"
```
See [Interactive hotspot diagram](#interactive-hotspot-diagram) for details of parameter usage.

#### File complexity
Prints a single-row CSV of the `total`, `mean`, `standard deviation` and `maximum` number of indentations (tab or 4 spaces) in a specified file.

Number of indentations is a useful proxy for complexity as it is correlated with the level of code nesting (e.g. nested `if` clauses). A high `maximum` (e.g. `6`) indicates areas of excessive complexity. If the `mean` is also high, the file may suffer from rampant complexity.
```shell
make indentation repoUrl=<repository url> file=<path to file relative to base of target repo>
```

#### File complexity trend
Generates and prints a CSV file for the specified code file, containing a row per commit over the specified time interval. Each row includes the `total`, `mean` and `standard deviation` number of indentations (tab or 4 spaces) at that point in time.

Number of indentations is a useful proxy for complexity as it is correlated with the level of code nesting (e.g. nested `if` clauses).

The CSV file can be found in `data/<repository name>/indentation-trend.csv`.

After generating the CSV file, paste it into your favourite spreadsheet software and chart how `total`, `mean` and `standard deviation` change over time. This provides a view of the trend in complexity. For example, if the `total` steadily increases but there has been work to refactor the code, you should see a decline in the `mean` and `standard deviation`.
```shell
make indentation-trend repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> file=<path to file relative to base of target repo>
```

#### Sum of coupling
For each file, prints the number of times other files changed alongside it in the same commit
```shell
make sum-of-coupling repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [groups]
```
Notes:
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

#### Coupling
For pairs of files, prints the % of shared commits and an average their respective number of commits
```shell
make coupling repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [minRevisions=5] [minSharedRevisions=5] [minCoupling=30] [groups]
```
Notes:
- The higher the average number of commits, the more we can rely on the reported % to inform our expectations about the future degree of coupling between these files.
- We can use optional arguments to restrict the reported pairs to those that are more significant. Default values are listed above.
  - `minRevisions` filters out files that have fewer total commits
  - `minSharedRevisions` filters out pairs that have fewer total shared commits
  - `minCoupling` filters out pairs that have a lower degree of coupling
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

#### Authors
For each file, prints the number of unique authors over the specific time period
```shell
make authors repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [groups]
```
Notes:
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

#### Main Developers
Prints two lines for each file: one for the author who has added the most lines and one for the author who has removed the most lines. In both cases, the number of lines added or removed by the author is reported, alongside the total lines added / removed and the authors % contribution.

Removed lines is an approximate indication of the most prolific refactorer. This may be the true "most knowledgeable developer" for a given file, since lines added is subject to disruption from copy-paste behaviour.
```shell
make main-devs repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [groups]
```
Notes:
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

#### Entity Ownership
Prints a line for each file and each author during the specific time period. Reports the number of lines added and removed by each author.

Useful for investigating who the authors are and whether they have used multiple different aliases that should be merged in the log of file changes.
```shell
make entity-ownership repoUrl=<repository url> from=<YYYY-MM-DD> to=<YYYY-MM-DD> [groups]
```
Notes:
- See [Architectural analysis](#architectural-analysis) for explanation of `groups` parameter

### Architectural analysis

Instead of performing an analysis per file, you can define groups of files and analyse at the level of system layers or other architectural constructs. Specify how you wish to group files using the `groups` argument. For example:

``groups="src/app => Code; src/tests/acceptance => AcceptanceTest; src/tests/api => ApiTest; src/tests/functional => FunctionalTest; src/tests/unit => UnitTest; ansible => Infrastructure""``

Groups can also be defined in terms of exact-match regex patterns, e.g. `^src/apps/([^/]+/)*[^\.]+\.js\$$`. Note: double `$` due to behaviour of `make`

### Clearing cache and results

File change history is cached (per repository) between executions. Results are also written to disk.

To clear the cache and results for a repository, run `make clean-repo-results repoUrl=<url name>`. To also remove the cloned repository, run `make clean-repo repoUrl=<url name>`.

To clear all repositories and results, run `make clean`.