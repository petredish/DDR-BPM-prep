
predeploy:
	bash $(PROJ_DIR)/scripts/deploy/predeploy.sh
	$(MAKE) manifest

predeploy-force: export FORCE=Y
predeploy-force: predeploy

# Build the top-level manifest. Run after predeploy so the songs.zip / jackets.zip exist.
manifest:
	poetry run python $(SRC_DIR)/build_manifest.py
