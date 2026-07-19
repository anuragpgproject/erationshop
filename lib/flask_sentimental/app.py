from flask import Flask, request, jsonify
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from flask_cors import CORS
import emoji

app = Flask(__name__)

# Enable CORS for all routes
CORS(app)

# Initialize the sentiment analyzer
analyzer = SentimentIntensityAnalyzer()

# Define custom positive and negative emojis
positive_emojis = ['😊', '😁', '😍', '❤️', '👍', '😃', '😄', '😆']
negative_emojis = ['😞', '😡', '😔', '👎', '😣', '😢', '😒']

# Function to convert emojis to text
def convert_emojis_to_text(text):
    # Convert emojis to text
    return emoji.demojize(text)

# Function to calculate custom sentiment based on emojis
def calculate_emoji_sentiment(text):
    score = 0
    # Check for positive emojis
    for emoji_char in positive_emojis:
        if emoji_char in text:
            score += 1  # Positive sentiment for each positive emoji
    # Check for negative emojis
    for emoji_char in negative_emojis:
        if emoji_char in text:
            score -= 1  # Negative sentiment for each negative emoji
    return score

# Define a route to accept feedback and analyze sentiment
@app.route('/analyze', methods=['POST'])
def analyze_sentiment():
    try:
        # Get the feedback text from the request body
        feedback = request.json.get('feedback', '')

        if not feedback:
            return jsonify({'error': 'Feedback is required!'}), 400

        # Convert emojis to text for initial sentiment analysis
        feedback_text = convert_emojis_to_text(feedback)

        # Perform sentiment analysis on the text
        sentiment_score = analyzer.polarity_scores(feedback_text)

        # Get the custom sentiment score based on emojis
        emoji_sentiment_score = calculate_emoji_sentiment(feedback)

        # Adjust the overall sentiment score with the emoji sentiment score
        adjusted_score = sentiment_score['compound'] + emoji_sentiment_score * 0.1  # Adjust factor (e.g., 0.1) can be tuned

        # Determine if it's positive or negative sentiment based on the adjusted score
        sentiment = "positive" if adjusted_score > 0 else "negative"

        # Return the sentiment result
        return jsonify({
            'sentiment': sentiment,
            'score': adjusted_score
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# For PythonAnywhere deployment, we don't need to specify `app.run()` here.
# PythonAnywhere takes care of running the app.

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)  # Optional: Ensure it listens on the correct port.
