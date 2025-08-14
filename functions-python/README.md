# Cloud Functions (Python 3.12)

Python backend for dictionary submissions validation and scheduled publishing.

## Local Setup

```bash
cd functions-python
python -m venv .venv
source .venv/Scripts/activate  # Windows Git Bash
pip install -U pip
pip install -r requirements.txt
```

## Deploy

```bash
firebase deploy --only functions --project wordle-solver-kyle
```


