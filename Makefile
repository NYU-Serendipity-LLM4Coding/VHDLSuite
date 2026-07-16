install-vunit:
	pip install vunit_hdl psutil openai tqdm

TIMESTAMP_FILE := VERSION.txt

update:
	@date '+%Y-%m-%d %H:%M:%S' > $(TIMESTAMP_FILE)
	@echo "Version updated at:"
	@cat $(TIMESTAMP_FILE)
	git add .
	git commit -m "update @ $$(cat $(TIMESTAMP_FILE))"
	git push