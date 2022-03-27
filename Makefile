.PHONEY: clean clean-repo validate-common-parameters validate-date-range-parameters validate-file-parameter change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership indentation indentation-trend

port=9000
minRevisions=5
minCoupling=30
minSharedRevisions=5

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
dataDirectoryPath=data
repoPath=../$(repo)
repoDataDirectoryPath=$(dataDirectoryPath)/$(repo)
enclosureDiagramDataDirectoryPath=enclosure-diagram/data
enclosureDiagramRepoDataDirectoryPath=$(enclosureDiagramDataDirectoryPath)/$(repo)
hotspotEnclosureDiagramFilePath=$(enclosureDiagramRepoDataDirectoryPath)/hotspot-enclosure-diagram-data.json
fileChangesLogFilePath=$(repoDataDirectoryPath)/file-changes-$(from)-$(to).log
changeFrequencyReportFilePath=$(repoDataDirectoryPath)/change-frequency-report.csv
linesOfCodeReportFilePath=$(repoDataDirectoryPath)/lines-of-code-report.csv
mainDevReportFilePath=$(repoDataDirectoryPath)/main-dev.csv
refactoringMainDevReportFilePath=$(repoDataDirectoryPath)/refactoring-main-dev.csv
maatGroupsFilePath=$(repoDataDirectoryPath)/maat-groups.txt

.INTERMEDIATE: $(changeFrequencyReportFilePath) \
	$(linesOfCodeReportFilePath) \
	$(hotspotEnclosureDiagramFilePath) \
	$(mainDevReportFilePath) \
	$(refactoringMainDevReportFilePath) \
	$(maatGroupsFilePath)

maatCommand=maat -l "$(fileChangesLogFilePath)" -c git2

ifdef groups
	maatCommand:=$(maatCommand) -g $(maatGroupsFilePath)
endif

clean:
	rm -rf "$(dataDirectoryPath)"
	rm -rf "$(enclosureDiagramDataDirectoryPath)"

clean-repo: validate-common-parameters
	rm -rf "$(repoDataDirectoryPath)"
	rm -rf "$(enclosureDiagramRepoDataDirectoryPath)"

validate-common-parameters:
ifndef repo
	$(error repo is undefined)
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

change-summary: validate-common-parameters $(fileChangesLogFilePath)
ifdef groups
	$(error change summary report does not support grouping)
endif
	$(maatCommand) -a summary | tee "$(repoDataDirectoryPath)/change-summary.csv" | less

hotspots: validate-common-parameters $(hotspotEnclosureDiagramFilePath)
	./scripts/open-enclosure-diagram.sh $(port) "$(makefileDirectoryPath)/$(hotspotEnclosureDiagramFilePath)"

hotspots-table: validate-common-parameters $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	python maat-scripts/merge/merge_comp_freqs.py "$(changeFrequencyReportFilePath)" "$(linesOfCodeReportFilePath)" | less

change-frequency: validate-common-parameters $(changeFrequencyReportFilePath)
	less "$(changeFrequencyReportFilePath)"

sum-of-coupling: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a soc | tee "$(repoDataDirectoryPath)/sum-of-coupling.csv" | less

coupling: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) | tee "$(repoDataDirectoryPath)/coupling.csv" | less

authors: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a authors | tee "$(repoDataDirectoryPath)/authors.csv" | less

main-devs: validate-common-parameters $(mainDevReportFilePath) $(refactoringMainDevReportFilePath)
	echo "entity,change-type,main-dev,changed,total-changed,ownership\n$$( echo "$$(tail +2 "$(mainDevReportFilePath)" | sed 's/,/,added,/')\n$$(tail +2 "$(refactoringMainDevReportFilePath)" | sed 's/,/,removed,/')" | sort )" | tee $(repoDataDirectoryPath)/main-devs.csv | less

entity-ownership: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a entity-ownership | tee "$(repoDataDirectoryPath)/entity-ownership.csv" | less

indentation: validate-common-parameters validate-file-parameter
	python maat-scripts/miner/complexity_analysis.py "$(repoPath)/$(file)"

indentation-trend: validate-common-parameters validate-date-range-parameters validate-file-parameter $(indentationTrendReportFilePath) $(repoDataDirectoryPath)
	cd "$(repoPath)" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell git --git-dir $(repoPath)/.git log --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell git --git-dir $(repoPath)/.git log --before=$(to) --pretty=format:%h -1) --file "$(file)" | tee "$(makefileDirectoryPath)/$(repoDataDirectoryPath)/indentation-trend.csv" | less

$(mainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a main-dev > "$@"

$(refactoringMainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a refactoring-main-dev > "$@"

$(hotspotEnclosureDiagramFilePath): $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath) $(enclosureDiagramRepoDataDirectoryPath)
	cd "$(repoPath)" && python "$(makefileDirectoryPath)/maat-scripts/transform/csv_as_enclosure_json.py" --structure "$(makefileDirectoryPath)/$(linesOfCodeReportFilePath)" --weights "$(makefileDirectoryPath)/$(changeFrequencyReportFilePath)" > "$(makefileDirectoryPath)/$@"

$(changeFrequencyReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a revisions > "$@"

$(linesOfCodeReportFilePath): $(repoDataDirectoryPath)
ifndef langs
	$(error langs is undefined)
endif

ifndef excludeDirs
	$(error excludeDirs is undefined)
endif

	cd "$(repoPath)" && cloc ./ --by-file --csv --quiet --include-lang="$(langs)" --fullpath --not-match-d="$(excludeDirs)" > "$(makefileDirectoryPath)/$@"

$(maatGroupsFilePath): $(repoDataDirectoryPath)
ifdef groups
	sed 's/; */\n/g' <<< '$(groups)' > "$@"
endif

$(fileChangesLogFilePath): validate-date-range-parameters $(repoDataDirectoryPath)
	git --git-dir $(repoPath)/.git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"

$(repoDataDirectoryPath):
	mkdir -p "$(repoDataDirectoryPath)"

$(enclosureDiagramRepoDataDirectoryPath):
	mkdir -p "$(enclosureDiagramRepoDataDirectoryPath)"