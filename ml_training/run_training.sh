#!/bin/bash

echo "==============================================="
echo "SMS Phishing Detection Model Training"
echo "==============================================="

echo "Setting up environment..."
python3 setup_training_environment.py

if [ $? -ne 0 ]; then
    echo "Setup failed! Please check the error messages above."
    exit 1
fi

echo ""
echo "Starting model training..."
python3 train_distilbert_sms_phishing.py

if [ $? -ne 0 ]; then
    echo "Training failed! Please check the error messages above."
    exit 1
fi

echo ""
echo "==============================================="
echo "Training completed successfully!"
echo "==============================================="
echo ""
echo "Model files have been saved to:"
echo "- ../assets/models/distilbert_sms_classifier.tflite"
echo "- ../assets/models/vocab.json"
echo ""
echo "You can now use these models in your Flutter app."
echo ""
