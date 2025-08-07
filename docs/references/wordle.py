# -------------------------------------- INSTRUCTIONS ------------------------------------------
# This script helps you solve Wordle puzzles (and similar word games).
#
# **Basic Usage:**
#   - Run the script without any arguments for standard Wordle rules (5-letter words, no prefix):
#     `python wordle.py`
#
# **Customizing Word Length:**
#   - To play with words of a different length, provide the desired length as the first argument:
#     `python wordle.py 7`  (for 7-letter words)
#
# **Using a Prefix (e.g., for Twitch Wordle):**
#   - To find words with a specific prefix, provide the word length first, then the prefix:
#     `python wordle.py 7 p`  (for 7-letter words starting with 'p')
#   - Note: If you want to use a prefix, you must specify the word length.
#
# **Using Different Dictionaries:**
#   - By default, the script uses 'words.json' (English dictionary).
#   - To use a different dictionary, change the `dictionary_filename` variable in the script.
#   - You can use dictionaries in other languages as long as they are in JSON format
#     (a list of words). Example: 'spanish-words.json'.
#     Edit the `dictionary_filename = "words.json"` line in the code to change the dictionary file.
#     Make sure the dictionary file is in the same directory as the script.
#
# ---------------------------------------------------------------------------------------------

import json
import os
import sys
from collections import Counter
import colorama


# --- Configuration ---
dictionary_filename = "words.json" # Filename for the word dictionary (JSON format)
default_word_length = 5            # Default word length if not specified in arguments
word_prefix = None                 # Prefix for words (optional, set by command-line argument)
target_word_length = None          # Word length to use (set by command-line argument or default)


# --- Argument Parsing ---
# Check for prefix argument (must come after word length argument)
if len(sys.argv) > 2:
    word_prefix = sys.argv[2].lower()
    print(f"Using prefix '{word_prefix}'.")

# Check for word length argument
if len(sys.argv) > 1:
    try:
        target_word_length = int(sys.argv[1])
    except ValueError:
        print(
            f"Invalid word length '{sys.argv[1]}'. Using default length {default_word_length}."
        )
        target_word_length = default_word_length
else:
    target_word_length = default_word_length


def load_dictionary(filename):
    """
    Loads words from a JSON file.

    Args:
        filename (str): The name of the JSON file containing the words.

    Returns:
        list: A list of words loaded from the file.
              Exits the script if the file is not found.
    """
    if os.path.exists(filename):
        print(f"Loading words from {filename}...\n")
        with open(filename, "r") as file:
            return json.load(file)
    else:
        sys.exit(f"Error: File '{filename}' not found.")


words = load_dictionary(dictionary_filename)  # Initial list of all possible words
all_words = list(words) # Keep a copy of the full word list for adding new words later

# Filter words based on word length and prefix (if provided)
possible_words = [
    word
    for word in words
    if len(word) == target_word_length and (word_prefix is None or word.startswith(word_prefix))
]

guess_count = 1 # Initialize guess counter


def calculate_letter_frequency(word_list=all_words, length=target_word_length, prefix=word_prefix):
    """
    Calculates the frequency of each letter in the given list of words,
    considering the specified word length and prefix.

    This function is optimized to efficiently determine letter frequencies
    for recommending the best starting words.

    Args:
        word_list (list, optional): List of words to analyze. Defaults to all_words.
        length (int, optional):  Word length to consider. Defaults to target_word_length.
        prefix (str, optional): Prefix to consider. Defaults to word_prefix.

    Returns:
        dict: A dictionary of letter frequencies (percentage), sorted in descending order.
              Keys are letters, values are their frequencies (as percentages).
    """

    # Filter words by length and prefix
    filtered_words = [
        word
        for word in word_list
        if len(word) == length and (prefix is None or word.startswith(prefix))
    ]

    # Remove prefix to calculate frequency on the rest of the word
    if prefix:
        filtered_words = [word[len(prefix) :] for word in filtered_words]

    # Combine all letters into a single string
    all_letters = "".join(filtered_words)

    # Count letter occurrences
    frequency = Counter(all_letters)
    total_letters = sum(frequency.values())

    # Calculate percentage frequency
    percentage_frequency = {
        letter: (count / total_letters) * 100 for letter, count in frequency.items()
    }

    # Sort frequencies in descending order
    sorted_percentage_frequency = dict(
        sorted(percentage_frequency.items(), key=lambda item: item[1], reverse=True)
    )

    return sorted_percentage_frequency


def normalize_letter_frequencies(frequencies=calculate_letter_frequency()):
    """
    Normalizes letter frequencies to a scale of 0 to 10.

    This normalization helps in scoring words based on common letter occurrences.

    Args:
        frequencies (dict, optional): A dictionary of letter frequencies.
                                       Defaults to the result of calculate_letter_frequency().

    Returns:
        dict: A dictionary of normalized letter scores (0-10 scale).
              Keys are letters, values are their normalized scores.
    """
    max_freq = max(frequencies.values())
    min_freq = min(frequencies.values())

    # Normalize frequencies to a 0-10 scale
    normalized_frequencies = {
        letter: ((value - min_freq) / (max_freq - min_freq)) * 10
        for letter, value in frequencies.items()
    }
    return normalized_frequencies


def calculate_guess_score(word, count_duplicates=False, letter_scores=normalize_letter_frequencies()):
    """
    Calculates a score for a word based on letter frequency.

    Higher scores indicate words with more common letters.
    For the first two guesses, duplicate letters in the guess are only counted once.
    From the third guess onwards, all letters are counted (including duplicates).

    Args:
        word (str): The word to score.
        count_duplicates (bool, optional): Whether to count duplicate letters. Defaults to False for first 2 guesses.
        letter_scores (dict, optional): Dictionary of letter scores.
                                        Defaults to the result of normalize_letter_frequencies().

    Returns:
        float: The calculated score for the word.
    """
    if guess_count > 2: # Count duplicates from guess 3 onwards
        count_duplicates = True

    if count_duplicates:
        return sum(letter_scores.get(letter, 0) for letter in word) # Sum scores for all letters
    else:
        return sum(letter_scores.get(letter, 0) for letter in set(word)) # Sum scores for unique letters


def recommend_guesses(word_list, n=9, length=target_word_length, prefix=word_prefix):
    """
    Recommends the top 'n' guess words from the given word list.

    Words are recommended based on their calculated score, prioritizing
    words with common and varied letters.

    Args:
        word_list (list): List of words to recommend from.
        n (int, optional): Maximum number of recommendations. Defaults to 9.
        length (int, optional): Word length to consider. Defaults to target_word_length.
        prefix (str, optional): Prefix to consider. Defaults to word_prefix.


    Returns:
        list: A list of tuples, each containing a recommended word and its score,
              sorted by score in descending order.
              The list contains up to 'n' recommendations.
    """
    n = min(n, len(word_list)) # Limit recommendations to available words

    filtered_words = [
        word
        for word in word_list
        if len(word) == length and (prefix is None or word.startswith(prefix))
    ]

    scored_words = [(word, calculate_guess_score(word)) for word in filtered_words]

    scored_words.sort(key=lambda x: x[1], reverse=True) # Sort by score, highest first

    return scored_words[:n] # Return top n words


def is_valid_guess_format(word):
    """
    Checks if the user's guess input is in a valid format.

    Validates word length, character types (letters only), and ensures
    it's not a feedback string ('gyb' characters).

    Args:
        word (str): The user's guess input.

    Returns:
        bool: True if the guess is valid, False otherwise.
              Prints error messages to the console for invalid inputs.
    """
    if len(word) != target_word_length:
        print(f"\t⚠️  Word length must be {target_word_length} characters ⚠️")
        return False

    if not word.isalpha():
        print("\t⚠️  Guess must contain only letters ⚠️")
        return False

    if all(char in "gyb" for char in word): # Prevent feedback as guess
        print("\t⚠️  Enter a guess word, not feedback (like 'gyb') ⚠️")
        return False

    return True


def get_user_guess_and_feedback():
    """
    Prompts the user for a guess word and then for feedback.

    Provides recommended guesses to the user before prompting for their guess.
    Allows users to choose from recommendations or enter their own guess.
    Also includes an option for filler words (words to uncover new letters).

    Returns:
        list: A list of tuples representing the guess and feedback, like [('g', 'g'), ('u', 'y'), ...].
    """
    recommended_guesses = recommend_guesses(possible_words)
    print("Recommended guesses:")
    for i, (guess, score) in enumerate(recommended_guesses, 1):
        print(f"{i}. {guess} - {round(score, 2)}") # Display recommendations with scores
    print(
        f"\nEnter your guess, or choose 1-{len(recommended_guesses)} from recommendations,"
        " or 0 for filler words:"
    )

    user_guess = ""
    while not user_guess: # Loop until a valid guess is entered
        user_input = input().strip().lower()

        if user_input == "0": # Filler word option
            letters = prompt_filler_letters_input()
            filler_words = find_words_with_letters(all_words, letters) # Use all_words for filler suggestions
            print(f"Filler words for letters '{letters}': {', '.join(filler_words)}")
            continue # Re-prompt for guess after showing filler words

        if user_input.isdigit() and 1 <= int(user_input) <= len(recommended_guesses): # Choose from recommendations
            user_guess = recommended_guesses[int(user_input) - 1][0]
            continue

        if is_valid_guess_format(user_input): # Validate user's manual guess
            user_guess = user_input

    feedback_result = ""
    while not feedback_result: # Loop until valid feedback is entered
        feedback_result = input(f"Enter feedback for your guess '{user_guess}': ").strip().lower()

        if len(feedback_result) != target_word_length:
            print(f"\t⚠️  Feedback must be {target_word_length} characters long ⚠️")
            feedback_result = "" # Re-prompt for feedback

        if not all(char in "gyb" for char in feedback_result): # Validate feedback characters
            print("\t⚠️  Feedback must only contain 'g', 'y', or 'b' ⚠️")
            feedback_result = "" # Re-prompt for feedback

    add_to_guess_dictionary(user_guess, feedback_result) # Add guess and feedback to dictionary

    return list(zip(user_guess, feedback_result)) # Combine guess and feedback into list of tuples


def filter_possible_words(word_list, guess_feedback):
    """
    Filters a list of words based on guess feedback (green, yellow, black).

    This function efficiently narrows down possible words after each guess
    by applying Wordle's feedback rules.

    Args:
        word_list (list): List of words to filter.
        guess_feedback (list): List of tuples, each containing a guessed letter and its feedback ('g', 'y', or 'b').
                                Example: [('d', 'g'), ('r', 'y'), ('i', 'b'), ('e', 'b'), ('d', 'b')]

    Returns:
        list: A filtered list of words that are still possible based on the feedback.
    """
    correct_letter_counts = {letter: 0 for letter, _ in guess_feedback} # Count 'g' feedback for each letter
    present_letter_counts = {letter: 0 for letter, _ in guess_feedback} # Count 'y' feedback for each letter

    # Count 'g' and 'y' feedback for each letter
    for letter, feedback in guess_feedback:
        if feedback == "g":
            correct_letter_counts[letter] += 1
        elif feedback == "y":
            present_letter_counts[letter] += 1

    def is_word_possible(word):
        """Checks if a word is possible given the feedback."""
        word_letter_counts = {letter: word.count(letter) for letter, _ in guess_feedback} # Count letters in the current word

        for i, (letter, feedback) in enumerate(guess_feedback):
            if feedback == "g": # Green feedback: letter must match at this position
                if (
                    word[i] != letter # Position mismatch for green
                    or word_letter_counts[letter] < correct_letter_counts[letter] # Word doesn't have enough of this green letter
                ):
                    return False
            elif feedback == "y": # Yellow feedback: letter must be in word, but not at this position
                if (
                    letter not in word # Yellow letter not present
                    or word[i] == letter # Yellow letter is in the same position
                    or word_letter_counts[letter] <= correct_letter_counts[letter] # Word doesn't have enough yellow letter occurrences
                ):
                    return False
            elif feedback == "b": # Black feedback: letter should not be in word (considering 'g' and 'y' counts)
                if letter in word and word_letter_counts[letter] > (
                    correct_letter_counts[letter] + present_letter_counts[letter] # Word has too many of this black letter
                ):
                    return False
        return True # Word is possible if all checks pass

    return [word for word in word_list if is_word_possible(word)] # Filter word list


def find_variable_letter_positions(word_list):
    """
    Identifies positions in words where letters vary across the word list.

    Useful for finding letters to use in filler words.
    For example, in ['gaming', 'vaping'], positions 0 and 2 vary ('g'/'v', 'm'/'p').

    Args:
        word_list (list): A list of words (assumed to be of the same length).

    Returns:
        dict: A dictionary where keys are positions (indices) and values are sets
              of unique letters found at that position across all words.
              Positions with only one unique letter (no variation) are excluded.
    """
    if not word_list:
        return {}

    word_length = len(word_list[0])
    variable_positions = {i: set() for i in range(word_length)} # Initialize sets for each position

    for word in word_list:
        for i, letter in enumerate(word):
            variable_positions[i].add(letter) # Collect letters at each position

    # Filter out positions with no letter variation
    variable_positions = {
        pos: letters for pos, letters in variable_positions.items() if len(letters) > 1
    }
    return variable_positions


def collect_variable_letters(variable_positions):
    """
    Collects all unique letters from the variable positions identified by `find_variable_letter_positions`.

    Example: For variable positions from ['gaming', 'vaping'], this would return 'gmpv'.

    Args:
        variable_positions (dict): A dictionary of variable positions from `find_variable_letter_positions`.

    Returns:
        str: A string containing all unique letters from the variable positions, sorted alphabetically.
    """
    unique_variable_letters = set()
    for letters in variable_positions.values():
        unique_variable_letters |= letters  # Union to collect unique letters

    return "".join(sorted(unique_variable_letters)) # Return sorted unique letters as a string


def find_words_with_letters(word_list, letters, n=9):
    """
    Finds filler words containing a combination of specified letters.

    Scores words based on how many of the specified letters they contain (without double-counting).
    Useful for when you need to uncover new letters using 'filler' guesses.

    Args:
        word_list (list): List of words to search within.
        letters (str): Letters to search for in filler words (e.g., "bhptw").
        n (int, optional): Maximum number of filler words to return. Defaults to 9.

    Returns:
        list: Top 'n' filler words containing the highest number of specified letters,
              sorted by score (number of specified letters) in descending order.
    """

    filtered_words = [
        word
        for word in word_list
        if any(letter in word for letter in letters) and len(word) == target_word_length # Words must contain at least one of the letters and be the correct length
    ]

    scored_words = [
        (word, sum(1 for letter in set(letters) if letter in word)) # Score based on unique letters present
        for word in filtered_words
    ]

    scored_words.sort(key=lambda x: x[1], reverse=True) # Sort by score descending

    return [word for word, score in scored_words][:n] # Return top n words


def prompt_filler_letters_input():
    """
    Prompts the user to enter letters for finding filler words.

    Returns:
        str: User-entered letters as a string (lowercase, letters only).
    """
    print("Enter letters to search for filler words (e.g., 'bhptw'):")
    letters = input().strip().lower()

    while not letters.isalpha(): # Validate input - only letters allowed
        print("\t⚠️  Use only letters for filler word search ⚠️")
        letters = input().strip().lower()

    return letters


def add_word_to_dictionary(word):
    """
    Adds a new word to the dictionary file.

    Prompts user for a valid word and adds it to the JSON dictionary file.
    Exits the script after adding the word or if the user enters 'exit'.

    Args:
        word (str): The word to add (initially provided, can be re-prompted).
    """
    def is_valid_new_word(new_word):
        """Validates a new word before adding it to the dictionary."""
        if new_word == "exit":
            sys.exit("👋  Bye! Wordle Helper closed. 👋\n") # Exit gracefully

        if len(new_word) != target_word_length:
            print(f"⚠️  Word length must be {target_word_length} characters ⚠️")
            return False

        if not new_word.isalpha():
            print("⚠️  Word must contain only letters ⚠️")
            return False
        return True

    while not is_valid_new_word(word): # Loop until a valid word or 'exit' is entered
        word = input("Enter a valid word to add or 'exit': ")

    word = word.strip().lower()
    all_words.append(word) # Add to the full word list
    with open(dictionary_filename, "w") as file:
        json.dump(all_words, file, indent=4) # Save updated dictionary to file, with indentation for readability
    sys.exit(f"✅  Added '{word}' to the dictionary. Dictionary updated. ✅\n") # Exit after successful addition

def print_intro():
    """Prints the introduction message for the Wordle solver."""
    print(
        f"\n🌟 Welcome to the Wordle Helper! 🌟\n"
        f"🔠 Word Length: {target_word_length} characters {'(with prefix)' if word_prefix else ''}\n"
        f"🔤 Prefix: '{word_prefix}'\n"
        f"📚 Dictionary: {dictionary_filename}\n"
        f"\n🔍 Let's solve Wordle! 🧩\n"
    )

def add_to_guess_dictionary(guess, feedback):
    """
    Adds the user's guess and feedback to the dictionary for future analysis.

    Args:
        guess (str): The user's guess word.
        feedback (str): The feedback received for the guess.
    """
    guess_data = {"guess": guess, "feedback": feedback}

    if os.path.exists("guesses.json"):
        with open("guesses.json", "r") as file:
            guesses = json.load(file)
    else:
        guesses = []

    guesses.append(guess_data)

    with open("guesses.json", "w") as file:
        json.dump(guesses, file, indent=4)
  

def delete_guess_dictionary():
    """Deletes the guess dictionary file."""
    if os.path.exists("guesses.json"):
        os.remove("guesses.json")
        print("🗑️  Guess dictionary deleted. 🗑️\n")
    else:
        print("🚫 Guess dictionary not found. 🚫\n")

def print_guess_dictionary():
    """
    Pretty prints the contents of the guesses.json file using the 
    feedback to color code each letter as needed using the
    colorama library. g = green, y = yellow, b = red
    """

    # come back to this later

    with open("guesses.json", "r") as file:
        guesses = json.load(file)

    for guess in guesses:
        guess_word = guess["guess"]
        feedback = guess["feedback"]
        feedback_colors = {
            "g": colorama.Fore.GREEN,
            "y": colorama.Fore.YELLOW,
            "b": colorama.Fore.RED,
        }

        feedback_colors = "".join(
            [feedback_colors.get(char, "") + char for char in feedback]
        )


        print(f"Guess: {guess_word.upper()}")
    print("")

# --- Main Game ---
if __name__ == "__main__":
    print_intro() # Print introduction message

    while True: # Main game loop
        possible_words = filter_possible_words(possible_words, get_user_guess_and_feedback()) # Filter words based on feedback
        guess_count += 1  # Increment guess count after each guess

        print_guess_dictionary() # Print the guess dictionary for reference

        if len(possible_words) > 30:
            print(f"{len(possible_words)} possible words remaining.") # Inform user if many words remain
        elif 1 < len(possible_words) <= 30:
            print(f"\n🔥 {len(possible_words)} possible words remaining: {', '.join(possible_words)} 🔥\n") # List remaining words
        elif len(possible_words) == 1:
            print(f"\n✅ Wordle solved! The word is '{possible_words[0]}'. ✅\n") # Solved!
        elif len(possible_words) == 0:
            print("🚫 No matching words found in the dictionary based on feedback. 🚫\n") # No words found

        # Handle cases where word is found or not in dictionary
        if len(possible_words) <= 1:
            delete_guess_dictionary()
            was_word_in_dictionary = input("Was your word in this dictionary? (y/n): ")
            if "n" in was_word_in_dictionary.lower():
                answer_word = input("What was the correct word? ")
                add_word_to_dictionary(answer_word) # Add word to dictionary if missing
            else:
                sys.exit("🎉 Congratulations! Wordle solved and verified. 🎉\n") # Exit on correct guess.