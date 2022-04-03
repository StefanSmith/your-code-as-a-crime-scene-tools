port=9000
minRevisions=5
minCoupling=30
minSharedRevisions=5

repoName=$(shell md5sum <<< "$(repoUrl)" | cut -d' ' -f1)
dataDirectoryPath=data

repositoriesDirectoryPath=data/repositories

analysesDirectoryPath=data/analyses
analysisDirectoryPath=$(analysesDirectoryPath)/$(shell sed 's/ *; */\n/g' <<< "$(repoUrl)" | sort | md5sum | cut -d ' ' -f1)

fileChangesLogFileName=file-changes-$(from)-$(to).log
fileChangesLogFilePaths=$(shell sed 's/ *; */\n/g' <<< "$(repoUrl)" | sort | xargs -I {} bash -c 'echo "$(analysesDirectoryPath)/$$(scripts/get-repository-path.sh "{}")/$(fileChangesLogFileName)"')

linesOfCodeReportFileName=lines-of-code-report.csv
linesOfCodeReportFilePaths=$(shell sed 's/ *; */\n/g' <<< "$(repoUrl)" | sort | xargs -I {} bash -c 'echo "$(analysesDirectoryPath)/$$(scripts/get-repository-path.sh "{}")/$(linesOfCodeReportFileName)"')

repositoryDirectoryPaths=$(shell sed 's/ *; */\n/g' <<< "$(repoUrl)" | sort | xargs -I {} bash -c 'echo "$(repositoriesDirectoryPath)/$$(scripts/get-repository-path.sh "{}")"')

.PHONEY: clean clean-repo clean-repo-results validate-common-parameters validate-date-range-parameters validate-file-parameter change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership indentation indentation-trend reset-repository

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
repoWorkingDirectoryPath=$(dataDirectoryPath)/$(repoName)
repoPath=$(repoWorkingDirectoryPath)/repository
resultsDirectoryPath=$(repoWorkingDirectoryPath)/analysis-results
enclosureDiagramDataDirectoryPath=enclosure-diagram/data
enclosureDiagramRepoDataDirectoryPath=$(enclosureDiagramDataDirectoryPath)/$(repoName)
hotspotEnclosureDiagramFilePath=$(enclosureDiagramRepoDataDirectoryPath)/hotspot-enclosure-diagram-data.json
fileChangesLogFilePath=$(analysisDirectoryPath)/$(fileChangesLogFileName)
changeFrequencyReportFilePath=$(analysisDirectoryPath)/change-frequency-report.csv
linesOfCodeReportFilePath=$(analysisDirectoryPath)/$(linesOfCodeReportFileName)
mainDevReportFilePath=$(resultsDirectoryPath)/main-dev.csv
refactoringMainDevReportFilePath=$(resultsDirectoryPath)/refactoring-main-dev.csv
maatGroupsFilePath=$(resultsDirectoryPath)/maat-groups.txt

.INTERMEDIATE: $(changeFrequencyReportFilePath) \
	$(linesOfCodeReportFilePath) \
	$(linesOfCodeReportFilePaths) \
	$(hotspotEnclosureDiagramFilePath) \
	$(mainDevReportFilePath) \
	$(refactoringMainDevReportFilePath) \
	$(maatGroupsFilePath) \
	$(fileChangesLogFilePath)

gitLogCommand=git -C "$(repoPath)" log
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


ifdef repoUrl
numberOfRepositories="$(shell tr ';' '\n' <<< "${repoUrl}" | grep -E -v "^ *$$" | wc -l | xargs)"
ifneq ($(numberOfRepositories), 1)
ifdef groups
crossRepositoryGrouping="true"
endif
endif
endif

ifdef crossRepositoryGrouping
$(linesOfCodeReportFilePath): $(repositoryDirectoryPaths) | validate-common-parameters
else
$(linesOfCodeReportFilePath): $(linesOfCodeReportFilePaths) | validate-common-parameters
endif
	mkdir -p "$(@D)"
ifdef crossRepositoryGrouping
	scripts/checkout-repositories-at-date.sh "$(to)" "$(repositoryDirectoryPaths)"
	scripts/cloc-for-groups.sh "$(repositoriesDirectoryPath)" "$(langs)" "${groups}" > "$@"
else
	scripts/merge-lines-of-code-reports.sh "$(linesOfCodeReportFilePaths)" "$(analysesDirectoryPath)" "$(linesOfCodeReportFileName)" > "$@"
endif

$(linesOfCodeReportFilePaths): $(analysesDirectoryPath)/%/$(linesOfCodeReportFileName): $(repositoriesDirectoryPath)/%
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
	scripts/checkout-repository-at-date.sh "$(to)" "$(makefileDirectoryPath)/$(repositoriesDirectoryPath)/%"

# TODO: Reduce duplication
ifdef groups
	./scripts/cloc-for-groups.sh "$(repositoriesDirectoryPath)/$*" "$(langs)" "${groups}" > "$(makefileDirectoryPath)/$@"
else
	cd "$(repositoriesDirectoryPath)/$*" && cloc ./ --by-file --csv --quiet --include-lang="$(langs)" --fullpath --not-match-d="$(excludeDirs)" > "$(makefileDirectoryPath)/$@"
endif

$(maatGroupsFilePath): | validate-common-parameters
ifdef groups
	mkdir -p "$(@D)"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"
endif

$(fileChangesLogFilePath): $(fileChangesLogFilePaths) | validate-common-parameters validate-date-range-parameters
	mkdir -p "$(@D)"
	scripts/merge-file-changes.sh "$(fileChangesLogFilePaths)" "$(analysesDirectoryPath)" "$(fileChangesLogFileName)" > "$@"

$(fileChangesLogFilePaths): $(analysesDirectoryPath)/%/$(fileChangesLogFileName): | $(repositoriesDirectoryPath)/%
	git -C "$(repositoriesDirectoryPath)/$*" reset --hard origin/master || git -C "$(repositoriesDirectoryPath)/$*" reset --hard origin/main && git -C "$(repositoriesDirectoryPath)/$*" clean -fdx
	mkdir -p "$(@D)"
	git -C "$(repositoriesDirectoryPath)/$*" log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"

$(repositoriesDirectoryPath)/%: | validate-common-parameters
	git clone "$$(scripts/pick-repository-url-for-path.sh "$(repoUrl)" "$*")" "$@"

$(resultsDirectoryPath): | validate-common-parameters
	mkdir -p "$@"

reset-repository: $(repoPath) | validate-common-parameters
	cd "$(repoPath)" && git reset --hard HEAD && git checkout master || git checkout main && git reset --hard origin/master || git reset --hard origin/main && git clean -fdx

$(repoPath): | validate-common-parameters
	rm -rf "$(repoPath)"
	git clone $(repoUrl) "$(repoPath)"