
full_scrape: scrape_packs unzip scrape_songs dedupe

scrape_packs:
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1709 WORLD
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1509 A3
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1293 "A20 PLUS"
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1292 A20
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1148 A
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 864 2014
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 845 2013
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 802 X3
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 546 X2
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 295 X
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 77 SuperNOVA2
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 1 SuperNOVA
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 41 EXTREME
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 31 MAX2
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 40 MAX
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 30 5th
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 39 4th
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 38 3rd
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 32 2nd
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_pack.sh 37 1st

# Some songs aren't located in the above packs.
# Download them into one of the folders
scrape_songs:
# 	bash $(PROJ_DIR)/scripts/scrape/zenius_song.sh 7568 2nd # PARANOiA KCET ~clean mix~
	bash $(PROJ_DIR)/scripts/scrape/zenius_song.sh 38006 3rd # LOVE THIS FEELIN'

# Some songs are duplicates
# Delete one version
dedupe:
	bash $(PROJ_DIR)/scripts/scrape/dedupe_song.sh "DYNAMITE RAVE" 3rd
	bash $(PROJ_DIR)/scripts/scrape/dedupe_song.sh "DYNAMITE RAVE (AIR Special)" SuperNOVA2
	bash $(PROJ_DIR)/scripts/scrape/dedupe_song.sh Happy X
	bash $(PROJ_DIR)/scripts/scrape/dedupe_song.sh "ever snow" MAX2
	bash $(PROJ_DIR)/scripts/scrape/dedupe_song.sh "La Bamba" EXTREME

unzip:
	bash $(PROJ_DIR)/scripts/scrape/unzip_pack.sh

check_updates:
# 	bash $(PROJ_DIR)/scripts/scrape/check_updates.sh 1709 WORLD
	bash $(PROJ_DIR)/scripts/scrape/check_updates.sh 32 2nd
	bash $(PROJ_DIR)/scripts/scrape/check_updates.sh 40 MAX
	bash $(PROJ_DIR)/scripts/scrape/check_updates.sh 41 EXTREME

# Per-category scrape (Python alternative to check_updates.sh): compares the
# listed remote "X ago" date against the local .sm mtime directly (no .dat
# needed) and downloads only stale songs. Override SCRAPE_FLAGS for --force,
# --margin-days, --only, etc.
SCRAPE_PY    = poetry run python $(PROJ_DIR)/scripts/scrape/scrape_category.py
SCRAPE_FLAGS ?= --data-dir $(SEED_DIR)
DRY_RUN      ?=

update_songs:
	$(SCRAPE_PY) 1709 WORLD       $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY) 1509 A3          $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY) 1293 "A20 PLUS"  $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY) 1292 A20         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY) 1148 A           $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)  864 2014        $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)  845 2013        $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)  802 X3          $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)  546 X2          $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)  295 X           $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   77 SuperNOVA2  $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)    1 SuperNOVA   $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   41 EXTREME     $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   31 MAX2        $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   40 MAX         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   30 5th         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   39 4th         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   38 3rd         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   32 2nd         $(SCRAPE_FLAGS) $(DRY_RUN)
	$(SCRAPE_PY)   37 1st         $(SCRAPE_FLAGS) $(DRY_RUN)

# Inspect what would be downloaded without touching anything.
update_songs_dry:
	$(MAKE) update_songs DRY_RUN=--dry-run
