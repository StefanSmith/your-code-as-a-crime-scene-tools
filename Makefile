.DELETE_ON_ERROR:

.PHONEY: clean clean-analyses validate-common-parameters validate-date-range-parameters validate-file-parameter change-summary hotspots hotspots-table change-frequency sum-of-coupling coupling authors main-devs entity-ownership indentation indentation-trend fetch-source

port=9000
minRevisions=5
minCoupling=30
minSharedRevisions=5
groupByRepo=false
fullyQualifiedRepoNames=false

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
repositoryUrlsToPathsMappingFile:=$(repositoriesDirectoryPath)/repositoryUrlsToPaths.csv
repositoryDirectoryPaths:=$(shell cut -d',' -f5 "$(repositoryTableFilePath)" | sed -E 's@^@$(repositoriesDirectoryPath)/@')

analysisId:=$(shell { cat "$(repositoryTableFilePath)"; echo "$(groups)"; } | md5sum | cut -d ' ' -f1 )
analysesDirectoryPath=$(dataDirectoryPath)/analyses

fileChangesLogFileName=file-changes-$(from)-$(to).log
repositoryFileChangesLogFilePaths=$(shell scripts/foreach-repository-url.sh 'echo "$(analysesDirectoryPath)/$$(scripts/get-repository-path.sh "{repoUrl}")/$(fileChangesLogFileName)"' "$(repoUrls)")

ifeq ($(crossRepositoryGrouping), true)
clocParameters=$(langs)::::
else
clocParameters=$(langs)::::$(groups)
endif

linesOfCodeReportFileName=lines-of-code-report-$(to)-$(shell echo "$(clocParameters)" | md5sum | cut -d ' ' -f1).csv
repositoryLinesOfCodeReportFilePaths=$(shell scripts/foreach-repository-url.sh 'echo "$(analysesDirectoryPath)/$$(scripts/get-repository-path.sh "{repoUrl}")/$(linesOfCodeReportFileName)"' "$(repoUrls)")

analysisDirectoryPath=$(analysesDirectoryPath)/$(analysisId)
fileChangesLogFilePath=$(analysisDirectoryPath)/$(fileChangesLogFileName)

intermediateAnalysisDirectoryPath=$(analysisDirectoryPath)/intermediate
linesOfCodeReportFilePath=$(intermediateAnalysisDirectoryPath)/lines-of-code-report.csv
changeFrequencyReportFilePath=$(intermediateAnalysisDirectoryPath)/change-frequency-report.csv
mainDevReportFilePath=$(intermediateAnalysisDirectoryPath)/main-dev.csv
refactoringMainDevReportFilePath=$(intermediateAnalysisDirectoryPath)/refactoring-main-dev.csv
maatGroupsFilePath=$(intermediateAnalysisDirectoryPath)/maat-groups.txt
hotspotEnclosureDiagramFilePath=$(analysisDirectoryPath)/hotspot-enclosure-diagram.html

enclosureDiagramDataDirectoryPath=enclosure-diagram/data
enclosureDiagramRepoDataDirectoryPath=$(enclosureDiagramDataDirectoryPath)/$(analysisId)

.INTERMEDIATE: $(changeFrequencyReportFilePath) \
	$(linesOfCodeReportFilePath) \
	$(mainDevReportFilePath) \
	$(refactoringMainDevReportFilePath) \
	$(maatGroupsFilePath) \
	$(repositoryUrlsToPathsMappingFile)

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

maatCommand=scripts/redirect-stdout-to-stderr-on-failure.sh maat -l "$(fileChangesLogFilePath)" -c git2

ifdef groups
	maatCommand:=$(maatCommand) -g $(maatGroupsFilePath)
endif

usage:
	@echo No recipe selected. Please see the README for details.

clean:
	rm -rf "$(analysesDirectoryPath)"
	rm -rf "$(enclosureDiagramDataDirectoryPath)"

clean-all: clean
	rm -rf "$(dataDirectoryPath)"

validate-common-parameters:
ifeq ($(or $(repoUrls),$(repoUrlsFile)),)
	# all arguments evaluated to empty strings
	$(error neither repoUrls nor repoUrlsFile is undefined)
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

fetch-source: validate-common-parameters $(repositoryDirectoryPaths)

change-summary: validate-common-parameters $(fileChangesLogFilePath)
ifdef groups
	$(error change summary report does not support grouping)
endif
	$(maatCommand) -a summary | tee "$(analysisDirectoryPath)/change-summary.csv" | less

hotspots: validate-common-parameters $(hotspotEnclosureDiagramFilePath)
	open "$(makefileDirectoryPath)/$(hotspotEnclosureDiagramFilePath)"

hotspots-table: validate-common-parameters $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath)
	python maat-scripts/merge/merge_comp_freqs.py "$(changeFrequencyReportFilePath)" "$(linesOfCodeReportFilePath)" | tee "$(analysisDirectoryPath)/hotspots.csv" | less

change-frequency: validate-common-parameters $(changeFrequencyReportFilePath)
	less "$(changeFrequencyReportFilePath)"

sum-of-coupling: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a soc | tee "$(analysisDirectoryPath)/sum-of-coupling.csv" | less

ifdef couplingDays
maatCouplingTemporalPeriodOption=--temporal-period $(couplingDays)
endif

coupling: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) $(maatCouplingTemporalPeriodOption) | tee "$(analysisDirectoryPath)/coupling.csv" | less

authors: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a authors | tee "$(analysisDirectoryPath)/authors.csv" | less

main-devs: validate-common-parameters $(mainDevReportFilePath) $(refactoringMainDevReportFilePath)
	echo "entity,change-type,main-dev,changed,total-changed,ownership\n$$( echo "$$(tail +2 "$(mainDevReportFilePath)" | sed 's/,/,added,/')\n$$(tail +2 "$(refactoringMainDevReportFilePath)" | sed 's/,/,removed,/')" | sort )" | tee $(analysisDirectoryPath)/main-devs.csv | less

entity-ownership: validate-common-parameters $(maatGroupsFilePath) $(fileChangesLogFilePath)
	$(maatCommand) -a entity-ownership | tee "$(analysisDirectoryPath)/entity-ownership.csv" | less

indentation: validate-common-parameters validate-file-parameter $(repositoryDirectoryPaths)
ifneq ($(numberOfRepositories),"1")
	$(error only one repository can be specified for this operation)
endif
	scripts/checkout-repository-on-mainline.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)"
	python maat-scripts/miner/complexity_analysis.py "$(repositoryDirectoryPaths)/$(file)"

indentation-trend: validate-common-parameters validate-date-range-parameters validate-file-parameter $(repositoryDirectoryPaths)
ifneq ($(numberOfRepositories),"1")
	$(error only one repository can be specified for this operation)
endif
	cd "$(repositoryDirectoryPaths)" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell git -C "$(repositoryDirectoryPaths)" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)")" --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell git -C "$(repositoryDirectoryPaths)" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoryDirectoryPaths)")" --before=$(to) --pretty=format:%h -1) --file "$(file)" | tee "$(makefileDirectoryPath)/$(analysisDirectoryPath)/indentation-trend.csv" | less

$(mainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a main-dev > "$@"

$(refactoringMainDevReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a refactoring-main-dev > "$@"

$(hotspotEnclosureDiagramFilePath): $(changeFrequencyReportFilePath) $(linesOfCodeReportFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	scripts/generate-hotspot-enclosure-diagram.sh "$(linesOfCodeReportFilePath)" "$(changeFrequencyReportFilePath)" > "$@"

$(changeFrequencyReportFilePath): $(maatGroupsFilePath) $(fileChangesLogFilePath) | validate-common-parameters
	mkdir -p "$(@D)"
	$(maatCommand) -a revisions > "$@"

$(linesOfCodeReportFilePath): $(repositoryLinesOfCodeReportFilePaths) | validate-common-parameters
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

$(maatGroupsFilePath): | validate-common-parameters
ifdef groups
	mkdir -p "$(@D)"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"
endif

$(fileChangesLogFilePath): $(repositoryFileChangesLogFilePaths) | validate-common-parameters validate-date-range-parameters
	mkdir -p "$(@D)"
	scripts/merge-file-changes.sh "$(repositoryFileChangesLogFilePaths)" "$(analysesDirectoryPath)" "$(fileChangesLogFileName)" > "$@"

$(repositoryFileChangesLogFilePaths): $(analysesDirectoryPath)/%/$(fileChangesLogFileName): | validate-date-range-parameters $(repositoriesDirectoryPath)/%
	mkdir -p "$(@D)"
	git -C "$(repositoriesDirectoryPath)/$*" log "$$(scripts/get-repository-mainline-branch-name.sh "$(makefileDirectoryPath)/$(repositoriesDirectoryPath)/$*")" --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"

$(repositoriesDirectoryPath)/%: | validate-common-parameters $(repositoryUrlsToPathsMappingFile)
	git clone "$$(scripts/pick-repository-url-for-path.sh "$*" "$(makefileDirectoryPath)/$(repositoryUrlsToPathsMappingFile)")" "$@"

$(repositoryUrlsToPathsMappingFile):
	scripts/foreach-repository-url.sh 'echo "$$(scripts/get-repository-path.sh "{repoUrl}"),{repoUrl}"' "$(repoUrls)" > "$@"