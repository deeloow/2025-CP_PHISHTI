#!/usr/bin/env python3
"""
Test script for the trained DistilBERT SMS phishing detection model
"""

import os
import json
import numpy as np
import tensorflow as tf
from transformers import DistilBertTokenizer

def load_model_and_tokenizer():
    """Load the trained model and tokenizer"""
    
    model_path = "../assets/models/distilbert_sms_classifier.tflite"
    tokenizer_path = "../assets/models/tokenizer"
    vocab_path = "../assets/models/vocab.json"
    
    # Check if files exist
    if not os.path.exists(model_path):
        print(f"❌ Model file not found: {model_path}")
        print("Please run the training script first: python train_distilbert_sms_phishing.py")
        return None, None
    
    # Load TensorFlow Lite model
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    
    # Load tokenizer
    if os.path.exists(tokenizer_path):
        tokenizer = DistilBertTokenizer.from_pretrained(tokenizer_path)
    else:
        print("⚠️ Tokenizer not found, using default DistilBERT tokenizer")
        tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-uncased')
    
    print("✅ Model and tokenizer loaded successfully")
    return interpreter, tokenizer

def predict_message(interpreter, tokenizer, message, max_length=128):
    """Predict if a message is phishing or legitimate"""
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Tokenize the message
    encoding = tokenizer(
        message,
        truncation=True,
        padding='max_length',
        max_length=max_length,
        return_tensors='np'
    )
    
    # Set input tensors
    interpreter.set_tensor(input_details[0]['index'], encoding['input_ids'].astype(np.float32))
    interpreter.set_tensor(input_details[1]['index'], encoding['attention_mask'].astype(np.float32))
    
    # Run inference
    interpreter.invoke()
    
    # Get output
    output = interpreter.get_tensor(output_details[0]['index'])
    probabilities = tf.nn.softmax(output[0]).numpy()
    
    # Get prediction
    predicted_class = np.argmax(probabilities)
    confidence = probabilities[predicted_class]
    
    return {
        'message': message,
        'prediction': 'Phishing' if predicted_class == 1 else 'Legitimate',
        'confidence': float(confidence),
        'phishing_probability': float(probabilities[1]),
        'legitimate_probability': float(probabilities[0])
    }

def run_test_cases():
    """Run test cases on various SMS messages"""
    
    print("🧪 Loading model for testing...")
    interpreter, tokenizer = load_model_and_tokenizer()
    
    if interpreter is None or tokenizer is None:
        return
    
    # Test messages
    test_cases = [
        # Phishing messages
        {
            'message': "URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify",
            'expected': 'Phishing'
        },
        {
            'message': "Congratulations! You've won $1000. Claim now by clicking: http://scam-lottery.com",
            'expected': 'Phishing'
        },
        {
            'message': "Your credit card has been blocked. Verify immediately: http://fake-visa.com/verify",
            'expected': 'Phishing'
        },
        {
            'message': "ALERT: Suspicious activity detected. Confirm your identity now!",
            'expected': 'Phishing'
        },
        {
            'message': "Your PayPal account is limited. Restore access: http://fake-paypal.com/restore",
            'expected': 'Phishing'
        },
        
        # Legitimate messages
        {
            'message': "Hi, how are you doing today? Hope you're well.",
            'expected': 'Legitimate'
        },
        {
            'message': "Thanks for the meeting yesterday. Let's follow up next week.",
            'expected': 'Legitimate'
        },
        {
            'message': "Your appointment is confirmed for tomorrow at 2 PM.",
            'expected': 'Legitimate'
        },
        {
            'message': "The package was delivered successfully. Thank you for your order.",
            'expected': 'Legitimate'
        },
        {
            'message': "Happy birthday! Hope you have a wonderful day.",
            'expected': 'Legitimate'
        }
    ]
    
    print("\n" + "="*80)
    print("🔍 TESTING SMS PHISHING DETECTION MODEL")
    print("="*80)
    
    correct_predictions = 0
    total_predictions = len(test_cases)
    
    for i, test_case in enumerate(test_cases, 1):
        message = test_case['message']
        expected = test_case['expected']
        
        # Make prediction
        result = predict_message(interpreter, tokenizer, message)
        
        # Check if prediction is correct
        is_correct = result['prediction'] == expected
        if is_correct:
            correct_predictions += 1
        
        # Display result
        print(f"\n📱 Test Case {i}:")
        print(f"Message: {message[:60]}{'...' if len(message) > 60 else ''}")
        print(f"Expected: {expected}")
        print(f"Predicted: {result['prediction']}")
        print(f"Confidence: {result['confidence']:.4f}")
        print(f"Phishing Prob: {result['phishing_probability']:.4f}")
        print(f"Result: {'✅ CORRECT' if is_correct else '❌ INCORRECT'}")
    
    # Calculate accuracy
    accuracy = correct_predictions / total_predictions
    
    print("\n" + "="*80)
    print("📊 TEST RESULTS SUMMARY")
    print("="*80)
    print(f"Total Test Cases: {total_predictions}")
    print(f"Correct Predictions: {correct_predictions}")
    print(f"Incorrect Predictions: {total_predictions - correct_predictions}")
    print(f"Accuracy: {accuracy:.2%}")
    
    if accuracy >= 0.8:
        print("🎉 Model performance is GOOD!")
    elif accuracy >= 0.6:
        print("⚠️ Model performance is FAIR - consider retraining with more data")
    else:
        print("❌ Model performance is POOR - retraining recommended")
    
    return accuracy

def interactive_test():
    """Interactive testing mode"""
    
    print("🧪 Loading model for interactive testing...")
    interpreter, tokenizer = load_model_and_tokenizer()
    
    if interpreter is None or tokenizer is None:
        return
    
    print("\n" + "="*60)
    print("🔍 INTERACTIVE SMS PHISHING DETECTION TEST")
    print("="*60)
    print("Enter SMS messages to test (type 'quit' to exit):")
    print("-" * 60)
    
    while True:
        try:
            message = input("\n📱 Enter SMS message: ").strip()
            
            if message.lower() in ['quit', 'exit', 'q']:
                print("👋 Goodbye!")
                break
            
            if not message:
                print("⚠️ Please enter a message")
                continue
            
            # Make prediction
            result = predict_message(interpreter, tokenizer, message)
            
            # Display result
            print(f"\n🔍 Analysis Results:")
            print(f"Message: {message}")
            print(f"Prediction: {result['prediction']}")
            print(f"Confidence: {result['confidence']:.4f}")
            print(f"Phishing Probability: {result['phishing_probability']:.4f}")
            
            if result['prediction'] == 'Phishing':
                print("🚨 WARNING: This message appears to be PHISHING!")
            else:
                print("✅ This message appears to be legitimate.")
            
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {str(e)}")

def main():
    """Main test function"""
    
    print("🚀 DistilBERT SMS Phishing Detection Model Tester")
    print("=" * 60)
    
    while True:
        print("\nChoose testing mode:")
        print("1. Run predefined test cases")
        print("2. Interactive testing")
        print("3. Exit")
        
        choice = input("\nEnter your choice (1-3): ").strip()
        
        if choice == '1':
            run_test_cases()
        elif choice == '2':
            interactive_test()
        elif choice == '3':
            print("👋 Goodbye!")
            break
        else:
            print("❌ Invalid choice. Please enter 1, 2, or 3.")

if __name__ == "__main__":
    main()
