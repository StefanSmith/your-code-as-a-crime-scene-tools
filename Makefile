.DELETE_ON_ERROR:

.PHONEY: clean clean-analyses validate-date-range-parameters validate-file-parameter change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership entity-effort indentation indentation-trend fetch-source list-of-authors non-team-authors knowledge-map main-dev-entities fragmentation fragmentation-table communication communication-table file-changes

port=9000
minRevisions=5
minCoupling=30
minSharedRevisions=5
groupByRepo=false
fullyQualifiedRepoNames=false

ifeq (clean,$(filter clean,$(MAKECMDGOALS)))
repoUrls="dummy value to pass validation"
endif

ifeq (clean-all,$(filter clean-all,$(MAKECMDGOALS)))
repoUrls="dummy value to pass validation"
endif

ifeq ($(or $(repoUrls),$(repoUrlsFile)),)
$(error Neither repoUrls nor repoUrlsFile provided. Aborting)
endif

ifdef repoUrlsFile
override repoUrls:=$(shell grep -v '^\#' "$(repoUrlsFile)" | tr '\n' ';')
endif

repositoryTableFilePath:=$(shell scripts/create-repository-table-file.sh "$(repoUrls)")

ifeq ($(groupByRepo), true)
override groups:=$(shell scripts/get-group-per-repository.sh "$(repositoryTableFilePath)" "$(fullyQualifiedRepoNames)")
endif

ifdef repoUrls
numberOfRepositories:=$(shell wc -l "$(repositoryTableFilePath)" | awk '{ print $$1 }')
ifneq ($(numberOfRepositories), 1)
ifdef groups
crossRepositoryGrouping=true
endif
endif
endif

dataDirectoryPath=data
repositoriesDirectoryPath:=$(dataDirectoryPath)/repositories
repositoryDirectoryPaths:=$(shell cut -d',' -f5 "$(repositoryTableFilePath)" | sed -E 's@^@$(repositoriesDirectoryPath)/@')

parametersForAnalysisId:=$(shell echo "$(MAKEOVERRIDES)" | sed -E 's/(authorColors(File)?|mainDev)=([^ ]|\\ )+ ?//' | sed 's/ *$$//')
analysisId:=$(shell { cat "$(repositoryTableFilePath)"; echo "$(parametersForAnalysisId)"; } | md5sum | cut -d ' ' -f1 )
knowledgeMapId:=$(shell echo "$(authorColorsFile)$(authorColors)" | md5sum | cut -d ' ' -f1 )
analysesDirectoryPath:=$(dataDirectoryPath)/analyses

fileChangesLogFileName:=file-changes-$(from)-$(to).log
repositoryFileChangesLogFilePaths:=$(shell cut -d',' -f5 "$(repositoryTableFilePath)" | sed -E 's@(.+)@$(analysesDirectoryPath)/\1/$(fileChangesLogFileName)@')

authorsFileName:=authors-$(from)-$(to).log
repositoryAuthorsFilePaths:=$(shell cut -d',' -f5 "$(repositoryTableFilePath)" | sed -E 's@(.+)@$(analysesDirectoryPath)/\1/$(authorsFileName)@')

clocParameters:=$(langs)::::

ifneq ($(crossRepositoryGrouping), true)
clocParameters:=$(clocParameters)$(groups)
endif

linesOfCodeReportFileName:=lines-of-code-report-$(to)-$(shell echo "$(clocParameters)" | md5sum | cut -d ' ' -f1).csv
repositoryLinesOfCodeReportFilePaths:=$(shell cut -d',' -f5 "$(repositoryTableFilePath)" | sed -E 's@(.+)@$(analysesDirectoryPath)/\1/$(linesOfCodeReportFileName)@')

analysisDirectoryPath:=$(analysesDirectoryPath)/$(analysisId)
fileChangesLogFilePath:=$(analysisDirectoryPath)/$(fileChangesLogFileName)
authorsFilePath:=$(analysisDirectoryPath)/$(authorsFileName)
listOfAuthorsReportFilePath:=$(analysisDirectoryPath)/list-of-authors.csv
linesOfCodeReportFilePath:=$(analysisDirectoryPath)/lines-of-code-report.csv
changeFrequencyReportFilePath:=$(analysisDirectoryPath)/change-frequency-report.csv
entityOwnershipReportFilePath:=$(analysisDirectoryPath)/entity-ownership.csv
entityEffortReportFilePath:=$(analysisDirectoryPath)/entity-effort.csv
mainDevsReportFilePath:=$(analysisDirectoryPath)/main-devs.csv
mainDevReportFilePath:=$(analysisDirectoryPath)/main-dev.csv
refactoringMainDevReportFilePath:=$(analysisDirectoryPath)/refactoring-main-dev.csv
maatGroupsFilePath:=$(analysisDirectoryPath)/maat-groups.txt
hotspotEnclosureDiagramFilePath:=$(analysisDirectoryPath)/hotspot-enclosure-diagram.html
fragmentationEnclosureDiagramFilePath:=$(analysisDirectoryPath)/fragmentation-enclosure-diagram.html
fragmentationReportFilePath:=$(analysisDirectoryPath)/fragmentation-report.csv
communicationDiagramFilePath:=$(analysisDirectoryPath)/communication-diagram.html
communicationReportFilePath:=$(analysisDirectoryPath)/communication-report.csv
knowledgeMapDiagramDirectoryPath:=$(analysisDirectoryPath)/$(knowledgeMapId)
knowledgeMapDiagramFilePath:=$(knowledgeMapDiagramDirectoryPath)/knowledge-map-diagram.html

ifdef authorColorsFile
authorColorsFilePath:=$(authorColorsFile)
else
generateAuthorColorsFile:=true
authorColorsFilePath:=$(knowledgeMapDiagramDirectoryPath)/author-colors.csv
endif

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

maatCommand:=scripts/redirect-stdout-to-stderr-on-failure.sh maat -l "$(fileChangesLogFilePath)" -c git2

ifdef groups
	maatCommand:=$(maatCommand) -g $(maatGroupsFilePath)
endif

ifdef teamMapFile
	maatCommand:=$(maatCommand) --team-map-file "$(teamMapFile)"
endif

ifdef teamMapFile
teamMapFilePath:=$(teamMapFile)
endif

default:
	$(error No target specified)

clean:
	rm -rf "$(analysesDirectoryPath)"

clean-all: clean
	rm -rf "$(dataDirectoryPath)"

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

fetch-source: $(repositoryDirectoryPaths)

list-of-authors: $(listOfAuthorsReportFilePath)
	less $(listOfAuthorsReportFilePath)

non-team-authors: $(authorsFilePath)
ifeq ($(teamMapFile),)
	$(error teamMapFile not specified. Aborting)
endif
	bash -c 'diff <(cat "$(teamMapFile)" | tail +2 | cut -d',' -f1 | sort --ignore-case | uniq) <(cat "$(authorsFilePath)") || echo > /dev/null # Suppress failure' | grep '^>' | cut -d' ' -f2- | less

change-summary: $(fileChangesLogFilePath) $(teamMapFilePath)
ifdef groups
	$(error change summary report does not support grouping)
endif
	$(maatCommand) -a summary | tee "$(analysisDirectoryPath)/change-summary.csv" | less

file-changes: $(fileChangesLogFilePath)
	less "$(fileChangesLogFilePath)"

fragmentation: $(fragmentationEnclosureDiagramFilePath)
	open "$(makefileDirectoryPath)/$(fragmentationEnclosureDiagramFilePath)"

fragmentation-table: $(fragmentationReportFilePath)
	less "$(fragmentationReportFilePath)"

communication: $(communicationDiagramFilePath)
	open "$(makefileDirectoryPath)/$(communicationDiagramFilePath)"

communication-table: $(communicationReportFilePath)
	less "$(communicationReportFilePath)"

hotspots: $(hotspotEnclosureDiagramFilePath)
	open "$(makefileDirectoryPath)/$(hotspotEnclosureDiagramFilePath)"

hotspots-table: $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	python maat-scripts/merge/merge_comp_freqs.py "$(changeFrequencyReportFilePath)" "$(linesOfCodeReportFilePath)" | tee "$(analysisDirectoryPath)/hotspots.csv" | less

knowledge-map: $(knowledgeMapDiagramFilePath)
	open "$(makefileDirectoryPath)/$(knowledgeMapDiagramFilePath)"

change-frequency: $(changeFrequencyReportFilePath)
	less "$(changeFrequencyReportFilePath)"

sum-of-coupling: $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	$(maatCommand) -a soc | tee "$(analysisDirectoryPath)/sum-of-coupling.csv" | less

ifdef couplingDays
maatCouplingTemporalPeriodOption:=--temporal-period $(couplingDays)
endif

coupling: $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	$(maatCommand) -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) $(maatCouplingTemporalPeriodOption) | tee "$(analysisDirectoryPath)/coupling.csv" | less

authors: $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	$(maatCommand) -a authors | tee "$(analysisDirectoryPath)/authors.csv" | less

main-devs: $(mainDevsReportFilePath)
	less "$(mainDevsReportFilePath)"

main-dev-entities: $(mainDevsReportFilePath)
ifndef mainDev
	$(error mainDev not specified. Aborting)
endif
	echo "$$(head -1 "$(mainDevsReportFilePath)" && grep ",$(mainDev)," "$(mainDevsReportFilePath)" | sort -n -r -t, -k6  || printf '')" | tee $(analysisDirectoryPath)/$(mainDev)-entities.csv | less

$(mainDevsReportFilePath): $(mainDevReportFilePath) $(refactoringMainDevReportFilePath)
	echo "entity,change-type,main-dev,changed,total-changed,ownership\n$$( echo "$$(tail +2 "$(mainDevReportFilePath)" | sed 's/,/,added,/')\n$$(tail +2 "$(refactoringMainDevReportFilePath)" | sed 's/,/,removed,/')" | sort )" > "$@"

entity-ownership: $(entityOwnershipReportFilePath)
	less "$(entityOwnershipReportFilePath)"

entity-effort: $(entityEffortReportFilePath)
	less "$(entityEffortReportFilePath)"

indentation: validate-file-parameter $(repositoryDirectoryPaths)
ifneq ($(numberOfRepositories), 1)
	$(error only one repository can be specified for this operation)
endif
	scripts/checkout-repository-on-mainline.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)"
	python maat-scripts/miner/complexity_analysis.py "$(repositoryDirectoryPaths)/$(file)"

indentation-trend: validate-date-range-parameters validate-file-parameter $(repositoryDirectoryPaths)
ifneq ($(numberOfRepositories), 1)
	$(error only one repository can be specified for this operation)
endif
	cd "$(repositoryDirectoryPaths)" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell git -C "$(repositoryDirectoryPaths)" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)")" --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell git -C "$(repositoryDirectoryPaths)" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)")" --before=$(to) --pretty=format:%h -1) --file "$(file)" | tee "$(makefileDirectoryPath)/$(analysisDirectoryPath)/indentation-trend.csv" | less

$(knowledgeMapDiagramFilePath): $(mainDevReportFilePath) $(linesOfCodeReportFilePath) $(authorColorsFilePath)
	mkdir -p "$(@D)"
	scripts/generate-knowledge-map-diagram.sh "$(linesOfCodeReportFilePath)" "$(mainDevReportFilePath)" "$(authorColorsFilePath)" > "$@"

$(communicationDiagramFilePath): $(communicationReportFilePath)
	mkdir -p "$(@D)"
	scripts/generate-communication-diagram.sh "$(communicationReportFilePath)" > "$@"

$(communicationReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	mkdir -p "$(@D)"
	$(maatCommand) -a communication > "$@"

$(authorColorsFilePath):
ifeq ($(generateAuthorColorsFile),true)
ifeq ($(authorColors),)
	$(error Cannot generate author colors file unless authorColors parameter is provided. Aborting)
endif
	mkdir -p "$(@D)"
	echo 'author,color' > "$@"
	tr ';' '\n' <<< "${authorColors}" | sed -E 's/^ +| ?(,) ?| +$$/\1/g' | grep -v "^$$" | sort | uniq >> "$@"
endif

$(entityOwnershipReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	$(maatCommand) -a entity-ownership > "$@"

$(entityEffortReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	$(maatCommand) -a entity-effort > "$@"

$(mainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	mkdir -p "$(@D)"
	$(maatCommand) -a main-dev > "$@"

$(refactoringMainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	mkdir -p "$(@D)"
	$(maatCommand) -a refactoring-main-dev > "$@"

$(fragmentationEnclosureDiagramFilePath): $(fragmentationReportFilePath) $(linesOfCodeReportFilePath)
	mkdir -p "$(@D)"
	scripts/generate-heatmap-enclosure-diagram.sh "$(linesOfCodeReportFilePath)" "$(fragmentationReportFilePath)" > "$@"

$(fragmentationReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	mkdir -p "$(@D)"
	$(maatCommand) -a fragmentation > "$@"

$(hotspotEnclosureDiagramFilePath): $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	mkdir -p "$(@D)"
	scripts/generate-heatmap-enclosure-diagram.sh "$(linesOfCodeReportFilePath)" "$(changeFrequencyReportFilePath)" > "$@"

$(changeFrequencyReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) $(teamMapFilePath)
	mkdir -p "$(@D)"
	$(maatCommand) -a revisions > "$@"

$(linesOfCodeReportFilePath): $(repositoryLinesOfCodeReportFilePaths)
	mkdir -p "$(@D)"
ifeq ($(crossRepositoryGrouping), true)
	scripts/aggregate-lines-of-code-reports.sh "$(repositoryLinesOfCodeReportFilePaths)" "$(analysesDirectoryPath)" "$(linesOfCodeReportFileName)" "$(groups)" > "$@"
else
	scripts/merge-lines-of-code-reports.sh "$(repositoryLinesOfCodeReportFilePaths)" "$(analysesDirectoryPath)" "$(linesOfCodeReportFileName)" > "$@"
endif

$(repositoryLinesOfCodeReportFilePaths): $(analysesDirectoryPath)/%/$(linesOfCodeReportFileName): $(repositoriesDirectoryPath)/%
ifndef to
	$(error to is undefined)
endif

ifndef langs
	$(error langs is undefined)
endif

	mkdir -p "$(@D)"
	scripts/checkout-repository-at-date.sh "$(to)" "$(makefileDirectoryPath)/$(repositoriesDirectoryPath)/$*"
	scripts/cloc.sh "$(repositoriesDirectoryPath)/$*" "$(clocParameters)" > "$@"

$(maatGroupsFilePath):
	mkdir -p "$(@D)"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"

$(fileChangesLogFilePath): $(repositoryFileChangesLogFilePaths) | validate-date-range-parameters
	mkdir -p "$(@D)"
	scripts/merge-file-changes.sh "$(repositoryFileChangesLogFilePaths)" "$(analysesDirectoryPath)" "$(fileChangesLogFileName)" > "$@"

$(repositoryFileChangesLogFilePaths): $(analysesDirectoryPath)/%/$(fileChangesLogFileName): | validate-date-range-parameters $(repositoriesDirectoryPath)/%
	mkdir -p "$(@D)"
	git -C "$(repositoriesDirectoryPath)/$*" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoriesDirectoryPath)/$*")" --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"

$(listOfAuthorsReportFilePath): $(authorsFilePath)
	cat $(authorsFilePath) > "$@"

$(authorsFilePath): $(repositoryAuthorsFilePaths) | validate-date-range-parameters
	mkdir -p "$(@D)"
	cat $(repositoryAuthorsFilePaths) | sort --ignore-case | uniq > "$@"

$(repositoryAuthorsFilePaths): $(analysesDirectoryPath)/%/$(authorsFileName): | validate-date-range-parameters $(repositoriesDirectoryPath)/%
	mkdir -p "$(@D)"
	git -C "$(repositoriesDirectoryPath)/$*" shortlog -s -e "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoriesDirectoryPath)/$*")" --after="$(from)" --before=="$(to)" | cut -f2 | sed -E 's/ <[^>]+>$$//' > "$@"

$(repositoriesDirectoryPath)/%:
	git clone "$(shell grep ',$*$$' "$(repositoryTableFilePath)" | awk -F ',' '{ print $$1 }')" "$@"