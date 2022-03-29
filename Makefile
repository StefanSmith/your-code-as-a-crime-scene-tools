.PHONEY: clean clean-repo clean-repo-results validate-common-parameters validate-date-range-parameters validate-file-parameter change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership indentation indentation-trend reset-repository

port=9000
minRevisions=5
minCoupling=30
minSharedRevisions=5

repoName=$(shell sed -E 's@[^/]+/(.+)\.git@\1@' <<< "$(repoUrl)")

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
dataDirectoryPath=data
repoWorkingDirectoryPath=$(dataDirectoryPath)/$(repoName)
repoPath=$(repoWorkingDirectoryPath)/repository
resultsDirectoryPath=$(repoWorkingDirectoryPath)/analysis-results
enclosureDiagramDataDirectoryPath=enclosure-diagram/data
enclosureDiagramRepoDataDirectoryPath=$(enclosureDiagramDataDirectoryPath)/$(repoName)
hotspotEnclosureDiagramFilePath=$(enclosureDiagramRepoDataDirectoryPath)/hotspot-enclosure-diagram-data.json
fileChangesLogFilePath=$(resultsDirectoryPath)/file-changes-$(from)-$(to).log
changeFrequencyReportFilePath=$(resultsDirectoryPath)/change-frequency-report.csv
linesOfCodeReportFilePath=$(resultsDirectoryPath)/lines-of-code-report.csv
mainDevReportFilePath=$(resultsDirectoryPath)/main-dev.csv
refactoringMainDevReportFilePath=$(resultsDirectoryPath)/refactoring-main-dev.csv
maatGroupsFilePath=$(resultsDirectoryPath)/maat-groups.txt

.INTERMEDIATE: $(changeFrequencyReportFilePath) \
	$(linesOfCodeReportFilePath) \
	$(hotspotEnclosureDiagramFilePath) \
	$(mainDevReportFilePath) \
	$(refactoringMainDevReportFilePath) \
	$(maatGroupsFilePath)

gitLogCommand=git --git-dir "$(repoPath)/.git" log
maatCommand=maat -l "$(fileChangesLogFilePath)" -c git2

ifdef groups
	maatCommand:=$(maatCommand) -g $(maatGroupsFilePath)
endif

clean:
	rm -rf "$(dataDirectoryPath)"
	rm -rf "$(enclosureDiagramDataDirectoryPath)"

clean-repo: validate-common-parameters
	rm -rf "$(repoWorkingDirectoryPath)"
	rm -rf "$(enclosureDiagramRepoDataDirectoryPath)"

clean-repo-results: validate-common-parameters
	rm -rf "$(resultsDirectoryPath)"
	rm -rf "$(enclosureDiagramRepoDataDirectoryPath)"

validate-common-parameters:
ifndef repoUrl
	$(error repoUrl is undefined)
endif

validate-date-range-parameters:
ifndef from
	$(error from is undefined)
endif

ifndef to
	$(error to is undefined)
endif

validate-file-parameter:
ifndef file
	$(error file is undefined)
endif

change-summary: validate-common-parameters $(resultsDirectoryPath) $(fileChangesLogFilePath)
ifdef groups
	$(error change summary report does not support grouping)
endif
	$(maatCommand) -a summary | tee "$(resultsDirectoryPath)/change-summary.csv" | less

hotspots: validate-common-parameters $(hotspotEnclosureDiagramFilePath)
	./scripts/open-enclosure-diagram.sh $(port) "$(makefileDirectoryPath)/$(hotspotEnclosureDiagramFilePath)"

hotspots-table: validate-common-parameters $(resultsDirectoryPath) $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	python maat-scripts/merge/merge_comp_freqs.py "$(changeFrequencyReportFilePath)" "$(linesOfCodeReportFilePath)" | tee "$(resultsDirectoryPath)/hotspots.csv" | less

change-frequency: validate-common-parameters $(changeFrequencyReportFilePath)
	less "$(changeFrequencyReportFilePath)"

sum-of-coupling: validate-common-parameters $(resultsDirectoryPath) $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a soc | tee "$(resultsDirectoryPath)/sum-of-coupling.csv" | less

coupling: validate-common-parameters $(resultsDirectoryPath) $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) | tee "$(resultsDirectoryPath)/coupling.csv" | less

authors: validate-common-parameters $(resultsDirectoryPath) $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a authors | tee "$(resultsDirectoryPath)/authors.csv" | less

main-devs: validate-common-parameters $(resultsDirectoryPath) $(mainDevReportFilePath) $(refactoringMainDevReportFilePath)
	echo "entity,change-type,main-dev,changed,total-changed,ownership\n$$( echo "$$(tail +2 "$(mainDevReportFilePath)" | sed 's/,/,added,/')\n$$(tail +2 "$(refactoringMainDevReportFilePath)" | sed 's/,/,removed,/')" | sort )" | tee $(resultsDirectoryPath)/main-devs.csv | less

entity-ownership: validate-common-parameters $(resultsDirectoryPath) $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a entity-ownership | tee "$(resultsDirectoryPath)/entity-ownership.csv" | less

indentation: validate-common-parameters validate-file-parameter reset-repository
	python maat-scripts/miner/complexity_analysis.py "$(repoPath)/$(file)"

indentation-trend: validate-common-parameters validate-date-range-parameters validate-file-parameter $(resultsDirectoryPath) reset-repository
	cd "$(repoPath)" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell $(gitLogCommand) --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell $(gitLogCommand) --before=$(to) --pretty=format:%h -1) --file "$(file)" | tee "$(makefileDirectoryPath)/$(resultsDirectoryPath)/indentation-trend.csv" | less

$(mainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a main-dev > "$@"

$(refactoringMainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a refactoring-main-dev > "$@"

$(hotspotEnclosureDiagramFilePath): $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	python "$(makefileDirectoryPath)/maat-scripts/transform/csv_as_enclosure_json.py" --structure "$(linesOfCodeReportFilePath)" --weights "$(changeFrequencyReportFilePath)" > "$@"

$(changeFrequencyReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a revisions > "$@"

$(linesOfCodeReportFilePath): | validate-common-parameters reset-repository
ifndef to
	$(error to is undefined)
endif

ifndef langs
	$(error langs is undefined)
endif

ifndef excludeDirs
	$(error excludeDirs is undefined)
endif

	mkdir -p "$(@D)"

# TODO: Reduce duplication
ifdef groups
	# TODO: Support git hash checkout
	./scripts/cloc-for-groups.sh "$(repoPath)" "$(shell $(gitLogCommand) --before=$(to) --pretty=format:%h -1)" "$(langs)" "${groups}" > "$(makefileDirectoryPath)/$@"
else
	cd "$(repoPath)" && git reset --hard $(shell $(gitLogCommand) --before=$(to) --pretty=format:%h -1) && cloc ./ --by-file --csv --quiet --include-lang="$(langs)" --fullpath --not-match-d="$(excludeDirs)" > "$(makefileDirectoryPath)/$@"
endif

$(maatGroupsFilePath): | validate-common-parameters
ifdef groups
	mkdir -p "$(@D)"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"
endif

$(fileChangesLogFilePath): | validate-common-parameters validate-date-range-parameters reset-repository
	mkdir -p "$(@D)"
	$(gitLogCommand) --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"

$(resultsDirectoryPath): | validate-common-parameters
	mkdir -p "$@"

reset-repository: $(repoPath) | validate-common-parameters
	cd "$(repoPath)" && git reset --hard HEAD && git checkout master || git checkout main && git reset --hard origin/master || git reset --hard origin/main && git clean -fdx

$(repoPath): | validate-common-parameters
	rm -rf "$(repoPath)"
	git clone $(repoUrl) "$(repoPath)"