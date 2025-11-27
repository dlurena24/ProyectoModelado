VENV_NAME=venv
PYTHON=$(VENV_NAME)/bin/python
PIP=$(VENV_NAME)/bin/pip
SCRIPT=main.py

all: setup run

setup:
	@test -d $(VENV_NAME) || python3 -m venv $(VENV_NAME)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

run:
	$(PYTHON) $(SCRIPT)

clean:
	rm -rf $(VENV_NAME)
