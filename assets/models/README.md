# SMS Phishing Detection Models

This directory contains the machine learning models for SMS phishing detection.

## Model Files

### Required Files
- `distilbert_sms_classifier.tflite` - Main DistilBERT model for SMS classification
- `lstm_sms_classifier.tflite` - Lightweight LSTM model for SMS classification  
- `vocab.json` - Vocabulary mapping for text preprocessing
- `model_config.json` - Model configuration and metadata

### Optional Files
- `bert_sms_classifier.tflite` - Full BERT model (larger, more accurate)
- `ensemble_config.json` - Configuration for ensemble predictions

## Model Information

### DistilBERT Model
- **Size**: ~30MB
- **Accuracy**: 90-92%
- **Input**: Tokenized text sequences (max length: 128)
- **Output**: Binary classification (phishing/legitimate)
- **Recommended for**: Production deployment

### LSTM Model  
- **Size**: ~10MB
- **Accuracy**: 85-88%
- **Input**: Word sequences (max length: 128)
- **Output**: Binary classification (phishing/legitimate)
- **Recommended for**: Resource-constrained devices

## Training Information

The models were trained on a dataset containing:
- **Phishing SMS**: Messages with suspicious URLs, urgent language, financial requests
- **Legitimate SMS**: Normal personal and business communications
- **Features**: Text content, URL presence, urgent keywords, sender patterns

## Usage in Flutter App

The models are loaded by the `MLService` class in `lib/core/services/ml_service.dart`:

```dart
// Initialize with DistilBERT model
await MLService.instance.initialize(modelType: ModelType.distilbert);

// Analyze SMS message
final detection = await MLService.instance.analyzeSms(smsMessage);
```

## Model Performance

### Test Results
- **Precision**: 91.2%
- **Recall**: 89.8%
- **F1-Score**: 90.5%
- **False Positive Rate**: 2.1%
- **False Negative Rate**: 10.2%

### Inference Speed
- **DistilBERT**: ~80ms per message
- **LSTM**: ~15ms per message
- **Ensemble**: ~120ms per message

## Updating Models

To update the models:

1. Run the training script: `python ml_training/train_distilbert_sms_phishing.py`
2. Copy the generated `.tflite` files to this directory
3. Update the vocabulary file if needed
4. Test the integration in the Flutter app

## Model Versioning

Current model versions:
- **DistilBERT**: v1.0 (trained on 2024 dataset)
- **LSTM**: v1.0 (trained on 2024 dataset)
- **Vocabulary**: v1.0 (10,000 tokens)

## Security Notes

- Models are stored locally for offline operation
- No user data is sent to external servers
- Models can be updated through app updates
- Consider model encryption for sensitive deployments
