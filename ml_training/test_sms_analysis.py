#!/usr/bin/env python3
"""
Test SMS Analysis Function
Tests the SMS analysis functionality with real datasets
"""

import os
import pandas as pd
import json
import re
from urllib.parse import urlparse

class SMSAnalyzer:
    def __init__(self):
        self.suspicious_keywords = [
            'urgent', 'immediately', 'suspended', 'blocked', 'verify', 'confirm',
            'click', 'link', 'congratulations', 'won', 'prize', 'claim', 'free',
            'limited', 'time', 'expire', 'security', 'alert', 'warning', 'action',
            'required', 'update', 'payment', 'card', 'bank', 'account', 'login',
            'password', 'restore', 'secure', 'compromised', 'illegal', 'fraud',
            'scam', 'phishing', 'malicious', 'fake', 'steal', 'hack'
        ]
        
        self.suspicious_domains = [
            'fake-bank.com', 'scam-lottery.com', 'fake-visa.com', 'phishing-site.com',
            'fake-paypal.com', 'scam-bank.com', 'fake-shipping.com', 'fake-irs.com',
            'fake-netflix.com', 'fake-amazon.com', 'scam-telecom.com', 'fake-loan.com',
            'phishing-email.com', 'fake-prize.com', 'scam-insurance.com', 'fake-ssa.com',
            'fake-crypto.com', 'scam-debt.com', 'fake-google.com', 'fake-medicare.com'
        ]
    
    def analyze_sms(self, text):
        """Analyze SMS message for phishing indicators"""
        analysis = {
            'text': text,
            'is_phishing': False,
            'phishing_score': 0.0,
            'indicators': [],
            'extracted_urls': [],
            'confidence': 0.0
        }
        
        # Extract URLs
        urls = self.extract_urls(text)
        analysis['extracted_urls'] = urls
        
        # Check for suspicious keywords
        keyword_score = self.check_suspicious_keywords(text)
        if keyword_score > 0:
            analysis['indicators'].append(f"Suspicious keywords detected (score: {keyword_score})")
            analysis['phishing_score'] += keyword_score * 0.3
        
        # Check for suspicious URLs
        url_score = self.check_suspicious_urls(urls)
        if url_score > 0:
            analysis['indicators'].append(f"Suspicious URLs detected (score: {url_score})")
            analysis['phishing_score'] += url_score * 0.4
        
        # Check for urgency indicators
        urgency_score = self.check_urgency_indicators(text)
        if urgency_score > 0:
            analysis['indicators'].append(f"Urgency indicators detected (score: {urgency_score})")
            analysis['phishing_score'] += urgency_score * 0.2
        
        # Check for financial keywords
        financial_score = self.check_financial_keywords(text)
        if financial_score > 0:
            analysis['indicators'].append(f"Financial keywords detected (score: {financial_score})")
            analysis['phishing_score'] += financial_score * 0.1
        
        # Normalize score to 0-1 range
        analysis['phishing_score'] = min(analysis['phishing_score'], 1.0)
        
        # Determine if phishing
        analysis['is_phishing'] = analysis['phishing_score'] > 0.5
        
        # Calculate confidence
        analysis['confidence'] = abs(analysis['phishing_score'] - 0.5) * 2
        
        return analysis
    
    def extract_urls(self, text):
        """Extract URLs from text"""
        url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
        urls = re.findall(url_pattern, text)
        return urls
    
    def check_suspicious_keywords(self, text):
        """Check for suspicious keywords"""
        text_lower = text.lower()
        score = 0
        
        for keyword in self.suspicious_keywords:
            if keyword in text_lower:
                score += 1
        
        return min(score / len(self.suspicious_keywords) * 10, 1.0)
    
    def check_suspicious_urls(self, urls):
        """Check for suspicious URLs"""
        if not urls:
            return 0
        
        score = 0
        for url in urls:
            domain = urlparse(url).netloc.lower()
            
            # Check against suspicious domains
            if any(suspicious in domain for suspicious in self.suspicious_domains):
                score += 1
            
            # Check for suspicious patterns
            if any(pattern in domain for pattern in ['fake', 'scam', 'phishing']):
                score += 1
            
            # Check for non-HTTPS
            if not url.startswith('https://'):
                score += 0.5
        
        return min(score / len(urls), 1.0)
    
    def check_urgency_indicators(self, text):
        """Check for urgency indicators"""
        urgency_patterns = [
            r'\b(urgent|immediately|asap|right now|hurry|quick|fast)\b',
            r'\b(expire|expired|expiring|deadline|limited time)\b',
            r'\b(suspended|blocked|locked|frozen|terminated)\b',
            r'\b(action required|immediate action|act now)\b'
        ]
        
        text_lower = text.lower()
        score = 0
        
        for pattern in urgency_patterns:
            matches = re.findall(pattern, text_lower)
            score += len(matches)
        
        return min(score / 5, 1.0)
    
    def check_financial_keywords(self, text):
        """Check for financial keywords"""
        financial_keywords = [
            'payment', 'card', 'bank', 'account', 'money', 'cash', 'dollar',
            'credit', 'debit', 'transaction', 'transfer', 'deposit', 'withdraw',
            'balance', 'statement', 'bill', 'invoice', 'refund', 'charge'
        ]
        
        text_lower = text.lower()
        score = 0
        
        for keyword in financial_keywords:
            if keyword in text_lower:
                score += 1
        
        return min(score / len(financial_keywords) * 5, 1.0)

def test_sms_analysis():
    """Test SMS analysis with dataset"""
    print("=" * 60)
    print("Testing SMS Analysis Function")
    print("=" * 60)
    
    # Initialize analyzer
    analyzer = SMSAnalyzer()
    
    # Load dataset
    data_dir = 'data'
    sms_csv_path = os.path.join(data_dir, 'sms_spam_collection.csv')
    
    if not os.path.exists(sms_csv_path):
        print(f"Dataset not found at {sms_csv_path}")
        print("Please run download_datasets.py first")
        return
    
    df = pd.read_csv(sms_csv_path)
    print(f"Loaded dataset with {len(df)} messages")
    
    # Test with sample messages
    test_messages = [
        "URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify",
        "Hi, how are you doing today? Hope you're well.",
        "Your credit card has been blocked. Verify now: http://fake-visa.com",
        "Thanks for the meeting yesterday. Let's follow up next week.",
        "Congratulations! You've won $1000. Claim now: http://scam-lottery.com",
        "Don't forget about dinner tonight at 7 PM.",
        "Your PayPal account is limited. Restore access: http://fake-paypal.com/restore",
        "The weather is beautiful today. Perfect for a walk."
    ]
    
    print("\nTesting with sample messages:")
    print("-" * 60)
    
    correct_predictions = 0
    total_predictions = len(test_messages)
    
    for i, message in enumerate(test_messages):
        analysis = analyzer.analyze_sms(message)
        
        # Expected label (1 for phishing, 0 for legitimate)
        expected = 1 if any(keyword in message.lower() for keyword in ['urgent', 'suspended', 'blocked', 'congratulations', 'won', 'limited']) else 0
        predicted = 1 if analysis['is_phishing'] else 0
        
        is_correct = predicted == expected
        if is_correct:
            correct_predictions += 1
        
        print(f"\nTest {i+1}:")
        print(f"Message: {message[:50]}...")
        print(f"Expected: {'Phishing' if expected == 1 else 'Legitimate'}")
        print(f"Predicted: {'Phishing' if predicted == 1 else 'Legitimate'}")
        print(f"Score: {analysis['phishing_score']:.3f}")
        print(f"Confidence: {analysis['confidence']:.3f}")
        print(f"Correct: {'✓' if is_correct else '✗'}")
        if analysis['indicators']:
            print(f"Indicators: {', '.join(analysis['indicators'])}")
    
    # Calculate accuracy
    accuracy = correct_predictions / total_predictions
    print(f"\n" + "=" * 60)
    print(f"Test Results:")
    print(f"Correct Predictions: {correct_predictions}/{total_predictions}")
    print(f"Accuracy: {accuracy:.3f} ({accuracy*100:.1f}%)")
    print("=" * 60)
    
    # Test with actual dataset samples
    print("\nTesting with dataset samples:")
    print("-" * 60)
    
    # Test phishing messages
    phishing_samples = df[df['label'] == 1].head(5)
    print(f"\nTesting {len(phishing_samples)} phishing samples:")
    
    phishing_correct = 0
    for _, row in phishing_samples.iterrows():
        analysis = analyzer.analyze_sms(row['text'])
        predicted = 1 if analysis['is_phishing'] else 0
        if predicted == 1:
            phishing_correct += 1
        
        print(f"Message: {row['text'][:50]}...")
        print(f"Predicted: {'Phishing' if predicted == 1 else 'Legitimate'}")
        print(f"Score: {analysis['phishing_score']:.3f}")
        print(f"Correct: {'✓' if predicted == 1 else '✗'}")
        print()
    
    # Test legitimate messages
    legitimate_samples = df[df['label'] == 0].head(5)
    print(f"\nTesting {len(legitimate_samples)} legitimate samples:")
    
    legitimate_correct = 0
    for _, row in legitimate_samples.iterrows():
        analysis = analyzer.analyze_sms(row['text'])
        predicted = 1 if analysis['is_phishing'] else 0
        if predicted == 0:
            legitimate_correct += 1
        
        print(f"Message: {row['text'][:50]}...")
        print(f"Predicted: {'Phishing' if predicted == 1 else 'Legitimate'}")
        print(f"Score: {analysis['phishing_score']:.3f}")
        print(f"Correct: {'✓' if predicted == 0 else '✗'}")
        print()
    
    # Overall accuracy on dataset samples
    total_dataset_samples = len(phishing_samples) + len(legitimate_samples)
    total_correct = phishing_correct + legitimate_correct
    dataset_accuracy = total_correct / total_dataset_samples
    
    print("=" * 60)
    print(f"Dataset Test Results:")
    print(f"Phishing Detection: {phishing_correct}/{len(phishing_samples)} ({phishing_correct/len(phishing_samples)*100:.1f}%)")
    print(f"Legitimate Detection: {legitimate_correct}/{len(legitimate_samples)} ({legitimate_correct/len(legitimate_samples)*100:.1f}%)")
    print(f"Overall Accuracy: {total_correct}/{total_dataset_samples} ({dataset_accuracy*100:.1f}%)")
    print("=" * 60)

def main():
    """Main function"""
    test_sms_analysis()

if __name__ == "__main__":
    main()
