"""
Tests for the Wordle Solver Cloud Functions
"""

import unittest
from unittest.mock import Mock, patch
import json
from main import (
    calculate_letter_frequency,
    normalize_letter_frequencies,
    calculate_guess_score,
    filter_possible_words,
    recommend_guesses,
    find_variable_letter_positions
)


class TestWordleSolverFunctions(unittest.TestCase):
    
    def setUp(self):
        """Set up test data"""
        self.test_words = [
            "apple", "apply", "crane", "slate", "audio", "house", "mouse", "about"
        ]
        self.five_letter_words = ["apple", "crane", "slate", "audio", "house", "mouse", "about"]
    
    def test_calculate_letter_frequency(self):
        """Test letter frequency calculation"""
        frequencies = calculate_letter_frequency(self.five_letter_words, 5)
        
        # Should return a dictionary
        self.assertIsInstance(frequencies, dict)
        
        # Should contain common letters
        self.assertIn('a', frequencies)
        self.assertIn('e', frequencies)
        
        # Frequencies should be positive numbers
        for freq in frequencies.values():
            self.assertGreater(freq, 0)
    
    def test_normalize_letter_frequencies(self):
        """Test letter frequency normalization"""
        frequencies = {'a': 20.0, 'b': 10.0, 'c': 5.0}
        normalized = normalize_letter_frequencies(frequencies)
        
        # Should return values between 0 and 10
        for score in normalized.values():
            self.assertGreaterEqual(score, 0)
            self.assertLessEqual(score, 10)
        
        # Highest frequency should get score 10
        self.assertEqual(normalized['a'], 10.0)
        
        # Lowest frequency should get score 0
        self.assertEqual(normalized['c'], 0.0)
    
    def test_calculate_guess_score(self):
        """Test word scoring"""
        letter_scores = {'a': 10, 'p': 5, 'l': 3, 'e': 8}
        
        # Test without duplicate counting (first 2 guesses)
        score = calculate_guess_score("apple", letter_scores, guess_count=1)
        expected = 10 + 5 + 3 + 8  # unique letters: a, p, l, e
        self.assertEqual(score, expected)
        
        # Test with duplicate counting (3rd guess onwards)
        score = calculate_guess_score("apple", letter_scores, guess_count=3)
        expected = 10 + 5 + 5 + 3 + 8  # all letters: a, p, p, l, e
        self.assertEqual(score, expected)
    
    def test_filter_possible_words(self):
        """Test word filtering based on feedback"""
        test_words = ["crane", "slate", "audio", "house"]
        
        # Test green feedback (correct position)
        feedback = [('c', 'g'), ('r', 'b'), ('a', 'b'), ('n', 'b'), ('e', 'b')]
        filtered = filter_possible_words(test_words, feedback)
        
        # Should only keep words starting with 'c'
        for word in filtered:
            self.assertEqual(word[0], 'c')
    
    def test_recommend_guesses(self):
        """Test word recommendation"""
        recommendations = recommend_guesses(self.five_letter_words, 5, None, n=3, guess_count=1)
        
        # Should return list of tuples (word, score)
        self.assertIsInstance(recommendations, list)
        self.assertLessEqual(len(recommendations), 3)
        
        if recommendations:
            word, score = recommendations[0]
            self.assertIsInstance(word, str)
            self.assertIsInstance(score, float)
            self.assertEqual(len(word), 5)
    
    def test_find_variable_letter_positions(self):
        """Test variable position detection"""
        words = ["crane", "slate", "audio"]
        variable_positions = find_variable_letter_positions(words)
        
        # Should return dictionary of positions to letter sets
        self.assertIsInstance(variable_positions, dict)
        
        # Position 0 should vary (c, s, a)
        if 0 in variable_positions:
            self.assertGreater(len(variable_positions[0]), 1)
    
    def test_empty_word_list(self):
        """Test functions with empty word lists"""
        # Should handle empty lists gracefully
        frequencies = calculate_letter_frequency([], 5)
        self.assertEqual(frequencies, {})
        
        normalized = normalize_letter_frequencies({})
        self.assertEqual(normalized, {})
        
        recommendations = recommend_guesses([], 5, None)
        self.assertEqual(recommendations, [])
    
    def test_prefix_filtering(self):
        """Test prefix-based filtering"""
        words_with_prefix = ["apple", "apply", "about"]
        frequencies = calculate_letter_frequency(words_with_prefix, 5, prefix="ap")
        
        # Should only analyze letters after the prefix
        self.assertIsInstance(frequencies, dict)
        
        recommendations = recommend_guesses(words_with_prefix, 5, prefix="ap")
        for word, score in recommendations:
            self.assertTrue(word.startswith("ap"))


class TestEdgeCases(unittest.TestCase):
    
    def test_single_letter_frequency(self):
        """Test frequency calculation with single letter words"""
        words = ["a", "b", "a"]
        frequencies = calculate_letter_frequency(words, 1)
        
        # 'a' should have higher frequency than 'b'
        self.assertGreater(frequencies.get('a', 0), frequencies.get('b', 0))
    
    def test_identical_frequencies(self):
        """Test normalization with identical frequencies"""
        frequencies = {'a': 10.0, 'b': 10.0, 'c': 10.0}
        normalized = normalize_letter_frequencies(frequencies)
        
        # All should get the same score (5.0 - middle value)
        for score in normalized.values():
            self.assertEqual(score, 5.0)
    
    def test_invalid_feedback_characters(self):
        """Test filtering with edge case feedback"""
        words = ["crane", "slate"]
        
        # Empty feedback should return all words
        filtered = filter_possible_words(words, [])
        self.assertEqual(len(filtered), len(words))


if __name__ == '__main__':
    unittest.main()
