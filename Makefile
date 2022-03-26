.PHONEY: clean clean-% %-change-summary %-hotspots %-hotspots-table %-sum-of-coupling %-coupling %-indentation %-indentation-trend
.PRECIOUS: data/%/file-changes-$(from)-$(to).log

makefileDirectoryPath := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

port=9000

minRevisions=5
minCoupling=30
minSharedRevisions=5

clean:
	rm -rf "data"
	rm -rf "enclosure-diagram/data"

clean-%:
	rm -rf "data/$*"
	rm -rf "enclosure-diagram/data/$*"

%-change-summary: data/%/file-changes-$(from)-$(to).log
	maat -l "data/$*/file-changes-$(from)-$(to).log" -c git2 -a summary

%-hotspots: enclosure-diagram/data/%/code-file-lines-and-change-frequency.json
	./scripts/open-enclosure-diagram.sh $(port) "data/$*/code-file-lines-and-change-frequency.json"

%-hotspots-table: data/%/change-frequency-report.csv data/%/lines-of-code-report.csv
	python maat-scripts/merge/merge_comp_freqs.py "data/$*/change-frequency-report.csv" "data/$*/lines-of-code-report.csv" | less

%-change-frequency: data/%/change-frequency-report.csv
	less "data/$*/change-frequency-report.csv"

%-sum-of-coupling: data/%/sum-of-coupling.csv
	less "data/$*/sum-of-coupling.csv"

%-coupling: data/%/coupling.csv
	less "data/$*/coupling.csv"

%-indentation:
ifndef file
	$(error file is undefined)
endif

	python maat-scripts/miner/complexity_analysis.py "../$*/$(file)"

%-indentation-trend: data/%/indentation-trend.csv
	less "data/$*/indentation-trend.csv"

ifdef groups
data/%/sum-of-coupling.csv: data/%/groups.txt data/%/file-changes-$(from)-$(to).log
	$(eval extraMaatSocArguments = "-g data/$*/groups.txt")
else
data/%/sum-of-coupling.csv: data/%/file-changes-$(from)-$(to).log
endif
	maat -l "data/$*/file-changes-$(from)-$(to).log" -c git2 -a soc $(extraMaatSocArguments) > "$@"

ifdef groups
data/%/coupling.csv: data/%/groups.txt data/%/file-changes-$(from)-$(to).log
	$(eval extraMaatCouplingArguments = "-g data/$*/groups.txt")
else
data/%/coupling.csv: data/%/file-changes-$(from)-$(to).log
endif
	maat -l "data/$*/file-changes-$(from)-$(to).log" -c git2 -a coupling --min-revs $(minRevisions) --min-coupling $(minCoupling) --min-shared-revs $(minSharedRevisions) $(extraMaatCouplingArguments) > "$@"

data/%/groups.txt:
	mkdir -p "data/$*"
	sed 's/; */\n/g' <<< '$(groups)' > "$@"

data/%/indentation-trend.csv:
ifndef from
	$(error from is undefined)
endif

ifndef to
	$(error to is undefined)
endif

ifndef file
	$(error file is undefined)
endif

	mkdir -p "data/$*"
	cd "../$*" && python "$(makefileDirectoryPath)/maat-scripts/miner/git_complexity_trend.py" --start $(shell git --git-dir ../$*/.git log --after=$(from) --pretty=format:%h --reverse | head -1) --end $(shell git --git-dir ../$*/.git log --before=$(to) --pretty=format:%h -1) --file "$(file)" > "$(makefileDirectoryPath)/$@"

enclosure-diagram/data/%/code-file-lines-and-change-frequency.json: data/%/change-frequency-report.csv data/%/lines-of-code-report.csv
	mkdir -p "enclosure-diagram/data/$*"
	cd "../$*" && python "$(makefileDirectoryPath)/maat-scripts/transform/csv_as_enclosure_json.py" --structure "$(makefileDirectoryPath)/data/$*/lines-of-code-report.csv" --weights "$(makefileDirectoryPath)/data/$*/change-frequency-report.csv" > "$(makefileDirectoryPath)/$@"

ifdef groups
data/%/change-frequency-report.csv: data/%/groups.txt data/%/file-changes-$(from)-$(to).log
	$(eval extraMaatRevisionsArguments = "-g data/$*/groups.txt")
else
data/%/change-frequency-report.csv: data/%/file-changes-$(from)-$(to).log
endif
	maat -l "data/$*/file-changes-$(from)-$(to).log" -c git2 -a revisions $(extraMaatRevisionsArguments) > "$@"

data/%/lines-of-code-report.csv:
ifndef langs
	$(error langs is undefined)
endif

ifndef excludeDirs
	$(error excludeDirs is undefined)
endif

	mkdir -p "data/$*"
	cd "../$*" && cloc ./ --by-file --csv --quiet --include-lang="$(langs)" --fullpath --not-match-d="$(excludeDirs)" > "$(makefileDirectoryPath)/$@"

data/%/file-changes-$(from)-$(to).log:
ifndef from
	$(error from is undefined)
endif

ifndef to
	$(error to is undefined)
endif

	mkdir -p "data/$*"
	git --git-dir ../$*/.git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --after="$(from)" --before=="$(to)" > "$@"