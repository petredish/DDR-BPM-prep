parse: check_songs songs courses
	$(info ################################################################################)
	$(info # Once finished, run `make load` to inspect the variable `songs`)
	$(info ################################################################################)

songs:
	poetry run python $(SRC_DIR)/parse_simfiles.py

courses:
	poetry run python $(SRC_DIR)/parse_courses.py

# check for duplicates, missing songs, etc.
check_songs:
    # fix clean
	$(info ################################################################################)
	$(info # 1. Make sure all_songs.txt has ending new line)
	$(info # 2. Make sure you ran a full scrape: make full_scrape)
	$(info ################################################################################)
	poetry run python $(SRC_DIR)/check_songs.py

# load data & write
write:
	poetry run python $(SRC_DIR)/parse_simfiles.py -l -w

# load data to inspect
load:
	poetry run python $(SRC_DIR)/parse_simfiles.py -l -i

# perform various file fixes
fix:
	bash $(PROJ_DIR)/scripts/parse/fix.sh

generate_dat:
	poetry run python $(SRC_DIR)/generate_dat.py "1st"
	poetry run python $(SRC_DIR)/generate_dat.py "2nd"
	poetry run python $(SRC_DIR)/generate_dat.py "3rd"
	poetry run python $(SRC_DIR)/generate_dat.py "4th"
	poetry run python $(SRC_DIR)/generate_dat.py "5th"
	poetry run python $(SRC_DIR)/generate_dat.py "X"
	poetry run python $(SRC_DIR)/generate_dat.py "X2"
	poetry run python $(SRC_DIR)/generate_dat.py "X3"
	poetry run python $(SRC_DIR)/generate_dat.py "SuperNOVA"
	poetry run python $(SRC_DIR)/generate_dat.py "SuperNOVA2"
	poetry run python $(SRC_DIR)/generate_dat.py "EXTREME"
	poetry run python $(SRC_DIR)/generate_dat.py "MAX"
	poetry run python $(SRC_DIR)/generate_dat.py "MAX2"
	poetry run python $(SRC_DIR)/generate_dat.py "2013"
	poetry run python $(SRC_DIR)/generate_dat.py "2014"
	poetry run python $(SRC_DIR)/generate_dat.py "A"
	poetry run python $(SRC_DIR)/generate_dat.py "A20"
	poetry run python $(SRC_DIR)/generate_dat.py "A20 PLUS"
	poetry run python $(SRC_DIR)/generate_dat.py "A3"
	poetry run python $(SRC_DIR)/generate_dat.py "WORLD"
