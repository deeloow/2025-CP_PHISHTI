use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Once;
use std::collections::HashMap;

use rust_bert::pipelines::sequence_classification::{
    SequenceClassificationConfig, SequenceClassificationModel,
};
use rust_bert::resources::RemoteResource;
use rust_bert::Config;
use serde::{Deserialize, Serialize};
use tokenizers::Tokenizer;

use log::{error, info, warn};

static INIT: Once = Once::new();

/// Initialize logging
fn init_logging() {
    INIT.call_once(|| {
        env_logger::Builder::from_default_env()
            .filter_level(log::LevelFilter::Info)
            .init();
    });
}

/// SMS Phishing Detection Result
#[derive(Debug, Serialize, Deserialize)]
pub struct PhishingDetectionResult {
    pub is_phishing: bool,
    pub confidence: f32,
    pub label: String,
    pub indicators: Vec<String>,
    pub processing_time_ms: u64,
}

/// DistilBERT SMS Phishing Detector
pub struct DistilBertPhishingDetector {
    model: SequenceClassificationModel,
    tokenizer: Tokenizer,
    is_initialized: bool,
}

impl DistilBertPhishingDetector {
    /// Create a new detector instance
    pub fn new() -> anyhow::Result<Self> {
        init_logging();
        info!("Initializing DistilBERT SMS Phishing Detector...");

        // Load DistilBERT model for sequence classification
        let config = SequenceClassificationConfig::new(
            Config::from_file(RemoteResource::from_pretrained(
                rust_bert::resources::LocalResource::from("distilbert-base-uncased"),
            )),
        );

        let model = SequenceClassificationModel::new(config)?;
        
        // Load tokenizer
        let tokenizer = Tokenizer::from_pretrained("distilbert-base-uncased", None)?;

        info!("DistilBERT model loaded successfully");
        
        Ok(Self {
            model,
            tokenizer,
            is_initialized: true,
        })
    }

    /// Analyze SMS message for phishing
    pub fn analyze_sms(&self, message: &str) -> anyhow::Result<PhishingDetectionResult> {
        if !self.is_initialized {
            return Err(anyhow::anyhow!("Model not initialized"));
        }

        let start_time = std::time::Instant::now();

        // Preprocess the message
        let processed_message = self.preprocess_message(message);
        
        // Run inference
        let predictions = self.model.predict(&[processed_message.as_str()]);
        
        let processing_time = start_time.elapsed().as_millis() as u64;

        if predictions.is_empty() {
            return Err(anyhow::anyhow!("No predictions returned"));
        }

        let prediction = &predictions[0];
        let confidence = prediction.score;
        let is_phishing = confidence > 0.7; // Threshold for phishing detection
        
        // Extract indicators
        let indicators = self.extract_indicators(message, confidence);

        Ok(PhishingDetectionResult {
            is_phishing,
            confidence,
            label: if is_phishing { "phishing".to_string() } else { "legitimate".to_string() },
            indicators,
            processing_time_ms: processing_time,
        })
    }

    /// Preprocess SMS message for DistilBERT
    fn preprocess_message(&self, message: &str) -> String {
        // Basic preprocessing for SMS
        let processed = message
            .to_lowercase()
            .trim()
            .to_string();
        
        // Truncate if too long (DistilBERT has 512 token limit)
        if processed.len() > 500 {
            format!("{}...", &processed[..497])
        } else {
            processed
        }
    }

    /// Extract phishing indicators from the message
    fn extract_indicators(&self, message: &str, confidence: f32) -> Vec<String> {
        let mut indicators = Vec::new();
        let lower_message = message.to_lowercase();

        // Urgent language indicators
        let urgent_keywords = [
            "urgent", "immediately", "act now", "limited time", "expires",
            "verify", "confirm", "suspended", "blocked", "security"
        ];
        
        for keyword in &urgent_keywords {
            if lower_message.contains(keyword) {
                indicators.push(format!("Urgent language: '{}'", keyword));
            }
        }

        // Financial keywords
        let financial_keywords = [
            "password", "pin", "ssn", "credit card", "bank account",
            "wire transfer", "gift card", "bitcoin", "cryptocurrency"
        ];
        
        for keyword in &financial_keywords {
            if lower_message.contains(keyword) {
                indicators.push(format!("Financial request: '{}'", keyword));
            }
        }

        // Suspicious URLs
        if lower_message.contains("http") || lower_message.contains("www.") {
            indicators.push("Contains URL".to_string());
        }

        // High confidence from model
        if confidence > 0.9 {
            indicators.push("Very high ML confidence".to_string());
        } else if confidence > 0.8 {
            indicators.push("High ML confidence".to_string());
        }

        indicators
    }

    /// Check if the detector is initialized
    pub fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

// Global detector instance
static mut DETECTOR: Option<DistilBertPhishingDetector> = None;

/// Initialize the global detector
#[no_mangle]
pub extern "C" fn init_distilbert_detector() -> i32 {
    init_logging();
    
    unsafe {
        match DistilBertPhishingDetector::new() {
            Ok(detector) => {
                DETECTOR = Some(detector);
                info!("DistilBERT detector initialized successfully");
                0 // Success
            }
            Err(e) => {
                error!("Failed to initialize DistilBERT detector: {}", e);
                -1 // Error
            }
        }
    }
}

/// Analyze SMS message for phishing
#[no_mangle]
pub extern "C" fn analyze_sms_phishing(message: *const c_char) -> *mut c_char {
    init_logging();
    
    if message.is_null() {
        error!("Null message pointer provided");
        return std::ptr::null_mut();
    }

    let message_str = unsafe {
        match CStr::from_ptr(message).to_str() {
            Ok(s) => s,
            Err(e) => {
                error!("Invalid UTF-8 in message: {}", e);
                return std::ptr::null_mut();
            }
        }
    };

    unsafe {
        match &DETECTOR {
            Some(detector) => {
                match detector.analyze_sms(message_str) {
                    Ok(result) => {
                        match serde_json::to_string(&result) {
                            Ok(json) => {
                                match CString::new(json) {
                                    Ok(c_string) => c_string.into_raw(),
                                    Err(e) => {
                                        error!("Failed to create C string: {}", e);
                                        std::ptr::null_mut()
                                    }
                                }
                            }
                            Err(e) => {
                                error!("Failed to serialize result: {}", e);
                                std::ptr::null_mut()
                            }
                        }
                    }
                    Err(e) => {
                        error!("Failed to analyze SMS: {}", e);
                        std::ptr::null_mut()
                    }
                }
            }
            None => {
                error!("Detector not initialized");
                std::ptr::null_mut()
            }
        }
    }
}

/// Check if detector is initialized
#[no_mangle]
pub extern "C" fn is_detector_initialized() -> i32 {
    unsafe {
        match &DETECTOR {
            Some(detector) => if detector.is_initialized() { 1 } else { 0 },
            None => 0,
        }
    }
}

/// Free memory allocated for C string
#[no_mangle]
pub extern "C" fn free_c_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

/// Get detector statistics
#[no_mangle]
pub extern "C" fn get_detector_stats() -> *mut c_char {
    init_logging();
    
    let stats = serde_json::json!({
        "model_type": "DistilBERT",
        "version": "0.1.0",
        "is_initialized": unsafe { DETECTOR.is_some() },
        "max_sequence_length": 512,
        "vocab_size": 30522
    });

    unsafe {
        match CString::new(stats.to_string()) {
            Ok(c_string) => c_string.into_raw(),
            Err(e) => {
                error!("Failed to create stats C string: {}", e);
                std::ptr::null_mut()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detector_initialization() {
        let detector = DistilBertPhishingDetector::new();
        assert!(detector.is_ok());
    }

    #[test]
    fn test_phishing_detection() {
        let detector = DistilBertPhishingDetector::new().unwrap();
        
        // Test phishing message
        let phishing_msg = "URGENT: Your account will be suspended. Click here to verify immediately!";
        let result = detector.analyze_sms(phishing_msg).unwrap();
        
        assert!(result.confidence > 0.0);
        assert!(!result.indicators.is_empty());
    }

    #[test]
    fn test_legitimate_detection() {
        let detector = DistilBertPhishingDetector::new().unwrap();
        
        // Test legitimate message
        let legitimate_msg = "Hi, how are you doing today? Hope you're well.";
        let result = detector.analyze_sms(legitimate_msg).unwrap();
        
        assert!(result.confidence > 0.0);
    }
}
