import json
from typing import List, Dict, Tuple
from firebase_functions import https_fn, scheduler_fn
from google.cloud import firestore, storage
import firebase_admin

# Initialize Admin SDK if not already initialized
try:
	firebase_admin.get_app()
except ValueError:
	firebase_admin.initialize_app()


# ---------- Solver validation (mirrors client logic) ----------

def _build_counts(guess_feedback: List[Tuple[str, str]]) -> Tuple[Dict[str, int], Dict[str, int]]:
	correct_counts: Dict[str, int] = {}
	present_counts: Dict[str, int] = {}
	for letter, fb in guess_feedback:
		correct_counts.setdefault(letter, 0)
		present_counts.setdefault(letter, 0)
		if fb == 'g':
			correct_counts[letter] += 1
		elif fb == 'y':
			present_counts[letter] += 1
	return correct_counts, present_counts


def _validate_word_against_one_guess(candidate: str, guess_feedback: List[Tuple[str, str]]) -> Tuple[bool, str | None]:
	correct_counts, present_counts = _build_counts(guess_feedback)
	word_letter_counts: Dict[str, int] = {}
	for letter, _ in guess_feedback:
		if letter not in word_letter_counts:
			word_letter_counts[letter] = candidate.count(letter)
	for idx, (letter, fb) in enumerate(guess_feedback):
		if fb == 'g':
			if candidate[idx] != letter:
				return False, f"must have {letter} at position {idx+1}"
			if word_letter_counts.get(letter, 0) < correct_counts.get(letter, 0):
				return False, f"insufficient count of {letter} for green requirements"
		elif fb == 'y':
			if letter not in candidate:
				return False, f"does not contain letter {letter}"
			if candidate[idx] == letter:
				return False, f"yellow {letter} cannot be at position {idx+1}"
			if word_letter_counts.get(letter, 0) <= correct_counts.get(letter, 0):
				return False, f"requires more occurrences of {letter}"
		elif fb == 'b':
			if letter in candidate and word_letter_counts.get(letter, 0) > (correct_counts.get(letter, 0) + present_counts.get(letter, 0)):
				return False, f"exceeds allowed count of letter {letter}"
	return True, None


def is_word_possible(candidate: str, history: List[Dict[str, str]]) -> Tuple[bool, List[str]]:
	reasons: List[str] = []
	for entry in history:
		guess = (entry.get('guess') or '').lower()
		fb = (entry.get('feedback') or '').lower()
		if not guess or not fb or len(guess) != len(candidate) or len(fb) != len(candidate):
			return False, ["invalid history entry"]
		guess_feedback = [(guess[i], fb[i]) for i in range(len(guess))]
		ok, reason = _validate_word_against_one_guess(candidate, guess_feedback)
		if not ok:
			if reason:
				reasons.append(reason)
			return False, reasons
	return True, reasons


# ---------- Firestore + Storage helpers ----------

def _load_dictionary_words(bucket_name: str, dictionary_path: str) -> List[str]:
	client = storage.Client()
	bucket = client.bucket(bucket_name)
	blob = bucket.blob(dictionary_path)
	data = blob.download_as_text()
	words = json.loads(data)
	return [str(w).lower() for w in words]


def _write_dictionary(bucket_name: str, dictionary_path: str, words: List[str]) -> None:
	client = storage.Client()
	bucket = client.bucket(bucket_name)
	blob = bucket.blob(dictionary_path)
	blob.upload_from_string(json.dumps(words, ensure_ascii=False), content_type='application/json')
	blob.cache_control = 'public, max-age=3600'
	blob.patch()


def _pending_submissions(db: firestore.Client) -> List[Tuple[str, Dict]]:
	pending: List[Tuple[str, Dict]] = []
	# Primary path: /dictionary/submissions/items/{doc}
	for doc in db.collection('dictionary').document('submissions').collection('items').list_documents():
		data = doc.get().to_dict() or {}
		if data.get('status') == 'pending':
			pending.append((doc.id, data))
	# Fallback path: /dictionary/submissions/{doc}
	for doc in db.collection('dictionary').collection('submissions').list_documents():
		data = doc.get().to_dict() or {}
		if data.get('status') == 'pending':
			pending.append((doc.id, data))
	return pending


@https_fn.on_request()
def validate_and_publish(req: https_fn.Request) -> https_fn.Response:
	db = firestore.Client()
	project_id = firebase_admin.get_app().project_id
	bucket_name = f"{project_id}.appspot.com"
	processed = {"approved": 0, "rejected": 0}
	for doc_id, sub in _pending_submissions(db):
		try:
			word = str(sub.get('word', '')).lower()
			word_length = int(sub.get('wordLength') or len(word))
			feedback_history = sub.get('feedbackHistory') or []
			if len(word) != word_length or not word.isalpha():
				db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
					"status": "rejected",
					"reasons": ["invalid word format or length"],
				})
				processed["rejected"] += 1
				continue
			ok, reasons = is_word_possible(word, feedback_history)
			if not ok:
				db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
					"status": "rejected",
					"reasons": reasons or ["does not satisfy feedback history"],
				})
				processed["rejected"] += 1
				continue
			dictionary_name = str(sub.get('dictionary') or 'english.json')
			dict_path = f"dictionaries/{dictionary_name}"
			words = _load_dictionary_words(bucket_name, dict_path)
			if word not in words:
				words.append(word)
				words = sorted(list(set(words)))
				_write_dictionary(bucket_name, dict_path, words)
			db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
				"status": "approved",
				"reasons": [],
			})
			processed["approved"] += 1
		except Exception as e:
			db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
				"status": "rejected",
				"reasons": [f"server error: {e}"],
			})
			processed["rejected"] += 1
	return https_fn.Response(json.dumps({"processed": processed}), mimetype='application/json')


@scheduler_fn.on_schedule(schedule="every 6 hours")
def scheduled_publish(event: scheduler_fn.ScheduledEvent) -> None:
	db = firestore.Client()
	project_id = firebase_admin.get_app().project_id
	bucket_name = f"{project_id}.appspot.com"
	for doc_id, sub in _pending_submissions(db):
		try:
			word = str(sub.get('word', '')).lower()
			word_length = int(sub.get('wordLength') or len(word))
			feedback_history = sub.get('feedbackHistory') or []
			if len(word) != word_length or not word.isalpha():
				db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
					"status": "rejected",
					"reasons": ["invalid word format or length"],
				})
				continue
			ok, reasons = is_word_possible(word, feedback_history)
			if not ok:
				db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
					"status": "rejected",
					"reasons": reasons or ["does not satisfy feedback history"],
				})
				continue
			dictionary_name = str(sub.get('dictionary') or 'english.json')
			dict_path = f"dictionaries/{dictionary_name}"
			words = _load_dictionary_words(bucket_name, dict_path)
			if word not in words:
				words.append(word)
				words = sorted(list(set(words)))
				_write_dictionary(bucket_name, dict_path, words)
			db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
				"status": "approved",
				"reasons": [],
			})
		except Exception as e:
			db.collection('dictionary').document('submissions').collection('items').document(doc_id).update({
				"status": "rejected",
				"reasons": [f"server error: {e}"],
			})
