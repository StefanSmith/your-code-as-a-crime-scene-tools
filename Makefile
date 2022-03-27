.PHONEY: clean clean-repo change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership indentation indentation-trend

repoPath=../$(repo)
repoDataPath=data/$(repo)
enclosureDiagramRepoDataPath=enclosure-diagram/$(repoDataPath)
fileChangesLogFilePath=$(repoDataPath)/file-changes-$(from)-$(to).log
changeFrequencyReportFilePath=$(repoDataPath)/change-frequency-report.csv
linesOfCodeReportFilePath=$(repoDataPath)/lines-of-code-report.csv
hotspotEnclosureDiagramFilePath=$(enclosureDiagramRepoDataPath)/hotspot-enclosure-diagram-data.json
sumOfCouplingReportFilePath=$(repoDataPath)/sum-of-coupling.csv
couplingReportFilePath=$(repoDataPath)/coupling.csv
authorsReportFilePath=$(repoDataPath)/authors.csv
mainDevsReportFilePath=$(repoDataPath)/main-devs.csv
refactoringMainDevsReportFilePath=$(repoDataPath)/refactoring-main-devs.csv
entityOwnershipReportFilePath=$(repoDataPath)/entity-ownership.csv
indentationTrendReportFilePath=$(repoDataPath)/indentation-trend.csv
maatGroupsFilePath=$(repoDataPath)/maat-groups.txt

.INTERMEDIATE: $(changeFrequencyReportFilePath) \
	$(linesOfCodeReportFilePath) \
	$(hotspotEnclosureDiagramFilePath) \
	$(sumOfCouplingReportFilePath) \
	$(couplingReportFilePath) \
	$(authorsReportFilePath) \
	$(mainDevsReportFilePath) \
	$(refactoringMainDevsReportFilePath) \
	$(entityOwnershipReportFilePath) \
	$(indentationTrendReportFilePath) \
	$(maatGroupsFilePath)

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

port=9000

minRevisions=5
minCoupling=30
minSharedRevisions=5

clean:
	rm -rf "data"
	rm -rf "enclosure-diagram/data"

clean-repo: validate-common-parameters
	rm -rf "$(repoDataPath)"
	rm -rf "$(enclosureDiagramRepoDataPath)"

validate-common-parameters:
ifndef repo
	$(error repo is undefined)
endif

change-summary: validate-common-parameters $(fileChangesLogFilePath)
	maat -l "$(fileChangesLogFilePath)" -c git2 -a summary

hotspots: validate-common-parameters $(hotspotEnclosureDiagramFilePath)
	./scripts/open-enclosure-diagram.sh $(port) "$(makefileDirectoryPath)/$(hotspotEnclosureDiagramFilePath)"

hotspots-table: validate-common-parameters $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	python maat-scripts/merge/merge_comp_freqs.py "$(changeFrequencyReportFilePath)" "$(linesOfCodeReportFilePath)" | less

change-frequency: validate-common-parameters $(changeFrequencyReportFilePath)
	less "$(changeFrequencyReportFilePath)"

sum-of-coupling: validate-common-parameters $(sumOfCouplingReportFilePath)
	less "$(sumOfCouplingReportFilePath)"

coupling: validate-common-parameters $(couplingReportFilePath)
	less "$(couplingReportFilePath)"

authors: validate-common-parameters $(authorsReportFilePath)
	less "$(authorsReportFilePath)"

main-devs: validate-common-parameters $(mainDevsReportFilePath) $(refactoringMainDevsReportFilePath)
	echo "entity,change-type,main-dev,changed,total-changed,ownership\n$$( echo "$$(tail +2 "$(mainDevsReportFilePath)" | sed 's/,/,added,/')\n$$(tail +2 "$(refactoringMainDevsReportFilePath)" | sed 's/,/,removed,/')" | sort )"

entity-ownership: validate-common-parameters $(entityOwnershipReportFilePath)
	less "$(entityOwnershipReportFilePath)"

indentation: validate-common-parameters
ifndef file
	$(error file is undefined)
endif

	python maat-scripts/miner/complexity_analysis.py "$(repoPath)/$(file)"

indentation-trend: validate-common-parameters $(indentationTrendReportFilePath)
	less "$(indentationTrendReportFilePath)"

ifdef groups
$(sumOfCouplingReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatSocArguments = "-g $(maatGroupsFilePath)")
else
$(sumOfCouplingReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a soc $(extraMaatSocArguments) > "$@"

ifdef groups
$(couplingReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatCouplingArguments = "-g $(maatGroupsFilePath)")
else
$(couplingReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) $(extraMaatCouplingArguments) > "$@"

ifdef groups
$(authorsReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatAuthorsArguments = "-g $(maatGroupsFilePath)")
else
$(authorsReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a authors $(extraMaatAuthorsArguments) > "$@"

$(maatGroupsFilePath):
	mkdir -p "$(repoDataPath)"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"

ifdef groups
$(mainDevsReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatMainDevArguments = "-g $(maatGroupsFilePath)")
else
$(mainDevsReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a main-dev $(extraMaatMainDevArguments) > "$@"

ifdef groups
$(refactoringMainDevsReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatRefactoringMainDevArguments = "-g $(maatGroupsFilePath)")
else
$(refactoringMainDevsReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a refactoring-main-dev $(extraMaatRefactoringMainDevArguments) > "$@"

ifdef groups
$(entityOwnershipReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatEntityOwnershipArguments = "-g $(maatGroupsFilePath)")
else
$(entityOwnershipReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a entity-ownership $(extraMaatEntityOwnershipArguments) > "$@"

$(indentationTrendReportFilePath):
ifndef from
	$(error from is undefined)
endif

ifndef to
	$(error to is undefined)
endif

ifndef file
	$(error file is undefined)
endif

	mkdir -p "$(repoDataPath)"
	cd "$(repoPath)" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell git --git-dir $(repoPath)/.git log --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell git --git-dir $(repoPath)/.git log --before=$(to) --pretty=format:%h -1) --file "$(file)" > "$(makefileDirectoryPath)/$@"

$(hotspotEnclosureDiagramFilePath): $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	mkdir -p "$(enclosureDiagramRepoDataPath)"
	cd "$(repoPath)" && python "$(makefileDirectoryPath)/maat-scripts/transform/csv_as_enclosure_json.py" --structure "$(makefileDirectoryPath)/$(linesOfCodeReportFilePath)" --weights "$(makefileDirectoryPath)/$(changeFrequencyReportFilePath)" > "$(makefileDirectoryPath)/$@"

ifdef groups
$(changeFrequencyReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(eval extraMaatRevisionsArguments = "-g $(maatGroupsFilePath)")
else
$(changeFrequencyReportFilePath): $(fileChangesLogFilePath)
endif
	maat -l "$(fileChangesLogFilePath)" -c git2 -a revisions $(extraMaatRevisionsArguments) > "$@"

$(linesOfCodeReportFilePath):
ifndef langs
	$(error langs is undefined)
endif

ifndef excludeDirs
	$(error excludeDirs is undefined)
endif

	mkdir -p "$(repoDataPath)"
	cd "$(repoPath)" && cloc ./ --by-file --csv --quiet --include-lang="$(langs)" --fullpath --not-match-d="$(excludeDirs)" > "$(makefileDirectoryPath)/$@"

$(fileChangesLogFilePath):
ifndef from
	$(error from is undefined)
endif

ifndef to
	$(error to is undefined)
endif

	mkdir -p "$(repoDataPath)"
	git --git-dir $(repoPath)/.git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"