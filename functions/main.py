# Wordle Solver Cloud Functions for Firebase
# Stateless Python implementation of the Wordle solver engine

import json
from collections import Counter
from typing import Dict, List, Tuple, Optional, Any

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, storage

# For cost control and performance optimization
set_global_options(max_instances=10, min_instances=1)

# Initialize Firebase Admin SDK
initialize_app()

# Global in-memory cache for dictionaries (optimization as per architectural plan)
_dictionary_cache: Dict[str, List[str]] = {}


def load_dictionary_from_storage(dictionary_name: str) -> List[str]:
    """
    Load dictionary from Cloud Storage with in-memory caching.

    Args:
        dictionary_name: Name of the dictionary file (e.g., 'english.json')

    Returns:
        List of words from the dictionary

    Raises:
        ValueError: If dictionary not found or invalid format
    """
    # Check cache first (warm start optimization)
    if dictionary_name in _dictionary_cache:
        return _dictionary_cache[dictionary_name]

    try:
        # Download from Cloud Storage (cold start)
        bucket = storage.bucket()
        blob = bucket.blob(f"dictionaries/{dictionary_name}")

        if not blob.exists():
            raise ValueError(f"Dictionary '{dictionary_name}' not found")

        dictionary_data = json.loads(blob.download_as_text())

        if not isinstance(dictionary_data, list):
            raise ValueError(f"Invalid dictionary format for '{dictionary_name}'")

        # Cache for future requests
        _dictionary_cache[dictionary_name] = dictionary_data
        return dictionary_data

    except Exception as e:
        raise ValueError(f"Failed to load dictionary '{dictionary_name}': {str(e)}")


def calculate_letter_frequency(
    word_list: List[str], length: int, prefix: Optional[str] = None
) -> Dict[str, float]:
    """
    Calculate letter frequency for words of specified length and prefix.

    Args:
        word_list: List of words to analyze
        length: Target word length
        prefix: Optional prefix filter

    Returns:
        Dictionary of letter frequencies (percentages)
    """
    # Filter words by length and prefix
    filtered_words = [
        word
        for word in word_list
        if len(word) == length and (prefix is None or word.startswith(prefix))
    ]

    if not filtered_words:
        return {}

    # Remove prefix to calculate frequency on the rest of the word
    if prefix:
        filtered_words = [word[len(prefix) :] for word in filtered_words]

    # Count letter occurrences
    all_letters = "".join(filtered_words)
    frequency = Counter(all_letters)
    total_letters = sum(frequency.values())

    if total_letters == 0:
        return {}

    # Calculate percentage frequency
    percentage_frequency = {
        letter: (count / total_letters) * 100 for letter, count in frequency.items()
    }

    # Sort frequencies in descending order
    return dict(
        sorted(percentage_frequency.items(), key=lambda item: item[1], reverse=True)
    )


def normalize_letter_frequencies(frequencies: Dict[str, float]) -> Dict[str, float]:
    """
    Normalize letter frequencies to a 0-10 scale.

    Args:
        frequencies: Dictionary of letter frequencies

    Returns:
        Dictionary of normalized letter scores (0-10 scale)
    """
    if not frequencies:
        return {}

    max_freq = max(frequencies.values())
    min_freq = min(frequencies.values())

    if max_freq == min_freq:
        return {letter: 5.0 for letter in frequencies}

    return {
        letter: ((value - min_freq) / (max_freq - min_freq)) * 10
        for letter, value in frequencies.items()
    }


def calculate_guess_score(
    word: str, letter_scores: Dict[str, float], guess_count: int = 1
) -> float:
    """
    Calculate score for a word based on letter frequency.

    Args:
        word: Word to score
        letter_scores: Dictionary of letter scores
        guess_count: Current guess number (affects duplicate letter handling)

    Returns:
        Calculated score for the word
    """
    count_duplicates = guess_count > 2

    if count_duplicates:
        return sum(letter_scores.get(letter, 0) for letter in word)
    else:
        return sum(letter_scores.get(letter, 0) for letter in set(word))


def filter_possible_words(
    word_list: List[str], guess_feedback: List[Tuple[str, str]]
) -> List[str]:
    """
    Filter words based on guess feedback (green, yellow, black).

    Args:
        word_list: List of words to filter
        guess_feedback: List of (letter, feedback) tuples where feedback is 'g', 'y', or 'b'

    Returns:
        Filtered list of possible words
    """
    if not guess_feedback:
        return word_list

    # Count feedback for each letter
    correct_letter_counts = {}
    present_letter_counts = {}

    for letter, feedback in guess_feedback:
        if letter not in correct_letter_counts:
            correct_letter_counts[letter] = 0
            present_letter_counts[letter] = 0

        if feedback == "g":
            correct_letter_counts[letter] += 1
        elif feedback == "y":
            present_letter_counts[letter] += 1

    def is_word_possible(word: str) -> bool:
        """Check if a word is possible given the feedback."""
        word_letter_counts = {
            letter: word.count(letter) for letter, _ in guess_feedback
        }

        for i, (letter, feedback) in enumerate(guess_feedback):
            if feedback == "g":  # Green: letter must match at this position
                if (
                    word[i] != letter
                    or word_letter_counts[letter] < correct_letter_counts[letter]
                ):
                    return False
            elif feedback == "y":  # Yellow: letter in word, not at this position
                if (
                    letter not in word
                    or word[i] == letter
                    or word_letter_counts[letter] <= correct_letter_counts[letter]
                ):
                    return False
            elif (
                feedback == "b"
            ):  # Black: letter should not be in word (considering g/y counts)
                if letter in word and word_letter_counts[letter] > (
                    correct_letter_counts[letter] + present_letter_counts[letter]
                ):
                    return False
        return True

    return [word for word in word_list if is_word_possible(word)]


def recommend_guesses(
    word_list: List[str],
    length: int,
    prefix: Optional[str],
    n: int = 9,
    guess_count: int = 1,
    score_base_word_list: Optional[List[str]] = None,
) -> List[Tuple[str, float]]:
    """
    Recommend top n guess words from the word list.

    Args:
        word_list: List of words to recommend from
        length: Target word length
        prefix: Optional prefix filter
        n: Maximum number of recommendations
        guess_count: Current guess number

    Returns:
        List of (word, score) tuples sorted by score descending
    """
    # Filter words by length and prefix
    filtered_words = [
        word
        for word in word_list
        if len(word) == length and (prefix is None or word.startswith(prefix))
    ]

    if not filtered_words:
        return []

    # Calculate letter frequencies and scores
    base = score_base_word_list if score_base_word_list is not None else word_list
    frequencies = calculate_letter_frequency(base, length, prefix)
    letter_scores = normalize_letter_frequencies(frequencies)

    # Score and sort words
    scored_words = [
        (word, calculate_guess_score(word, letter_scores, guess_count))
        for word in filtered_words
    ]

    scored_words.sort(key=lambda x: x[1], reverse=True)
    return scored_words[:n]


def find_variable_letter_positions(word_list: List[str]) -> Dict[int, set]:
    """
    Find positions where letters vary across the word list.

    Args:
        word_list: List of words (same length)

    Returns:
        Dictionary of position -> set of letters at that position
    """
    if not word_list:
        return {}

    word_length = len(word_list[0])
    variable_positions = {i: set() for i in range(word_length)}

    for word in word_list:
        for i, letter in enumerate(word):
            variable_positions[i].add(letter)

    # Filter out positions with no variation
    return {
        pos: letters for pos, letters in variable_positions.items() if len(letters) > 1
    }


@https_fn.on_call()
def calculate_next_move(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    Main Cloud Function: Calculate next move for Wordle solver.

    Expected request data:
    {
        "config": {
            "wordLength": 5,
            "prefix": null,
            "dictionary": "english.json"
        },
        "history": [
            {"guess": "crane", "feedback": "bbbyg"},
            {"guess": "sloth", "feedback": "bybbg"}
        ]
    }

    Returns:
    {
        "recommendations": [{"word": "word", "score": 8.5}, ...],
        "remainingWords": ["word1", "word2", ...],
        "remainingCount": 42,
        "variablePositions": {0: ["a", "b"], 1: ["c", "d"]},
        "fillerSuggestions": ["filler1", "filler2", ...]
    }
    """
    try:
        data = req.data

        # Validate request structure
        if not data or "config" not in data:
            raise ValueError("Missing config in request")

        config = data["config"]
        history = data.get("history", [])

        # Extract configuration
        word_length = config.get("wordLength", 5)
        prefix = config.get("prefix")
        dictionary_name = config.get("dictionary", "english.json")

        # Validate configuration
        if not isinstance(word_length, int) or word_length < 1:
            raise ValueError("Invalid wordLength")

        # Load dictionary
        try:
            dictionary = load_dictionary_from_storage(dictionary_name)
        except ValueError as e:
            return {"error": "DICTIONARY_NOT_FOUND", "message": str(e)}

        # Initialize possible words based on length and prefix
        possible_words = [
            word
            for word in dictionary
            if len(word) == word_length and (prefix is None or word.startswith(prefix))
        ]

        # Apply historical feedback iteratively
        guess_count = len(history) + 1

        for entry in history:
            if "guess" not in entry or "feedback" not in entry:
                raise ValueError("Invalid history entry format")

            guess = entry["guess"].lower()
            feedback = entry["feedback"].lower()

            if len(guess) != word_length or len(feedback) != word_length:
                raise ValueError("Guess and feedback length mismatch")

            if not all(c in "gyb" for c in feedback):
                raise ValueError("Invalid feedback characters")

            # Convert to list of tuples for filtering
            guess_feedback = list(zip(guess, feedback))
            possible_words = filter_possible_words(possible_words, guess_feedback)

        # Generate recommendations strictly from remaining possible words,
        # but compute letter frequency over the full dictionary for better scoring,
        # matching the reference prototype behavior.
        recommendations = recommend_guesses(
            possible_words,
            word_length,
            prefix,
            n=9,
            guess_count=guess_count,
            score_base_word_list=dictionary,
        )

        # Find variable positions for filler word analysis
        variable_positions = find_variable_letter_positions(possible_words)

        # Collect variable letters for filler suggestions
        variable_letters = set().union(*variable_positions.values())

        # Find filler words if we have variable letters
        filler_suggestions = []
        if variable_letters and len(possible_words) > 10:
            # Find words from full dictionary that contain variable letters
            filler_candidates = [
                word
                for word in dictionary
                if len(word) == word_length
                and any(letter in word for letter in variable_letters)
            ]

            # Score filler words by number of variable letters they contain
            scored_fillers = [
                (word, sum(1 for letter in set(variable_letters) if letter in word))
                for word in filler_candidates
            ]
            scored_fillers.sort(key=lambda x: x[1], reverse=True)
            filler_suggestions = [word for word, score in scored_fillers[:9]]

        # Format variable positions for response
        formatted_variable_positions = {
            str(pos): list(letters) for pos, letters in variable_positions.items()
        }

        return {
            "recommendations": [
                {"word": word, "score": round(score, 2)}
                for word, score in recommendations
            ],
            "remainingWords": possible_words[:100],  # Limit for performance
            "remainingCount": len(possible_words),
            "variablePositions": formatted_variable_positions,
            "fillerSuggestions": filler_suggestions,
            "guessCount": guess_count,
        }

    except ValueError as e:
        return {"error": "INVALID_ARGUMENT", "message": str(e)}
    except Exception:
        return {"error": "INTERNAL_ERROR", "message": "An unexpected error occurred"}


@https_fn.on_call()
def health_check(req: https_fn.CallableRequest) -> Dict[str, str]:
    """Simple health check endpoint."""
    return {"status": "healthy", "message": "Wordle Solver API is running"}
