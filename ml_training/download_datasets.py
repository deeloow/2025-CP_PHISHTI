#!/usr/bin/env python3
"""
Dataset Download Script for SMS Phishing Detection
Downloads and processes SMS spam and malicious URL datasets
"""

import os
import pandas as pd
import requests
import zipfile
import json
from urllib.parse import urlparse
import re

class DatasetDownloader:
    def __init__(self):
        self.data_dir = 'data'
        self.sms_dataset_path = os.path.join(self.data_dir, 'sms_spam_collection.csv')
        self.url_dataset_path = os.path.join(self.data_dir, 'malicious_urls.csv')
        
        # Create data directory
        os.makedirs(self.data_dir, exist_ok=True)
    
    def download_sms_dataset(self):
        """Download and process SMS spam collection dataset"""
        print("Downloading SMS Spam Collection Dataset...")
        
        # SMS Spam Collection Dataset URL (UCI ML Repository)
        sms_url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip"
        
        try:
            # Download the dataset
            response = requests.get(sms_url)
            response.raise_for_status()
            
            # Save zip file
            zip_path = os.path.join(self.data_dir, 'sms_spam_collection.zip')
            with open(zip_path, 'wb') as f:
                f.write(response.content)
            
            # Extract zip file
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(self.data_dir)
            
            # Find the extracted file
            extracted_files = [f for f in os.listdir(self.data_dir) if f.endswith('.txt')]
            if extracted_files:
                sms_file = os.path.join(self.data_dir, extracted_files[0])
                
                # Read and process the SMS data
                with open(sms_file, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                # Parse SMS data
                data = []
                for line in lines:
                    line = line.strip()
                    if line:
                        parts = line.split('\t', 1)
                        if len(parts) == 2:
                            label = parts[0].lower()
                            text = parts[1]
                            
                            # Convert labels
                            if label == 'spam':
                                label_num = 1
                                label_type = 'phishing'
                            else:  # ham
                                label_num = 0
                                label_type = 'legitimate'
                            
                            data.append({
                                'text': text,
                                'label': label_num,
                                'type': label_type,
                                'original_label': label
                            })
                
                # Create DataFrame and save
                df = pd.DataFrame(data)
                df.to_csv(self.sms_dataset_path, index=False)
                
                print(f"SMS dataset saved to: {self.sms_dataset_path}")
                print(f"SMS dataset shape: {df.shape}")
                print(f"SMS label distribution:\n{df['label'].value_counts()}")
                
                # Clean up
                os.remove(zip_path)
                if os.path.exists(sms_file):
                    os.remove(sms_file)
                
                return df
                
        except Exception as e:
            print(f"Error downloading SMS dataset: {e}")
            return self.create_sample_sms_dataset()
    
    def create_sample_sms_dataset(self):
        """Create a sample SMS dataset if download fails"""
        print("Creating sample SMS dataset...")
        
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
            "Medicare benefits update required: http://fake-medicare.com/update",
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
            "Welcome to our service! Here's your account information.",
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
        
        # Create DataFrame
        data = []
        
        # Add phishing messages
        for msg in phishing_messages:
            data.append({
                'text': msg,
                'label': 1,
                'type': 'phishing',
                'original_label': 'spam'
            })
        
        # Add legitimate messages
        for msg in legitimate_messages:
            data.append({
                'text': msg,
                'label': 0,
                'type': 'legitimate',
                'original_label': 'ham'
            })
        
        df = pd.DataFrame(data)
        df.to_csv(self.sms_dataset_path, index=False)
        
        print(f"Sample SMS dataset saved to: {self.sms_dataset_path}")
        print(f"SMS dataset shape: {df.shape}")
        print(f"SMS label distribution:\n{df['label'].value_counts()}")
        
        return df
    
    def download_url_dataset(self):
        """Download and process malicious URL dataset"""
        print("Downloading Malicious URL Dataset...")
        
        # Sample malicious URLs (since we can't directly download from Kaggle without API)
        malicious_urls = [
            "http://fake-bank.com/verify",
            "http://scam-lottery.com",
            "http://fake-visa.com/verify",
            "http://phishing-site.com",
            "http://fake-paypal.com/restore",
            "http://scam-bank.com/update",
            "http://fake-shipping.com/pay",
            "http://fake-irs.com/refund",
            "http://fake-netflix.com/renew",
            "http://fake-amazon.com/verify",
            "http://scam-telecom.com/pay",
            "http://fake-loan.com/claim",
            "http://phishing-email.com/verify",
            "http://fake-prize.com/claim",
            "http://scam-insurance.com/claim",
            "http://fake-ssa.com/restore",
            "http://fake-crypto.com/secure",
            "http://scam-debt.com/pay",
            "http://fake-google.com/secure",
            "http://fake-medicare.com/update",
            "http://malicious-site.com/steal-data",
            "http://phishing-bank.com/login",
            "http://fake-apple.com/verify",
            "http://scam-microsoft.com/update",
            "http://fake-facebook.com/login",
            "http://phishing-twitter.com/verify",
            "http://fake-instagram.com/secure",
            "http://scam-whatsapp.com/verify",
            "http://fake-youtube.com/claim",
            "http://phishing-linkedin.com/update"
        ]
        
        # Sample legitimate URLs
        legitimate_urls = [
            "https://www.google.com",
            "https://www.github.com",
            "https://www.stackoverflow.com",
            "https://www.wikipedia.org",
            "https://www.reddit.com",
            "https://www.youtube.com",
            "https://www.amazon.com",
            "https://www.netflix.com",
            "https://www.spotify.com",
            "https://www.dropbox.com",
            "https://www.slack.com",
            "https://www.trello.com",
            "https://www.notion.so",
            "https://www.figma.com",
            "https://www.canva.com",
            "https://www.medium.com",
            "https://www.dev.to",
            "https://www.codepen.io",
            "https://www.jsfiddle.net",
            "https://www.repl.it",
            "https://www.kaggle.com",
            "https://www.coursera.org",
            "https://www.edx.org",
            "https://www.udemy.com",
            "https://www.freecodecamp.org",
            "https://www.codecademy.com",
            "https://www.w3schools.com",
            "https://www.mozilla.org",
            "https://www.apache.org",
            "https://www.python.org"
        ]
        
        # Create DataFrame
        data = []
        
        # Add malicious URLs
        for url in malicious_urls:
            data.append({
                'url': url,
                'label': 1,
                'type': 'malicious',
                'domain': urlparse(url).netloc,
                'path': urlparse(url).path,
                'is_https': url.startswith('https://'),
                'url_length': len(url),
                'has_suspicious_keywords': self.has_suspicious_keywords(url)
            })
        
        # Add legitimate URLs
        for url in legitimate_urls:
            data.append({
                'url': url,
                'label': 0,
                'type': 'legitimate',
                'domain': urlparse(url).netloc,
                'path': urlparse(url).path,
                'is_https': url.startswith('https://'),
                'url_length': len(url),
                'has_suspicious_keywords': self.has_suspicious_keywords(url)
            })
        
        df = pd.DataFrame(data)
        df.to_csv(self.url_dataset_path, index=False)
        
        print(f"URL dataset saved to: {self.url_dataset_path}")
        print(f"URL dataset shape: {df.shape}")
        print(f"URL label distribution:\n{df['label'].value_counts()}")
        
        return df
    
    def has_suspicious_keywords(self, url):
        """Check if URL contains suspicious keywords"""
        suspicious_keywords = [
            'fake', 'scam', 'phishing', 'malicious', 'steal', 'hack',
            'verify', 'confirm', 'update', 'secure', 'restore', 'claim',
            'urgent', 'immediately', 'suspended', 'blocked', 'limited'
        ]
        
        url_lower = url.lower()
        return any(keyword in url_lower for keyword in suspicious_keywords)
    
    def create_combined_dataset(self, sms_df, url_df):
        """Create a combined dataset for training"""
        print("Creating combined dataset...")
        
        # Extract URLs from SMS messages
        sms_with_urls = []
        for _, row in sms_df.iterrows():
            text = row['text']
            urls = self.extract_urls(text)
            
            if urls:
                for url in urls:
                    sms_with_urls.append({
                        'text': text,
                        'url': url,
                        'sms_label': row['label'],
                        'sms_type': row['type'],
                        'domain': urlparse(url).netloc,
                        'path': urlparse(url).path,
                        'is_https': url.startswith('https://'),
                        'url_length': len(url),
                        'has_suspicious_keywords': self.has_suspicious_keywords(url)
                    })
        
        if sms_with_urls:
            combined_df = pd.DataFrame(sms_with_urls)
            combined_path = os.path.join(self.data_dir, 'combined_sms_urls.csv')
            combined_df.to_csv(combined_path, index=False)
            
            print(f"Combined dataset saved to: {combined_path}")
            print(f"Combined dataset shape: {combined_df.shape}")
            
            return combined_df
        
        return None
    
    def extract_urls(self, text):
        """Extract URLs from text"""
        url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
        urls = re.findall(url_pattern, text)
        return urls
    
    def create_dataset_summary(self, sms_df, url_df, combined_df=None):
        """Create a summary of the datasets"""
        summary = {
            'sms_dataset': {
                'total_messages': len(sms_df),
                'phishing_messages': len(sms_df[sms_df['label'] == 1]),
                'legitimate_messages': len(sms_df[sms_df['label'] == 0]),
                'phishing_percentage': (len(sms_df[sms_df['label'] == 1]) / len(sms_df)) * 100
            },
            'url_dataset': {
                'total_urls': len(url_df),
                'malicious_urls': len(url_df[url_df['label'] == 1]),
                'legitimate_urls': len(url_df[url_df['label'] == 0]),
                'malicious_percentage': (len(url_df[url_df['label'] == 1]) / len(url_df)) * 100
            }
        }
        
        if combined_df is not None:
            summary['combined_dataset'] = {
                'total_entries': len(combined_df),
                'entries_with_urls': len(combined_df)
            }
        
        # Save summary
        summary_path = os.path.join(self.data_dir, 'dataset_summary.json')
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"Dataset summary saved to: {summary_path}")
        return summary
    
    def download_all_datasets(self):
        """Download and process all datasets"""
        print("=" * 60)
        print("Downloading and Processing Datasets")
        print("=" * 60)
        
        # Download SMS dataset
        sms_df = self.download_sms_dataset()
        
        # Download URL dataset
        url_df = self.download_url_dataset()
        
        # Create combined dataset
        combined_df = self.create_combined_dataset(sms_df, url_df)
        
        # Create summary
        summary = self.create_dataset_summary(sms_df, url_df, combined_df)
        
        print("\n" + "=" * 60)
        print("Dataset Download Complete!")
        print("=" * 60)
        print(f"SMS Dataset: {len(sms_df)} messages")
        print(f"URL Dataset: {len(url_df)} URLs")
        if combined_df is not None:
            print(f"Combined Dataset: {len(combined_df)} entries")
        print("=" * 60)
        
        return sms_df, url_df, combined_df

def main():
    """Main function"""
    downloader = DatasetDownloader()
    sms_df, url_df, combined_df = downloader.download_all_datasets()
    
    print("\nDatasets are ready for training!")
    print("Run the training script to train the model with these datasets.")

if __name__ == "__main__":
    main()
