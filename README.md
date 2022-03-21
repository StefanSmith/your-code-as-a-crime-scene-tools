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

This repository assumes it is a sibling directory of the source repositories you wish to analyse. To run an analysis, call a make recipe, substituting the name of the repository you wish to analyse. All examples below use `my-repo` as an example.

Data is cached (per repository) between executions and is **not** regenerated when parameter values change. To clear the cache for a repository, run `make clean-[repo]`, e.g. `make clean-my-repo`. 

### Summary of activity
Reports number of files, number of changes to files and number of authors involved during the specified time frame.
```shell
make my-repo-change-summary from=<YYYY-MM-DD> to=<YYYY-MM-DD>
```

### Interactive hotspot diagram
Opens an interactive "circle packing" diagram showing code files, with highlighted red hotspots. The larger the circle, the more lines of code (a rough proxy for complexity). The darker the circle, the higher the frequency of change (correlates with deminishing quality and higher defect rate).
```shell
make my-repo-hotspots from=<YYYY-MM-DD> to=<YYYY-MM-DD> langs="<comma-separated language list>" excludeDirs="<excluded directory regex>"
```
Notes:
- Valid values for `langs` can be listed by running `cloc --show-lang`. Examples include `PHP`, `JavaScript` and `TypeScript`.
- `excludeDirs` takes a regex expression that is matched against the full path of each file's containing directory. Use `|` between alternative paths you wish to exclude. At a minimum, you should always exclude the path to third party libraries (e.g. `/node_modules/` in JavaScript or `./src/vendor` in PHP).  

### Hotspot table
Prints a CSV of code files, sorted by frequency of change, and reporting the current number of lines of code and the number of changes in the specified time frame.
```shell
make my-repo-hotspots-table from=<YYYY-MM-DD> to=<YYYY-MM-DD> langs="<comma-separated language list>" excludeDirs="<excluded directory regex>"
```
See [Interactive hotspot diagram](#interactive-hotspot-diagram) for details of parameter usage.

### File complexity
Prints a single-row CSV of the `total`, `mean`, `standard deviation` and `maximum` number of indentations (tab or 4 spaces) in a specified file.

Number of indentations is a useful proxy for complexity as it is correlated with the level of code nesting (e.g. nested `if` clauses). A high `maximum` (e.g. `6`) indicates areas of excessive complexity. If the `mean` is also high, the file may suffer from rampant complexity.
```shell
make my-repo-indentation file=<path to file relative to base of target repo>
```

### File complexity trend
Generates a CSV file for the specified code file, containing a row per commit over the specified time interval. Each row includes the `total`, `mean` and `standard deviation` number of indentations (tab or 4 spaces) at that point in time.

Number of indentations is a useful proxy for complexity as it is correlated with the level of code nesting (e.g. nested `if` clauses).

The CSV file can be found in `data/<repository name>/indentation-trend.csv`.

After generating the CSV file, paste it into your favourite spreadsheet software and chart how `total`, `mean` and `standard deviation` change over time. This provides a view of the trend in complexity. For example, if the `total` steadily increases but there has been work to refactor the code, you should see a decline in the `mean` and `standard deviation`.
```shell
make my-repo-indentation-trend from=<YYYY-MM-DD> to=<YYYY-MM-DD> file=<path to file relative to base of target repo>
```