#!/usr/bin/env python3
"""
DistilBERT SMS Phishing Detection Model Training Script
This script trains a DistilBERT model for SMS phishing detection and converts it to TensorFlow Lite
"""

import os
import json
import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from transformers import (
    DistilBertTokenizer, 
    TFDistilBertForSequenceClassification,
    DistilBertConfig
)
import matplotlib.pyplot as plt
import seaborn as sns

# Configuration
class Config:
    MODEL_NAME = 'distilbert-base-uncased'
    MAX_LENGTH = 128
    BATCH_SIZE = 16
    EPOCHS = 3
    LEARNING_RATE = 2e-5
    OUTPUT_DIR = '../assets/models'
    DATA_DIR = 'data'
    
    # Model paths
    TFLITE_MODEL_PATH = os.path.join(OUTPUT_DIR, 'distilbert_sms_classifier.tflite')
    VOCAB_PATH = os.path.join(OUTPUT_DIR, 'vocab.json')
    TOKENIZER_PATH = os.path.join(OUTPUT_DIR, 'tokenizer')

def create_sample_dataset():
    """
    Create a sample SMS phishing dataset for training
    In production, replace this with your actual dataset
    """
    
    # Sample phishing SMS messages
    phishing_messages = [
        "URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify",
        "Congratulations! You've won $1000. Claim now by clicking: http://scam-lottery.com",
        "Your credit card has been blocked. Verify immediately: http://fake-visa.com/verify",
        "ALERT: Suspicious activity detected. Confirm your identity: http://phishing-site.com",
        "Your PayPal account is limited. Restore access: http://fake-paypal.com/restore",
        "Bank security notice: Update your details now: http://scam-bank.com/update",
        "Your package is held at customs. Pay fee: http://fake-shipping.com/pay",
        "Tax refund available. Claim $500: http://fake-irs.com/refund",
        "Your Netflix subscription expired. Renew: http://fake-netflix.com/renew",
        "Amazon security alert. Verify account: http://fake-amazon.com/verify",
        "Your phone bill is overdue. Pay now: http://scam-telecom.com/pay",
        "Bank loan approved. Claim $5000: http://fake-loan.com/claim",
        "Your email will be deleted. Verify: http://phishing-email.com/verify",
        "Prize notification: You won an iPhone. Claim: http://fake-prize.com/claim",
        "Your insurance claim approved. Details: http://scam-insurance.com/claim",
        "Urgent: Your social security suspended: http://fake-ssa.com/restore",
        "Your cryptocurrency wallet compromised: http://fake-crypto.com/secure",
        "Final notice: Pay outstanding debt: http://scam-debt.com/pay",
        "Your Google account accessed illegally: http://fake-google.com/secure",
        "Medicare benefits update required: http://fake-medicare.com/update"
    ]
    
    # Sample legitimate SMS messages
    legitimate_messages = [
        "Hi, how are you doing today?",
        "Thanks for the meeting yesterday. Let's follow up next week.",
        "Don't forget about dinner tonight at 7 PM.",
        "Happy birthday! Hope you have a wonderful day.",
        "The weather is beautiful today. Perfect for a walk.",
        "Can you pick up milk on your way home?",
        "Great job on the presentation today!",
        "See you at the gym tomorrow morning.",
        "The movie starts at 8 PM. Don't be late!",
        "Thanks for helping me move last weekend.",
        "Your appointment is confirmed for tomorrow at 2 PM.",
        "The package was delivered successfully.",
        "Your order has been shipped and will arrive in 2-3 days.",
        "Reminder: Your subscription renews automatically next month.",
        "Your flight is on time. Gate B12.",
        "Thank you for your purchase. Receipt attached.",
        "Your reservation is confirmed for Friday night.",
        "The meeting has been rescheduled to next Tuesday.",
        "Your prescription is ready for pickup.",
        "Welcome to our service! Here's your account information."
    ]
    
    # Create DataFrame
    data = []
    
    # Add phishing messages
    for msg in phishing_messages:
        data.append({'text': msg, 'label': 1, 'type': 'phishing'})
    
    # Add legitimate messages
    for msg in legitimate_messages:
        data.append({'text': msg, 'label': 0, 'type': 'legitimate'})
    
    # Add more variations
    phishing_variations = [
        "Click this link to verify your account immediately",
        "Your account has been compromised. Act now!",
        "Urgent action required for your security",
        "Verify your identity to prevent account closure",
        "Your payment method needs updating",
        "Suspicious login detected. Secure your account",
        "Your subscription will expire. Renew now",
        "Claim your reward before it expires",
        "Your package requires additional payment",
        "Update your billing information immediately"
    ]
    
    legitimate_variations = [
        "Looking forward to seeing you soon",
        "Thanks for the quick response",
        "Have a great weekend!",
        "The document you requested is attached",
        "Let me know if you need anything else",
        "Your order is being processed",
        "Thanks for choosing our service",
        "Your feedback is important to us",
        "Welcome to the team!",
        "Your request has been received"
    ]
    
    for msg in phishing_variations:
        data.append({'text': msg, 'label': 1, 'type': 'phishing'})
    
    for msg in legitimate_variations:
        data.append({'text': msg, 'label': 0, 'type': 'legitimate'})
    
    df = pd.DataFrame(data)
    return df

def load_or_create_dataset():
    """Load dataset from file or create sample dataset"""
    
    # Try to load existing dataset
    csv_path = os.path.join(Config.DATA_DIR, 'sms_dataset.csv')
    
    if os.path.exists(csv_path):
        print(f"Loading dataset from {csv_path}")
        df = pd.read_csv(csv_path)
    else:
        print("Creating sample dataset...")
        df = create_sample_dataset()
        
        # Save the dataset
        os.makedirs(Config.DATA_DIR, exist_ok=True)
        df.to_csv(csv_path, index=False)
        print(f"Sample dataset saved to {csv_path}")
    
    print(f"Dataset shape: {df.shape}")
    print(f"Label distribution:\n{df['label'].value_counts()}")
    
    return df

def preprocess_data(df, tokenizer):
    """Preprocess the SMS data for DistilBERT"""
    
    texts = df['text'].tolist()
    labels = df['label'].tolist()
    
    # Tokenize texts
    print("Tokenizing texts...")
    encodings = tokenizer(
        texts,
        truncation=True,
        padding=True,
        max_length=Config.MAX_LENGTH,
        return_tensors='tf'
    )
    
    return encodings, np.array(labels)

def create_tf_dataset(encodings, labels, batch_size):
    """Create TensorFlow dataset"""
    
    dataset = tf.data.Dataset.from_tensor_slices((
        {
            'input_ids': encodings['input_ids'],
            'attention_mask': encodings['attention_mask']
        },
        labels
    ))
    
    dataset = dataset.batch(batch_size)
    return dataset

def train_model():
    """Train the DistilBERT model"""
    
    print("Starting DistilBERT SMS Phishing Detection Training...")
    
    # Load dataset
    df = load_or_create_dataset()
    
    # Initialize tokenizer
    print("Loading tokenizer...")
    tokenizer = DistilBertTokenizer.from_pretrained(Config.MODEL_NAME)
    
    # Preprocess data
    encodings, labels = preprocess_data(df, tokenizer)
    
    # Split data
    print("Splitting data...")
    train_encodings, val_encodings, train_labels, val_labels = train_test_split(
        encodings, labels, test_size=0.2, random_state=42, stratify=labels
    )
    
    # Create datasets
    train_dataset = create_tf_dataset(
        {'input_ids': train_encodings['input_ids'], 'attention_mask': train_encodings['attention_mask']},
        train_labels,
        Config.BATCH_SIZE
    )
    
    val_dataset = create_tf_dataset(
        {'input_ids': val_encodings['input_ids'], 'attention_mask': val_encodings['attention_mask']},
        val_labels,
        Config.BATCH_SIZE
    )
    
    # Load model
    print("Loading DistilBERT model...")
    model = TFDistilBertForSequenceClassification.from_pretrained(
        Config.MODEL_NAME,
        num_labels=2
    )
    
    # Compile model
    optimizer = tf.keras.optimizers.Adam(learning_rate=Config.LEARNING_RATE)
    loss = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)
    metrics = ['accuracy']
    
    model.compile(optimizer=optimizer, loss=loss, metrics=metrics)
    
    # Train model
    print("Training model...")
    history = model.fit(
        train_dataset,
        validation_data=val_dataset,
        epochs=Config.EPOCHS,
        verbose=1
    )
    
    # Evaluate model
    print("Evaluating model...")
    val_loss, val_accuracy = model.evaluate(val_dataset, verbose=0)
    print(f"Validation Loss: {val_loss:.4f}")
    print(f"Validation Accuracy: {val_accuracy:.4f}")
    
    # Save tokenizer
    os.makedirs(Config.OUTPUT_DIR, exist_ok=True)
    tokenizer.save_pretrained(Config.TOKENIZER_PATH)
    
    return model, tokenizer, history

def convert_to_tflite(model, tokenizer):
    """Convert the trained model to TensorFlow Lite"""
    
    print("Converting model to TensorFlow Lite...")
    
    # Create a concrete function for conversion
    @tf.function
    def representative_dataset():
        # Sample data for quantization
        sample_texts = [
            "Your account has been suspended. Click here to verify.",
            "Hi, how are you doing today?",
            "Urgent: Update your payment information now!",
            "Thanks for the meeting yesterday."
        ]
        
        for text in sample_texts:
            encoding = tokenizer(
                text,
                truncation=True,
                padding='max_length',
                max_length=Config.MAX_LENGTH,
                return_tensors='tf'
            )
            yield [
                tf.cast(encoding['input_ids'], tf.float32),
                tf.cast(encoding['attention_mask'], tf.float32)
            ]
    
    # Convert to TensorFlow Lite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Enable optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Set representative dataset for quantization
    converter.representative_dataset = representative_dataset
    
    # Convert
    tflite_model = converter.convert()
    
    # Save the model
    with open(Config.TFLITE_MODEL_PATH, 'wb') as f:
        f.write(tflite_model)
    
    print(f"TensorFlow Lite model saved to: {Config.TFLITE_MODEL_PATH}")
    
    # Get model size
    model_size = os.path.getsize(Config.TFLITE_MODEL_PATH) / (1024 * 1024)
    print(f"Model size: {model_size:.2f} MB")
    
    return tflite_model

def create_vocabulary_file(tokenizer):
    """Create vocabulary file for Flutter app"""
    
    print("Creating vocabulary file...")
    
    # Get vocabulary
    vocab = tokenizer.get_vocab()
    
    # Create simplified vocabulary for mobile app
    # Include most common tokens and special tokens
    mobile_vocab = {}
    
    # Add special tokens
    special_tokens = ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]']
    for i, token in enumerate(special_tokens):
        if token in vocab:
            mobile_vocab[token] = vocab[token]
    
    # Add most common words (limit to reduce size)
    common_words = [
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
        'your', 'you', 'we', 'our', 'this', 'that', 'is', 'are', 'was', 'were', 'be', 'been',
        'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'can',
        'account', 'verify', 'click', 'link', 'urgent', 'immediately', 'suspended', 'blocked',
        'security', 'payment', 'card', 'bank', 'login', 'password', 'confirm', 'update',
        'congratulations', 'won', 'prize', 'claim', 'free', 'offer', 'limited', 'time',
        'hello', 'hi', 'thanks', 'thank', 'please', 'sorry', 'yes', 'no', 'ok', 'okay'
    ]
    
    for word in common_words:
        if word in vocab:
            mobile_vocab[word] = vocab[word]
    
    # Save vocabulary
    with open(Config.VOCAB_PATH, 'w') as f:
        json.dump(mobile_vocab, f, indent=2)
    
    print(f"Vocabulary saved to: {Config.VOCAB_PATH}")
    print(f"Vocabulary size: {len(mobile_vocab)} tokens")

def test_tflite_model(tflite_model_path, tokenizer):
    """Test the TensorFlow Lite model"""
    
    print("Testing TensorFlow Lite model...")
    
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
    interpreter.allocate_tensors()
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"Input details: {input_details}")
    print(f"Output details: {output_details}")
    
    # Test with sample messages
    test_messages = [
        "URGENT: Your account will be suspended. Click here to verify immediately!",
        "Hi, how are you doing today? Hope you're well.",
        "Your credit card has been blocked. Verify now: http://fake-bank.com",
        "Thanks for the meeting yesterday. Let's follow up next week."
    ]
    
    expected_labels = [1, 0, 1, 0]  # 1 = phishing, 0 = legitimate
    
    print("\nTesting predictions:")
    for i, (message, expected) in enumerate(zip(test_messages, expected_labels)):
        # Tokenize
        encoding = tokenizer(
            message,
            truncation=True,
            padding='max_length',
            max_length=Config.MAX_LENGTH,
            return_tensors='np'
        )
        
        # Set input tensor
        interpreter.set_tensor(input_details[0]['index'], encoding['input_ids'].astype(np.float32))
        interpreter.set_tensor(input_details[1]['index'], encoding['attention_mask'].astype(np.float32))
        
        # Run inference
        interpreter.invoke()
        
        # Get output
        output = interpreter.get_tensor(output_details[0]['index'])
        probabilities = tf.nn.softmax(output[0]).numpy()
        
        predicted_label = np.argmax(probabilities)
        confidence = probabilities[predicted_label]
        
        print(f"\nTest {i+1}:")
        print(f"Message: {message[:50]}...")
        print(f"Expected: {'Phishing' if expected == 1 else 'Legitimate'}")
        print(f"Predicted: {'Phishing' if predicted_label == 1 else 'Legitimate'}")
        print(f"Confidence: {confidence:.4f}")
        print(f"Correct: {'✓' if predicted_label == expected else '✗'}")

def plot_training_history(history):
    """Plot training history"""
    
    plt.figure(figsize=(12, 4))
    
    # Plot accuracy
    plt.subplot(1, 2, 1)
    plt.plot(history.history['accuracy'], label='Training Accuracy')
    plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
    plt.title('Model Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.legend()
    
    # Plot loss
    plt.subplot(1, 2, 2)
    plt.plot(history.history['loss'], label='Training Loss')
    plt.plot(history.history['val_loss'], label='Validation Loss')
    plt.title('Model Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig(os.path.join(Config.OUTPUT_DIR, 'training_history.png'))
    plt.show()

def main():
    """Main training pipeline"""
    
    print("=" * 60)
    print("DistilBERT SMS Phishing Detection Training Pipeline")
    print("=" * 60)
    
    try:
        # Train model
        model, tokenizer, history = train_model()
        
        # Convert to TensorFlow Lite
        tflite_model = convert_to_tflite(model, tokenizer)
        
        # Create vocabulary file
        create_vocabulary_file(tokenizer)
        
        # Test the TFLite model
        test_tflite_model(Config.TFLITE_MODEL_PATH, tokenizer)
        
        # Plot training history
        plot_training_history(history)
        
        print("\n" + "=" * 60)
        print("Training completed successfully!")
        print(f"Model saved to: {Config.TFLITE_MODEL_PATH}")
        print(f"Vocabulary saved to: {Config.VOCAB_PATH}")
        print(f"Tokenizer saved to: {Config.TOKENIZER_PATH}")
        print("=" * 60)
        
    except Exception as e:
        print(f"Error during training: {str(e)}")
        raise

if __name__ == "__main__":
    main()
