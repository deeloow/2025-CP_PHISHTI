#!/usr/bin/env python3
"""
Setup script for SMS phishing detection training environment
"""

import os
import subprocess
import sys
import urllib.request
import zipfile
import pandas as pd

def install_requirements():
    """Install required packages"""
    print("Installing required packages...")
    
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✓ Requirements installed successfully")
    except subprocess.CalledProcessError as e:
        print(f"✗ Error installing requirements: {e}")
        return False
    
    return True

def download_sample_datasets():
    """Download sample SMS datasets for training"""
    print("Setting up sample datasets...")
    
    # Create data directory
    data_dir = "data"
    os.makedirs(data_dir, exist_ok=True)
    
    # Create enhanced sample dataset
    phishing_messages = [
        # Banking phishing
        "URGENT: Your account will be suspended. Click here to verify: http://fake-bank.com/verify",
        "Your credit card has been blocked. Verify immediately: http://fake-visa.com/verify",
        "Bank security notice: Update your details now: http://scam-bank.com/update",
        "Your account has been compromised. Secure it now: http://phishing-bank.com/secure",
        "Suspicious transaction detected. Confirm: http://fake-banking.com/confirm",
        
        # Prize/lottery scams
        "Congratulations! You've won $1000. Claim now: http://scam-lottery.com",
        "You're our lucky winner! Claim $5000: http://fake-prize.com/claim",
        "Prize notification: You won an iPhone. Claim: http://fake-contest.com/claim",
        "Lottery winner! Collect your $10000: http://scam-lottery.org/collect",
        "You've won a gift card! Claim here: http://fake-rewards.com/gift",
        
        # Tech support scams
        "Your computer is infected. Download fix: http://fake-antivirus.com/fix",
        "Microsoft security alert. Update now: http://fake-microsoft.com/update",
        "Your device has been hacked. Secure: http://scam-security.com/secure",
        "Virus detected on your phone. Clean: http://fake-cleaner.com/clean",
        "System update required. Install: http://fake-update.com/install",
        
        # Social media/email scams
        "Your Facebook account suspended. Restore: http://fake-facebook.com/restore",
        "Gmail storage full. Upgrade now: http://fake-gmail.com/upgrade",
        "Your Instagram was hacked. Secure: http://fake-instagram.com/secure",
        "LinkedIn premium expired. Renew: http://fake-linkedin.com/renew",
        "Twitter account locked. Unlock: http://fake-twitter.com/unlock",
        
        # Shopping/delivery scams
        "Your package is held. Pay customs fee: http://fake-shipping.com/pay",
        "Amazon order cancelled. Reorder: http://fake-amazon.com/reorder",
        "Delivery failed. Reschedule: http://scam-delivery.com/reschedule",
        "Your order is ready. Confirm: http://fake-shop.com/confirm",
        "Package delivery fee required: http://scam-post.com/fee",
        
        # Financial scams
        "Tax refund available. Claim $500: http://fake-irs.com/refund",
        "Loan approved instantly. Apply: http://scam-loan.com/apply",
        "Investment opportunity. Invest now: http://fake-invest.com/invest",
        "Crypto wallet compromised. Secure: http://fake-crypto.com/secure",
        "Insurance claim approved. Details: http://scam-insurance.com/claim",
        
        # Subscription scams
        "Netflix subscription expired. Renew: http://fake-netflix.com/renew",
        "Spotify premium cancelled. Restore: http://fake-spotify.com/restore",
        "Your subscription will expire. Renew: http://scam-service.com/renew",
        "Premium account suspended. Reactivate: http://fake-premium.com/activate",
        "Service interruption. Update payment: http://scam-billing.com/update",
        
        # Government/legal scams
        "Social security suspended. Restore: http://fake-ssa.com/restore",
        "Legal notice: Respond immediately: http://fake-legal.com/respond",
        "Court summons. View details: http://scam-court.com/summons",
        "IRS audit notice. Respond now: http://fake-audit.com/respond",
        "Immigration status update: http://fake-immigration.com/update",
        
        # Urgent action scams
        "FINAL NOTICE: Act now or lose access",
        "IMMEDIATE ACTION REQUIRED: Verify account",
        "LAST WARNING: Update information now",
        "URGENT RESPONSE NEEDED: Security breach",
        "TIME SENSITIVE: Confirm identity now"
    ]
    
    legitimate_messages = [
        # Personal messages
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
        
        # Business messages
        "Your appointment is confirmed for tomorrow at 2 PM.",
        "The meeting has been rescheduled to next Tuesday.",
        "Please review the attached document.",
        "Your request has been processed successfully.",
        "Thank you for your feedback. We appreciate it.",
        "The project deadline has been extended to Friday.",
        "Your application has been received and is under review.",
        "Welcome to the team! Looking forward to working with you.",
        "The conference call will start in 10 minutes.",
        "Your timesheet has been approved.",
        
        # Service notifications (legitimate)
        "Your order has been shipped and will arrive in 2-3 days.",
        "Your prescription is ready for pickup.",
        "Your flight is on time. Gate B12.",
        "Your reservation is confirmed for Friday night.",
        "Thank you for your purchase. Receipt attached.",
        "Your subscription renews automatically next month.",
        "Your package was delivered successfully.",
        "Your payment has been processed successfully.",
        "Your account balance is $1,234.56.",
        "Your monthly statement is now available.",
        
        # Social messages
        "Looking forward to seeing you at the party!",
        "Thanks for the recommendation. I'll check it out.",
        "Have a great weekend! See you Monday.",
        "Congratulations on your promotion!",
        "Hope you feel better soon. Take care.",
        "The photos from the trip look amazing!",
        "Thanks for the birthday wishes!",
        "Let me know when you're free to chat.",
        "Hope your vacation is going well!",
        "Thanks for the book recommendation.",
        
        # Informational messages
        "The library will be closed tomorrow for maintenance.",
        "School pickup time has changed to 3:30 PM.",
        "The gym will have extended hours this weekend.",
        "Your doctor's appointment is confirmed.",
        "The restaurant is fully booked tonight.",
        "Your car service is scheduled for Monday.",
        "The event has been moved to the main hall.",
        "Your table is ready. Please come in.",
        "The store will close early today at 6 PM.",
        "Your class has been moved to room 205."
    ]
    
    # Create dataset
    data = []
    
    # Add phishing messages
    for msg in phishing_messages:
        data.append({
            'text': msg,
            'label': 1,
            'type': 'phishing',
            'length': len(msg),
            'has_url': 'http' in msg.lower(),
            'has_urgent': any(word in msg.lower() for word in ['urgent', 'immediate', 'final', 'last'])
        })
    
    # Add legitimate messages
    for msg in legitimate_messages:
        data.append({
            'text': msg,
            'label': 0,
            'type': 'legitimate',
            'length': len(msg),
            'has_url': 'http' in msg.lower(),
            'has_urgent': any(word in msg.lower() for word in ['urgent', 'immediate', 'final', 'last'])
        })
    
    # Create DataFrame and save
    df = pd.DataFrame(data)
    df.to_csv(os.path.join(data_dir, 'sms_dataset.csv'), index=False)
    
    print(f"✓ Sample dataset created with {len(df)} messages")
    print(f"  - Phishing messages: {len(df[df['label'] == 1])}")
    print(f"  - Legitimate messages: {len(df[df['label'] == 0])}")
    
    return True

def create_directory_structure():
    """Create necessary directory structure"""
    print("Creating directory structure...")
    
    directories = [
        "data",
        "models",
        "outputs",
        "../assets/models"
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"✓ Created directory: {directory}")
    
    return True

def verify_installation():
    """Verify that all required packages are installed"""
    print("Verifying installation...")
    
    required_packages = [
        'tensorflow',
        'transformers',
        'pandas',
        'numpy',
        'sklearn'
    ]
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package} is available")
        except ImportError:
            print(f"✗ {package} is not available")
            return False
    
    return True

def main():
    """Main setup function"""
    print("=" * 60)
    print("SMS Phishing Detection Training Environment Setup")
    print("=" * 60)
    
    steps = [
        ("Creating directory structure", create_directory_structure),
        ("Installing requirements", install_requirements),
        ("Downloading sample datasets", download_sample_datasets),
        ("Verifying installation", verify_installation)
    ]
    
    for step_name, step_func in steps:
        print(f"\n{step_name}...")
        if not step_func():
            print(f"✗ Failed: {step_name}")
            return False
        print(f"✓ Completed: {step_name}")
    
    print("\n" + "=" * 60)
    print("Setup completed successfully!")
    print("\nNext steps:")
    print("1. Run: python train_distilbert_sms_phishing.py")
    print("2. The trained model will be saved to ../assets/models/")
    print("3. Copy the model files to your Flutter app's assets folder")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
