use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Once;
use serde::{Deserialize, Serialize};

static INIT: Once = Once::new();

/// Initialize logging
fn init_logging() {
    INIT.call_once(|| {
        println!("Rust ML Service initialized (mock version)");
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

/// Mock DistilBERT SMS Phishing Detector
pub struct MockDistilBertPhishingDetector {
    is_initialized: bool,
}

impl MockDistilBertPhishingDetector {
    /// Create a new detector instance
    pub fn new() -> anyhow::Result<Self> {
        init_logging();
        println!("Initializing Mock DistilBERT SMS Phishing Detector...");
        
        Ok(Self {
            is_initialized: true,
        })
    }

    /// Analyze SMS message for phishing using mock ML logic
    pub fn analyze_sms(&self, message: &str) -> anyhow::Result<PhishingDetectionResult> {
        if !self.is_initialized {
            return Err(anyhow::anyhow!("Model not initialized"));
        }

        let start_time = std::time::Instant::now();
        
        // Mock ML analysis - simulate DistilBERT behavior
        let (is_phishing, confidence, indicators) = self.mock_ml_analysis(message);
        
        let processing_time = start_time.elapsed().as_millis() as u64;

        Ok(PhishingDetectionResult {
            is_phishing,
            confidence,
            label: if is_phishing { "phishing".to_string() } else { "legitimate".to_string() },
            indicators,
            processing_time_ms: processing_time,
        })
    }

    /// Mock ML analysis that simulates DistilBERT behavior
    fn mock_ml_analysis(&self, message: &str) -> (bool, f32, Vec<String>) {
        let mut indicators = Vec::new();
        let lower_message = message.to_lowercase();
        
        let mut phishing_score = 0.0;
        
        // Urgent language detection (high weight)
        let urgent_keywords = [
            "urgent", "immediately", "act now", "limited time", "expires",
            "verify", "confirm", "suspended", "blocked", "security", "click here"
        ];
        
        for keyword in &urgent_keywords {
            if lower_message.contains(keyword) {
                phishing_score += 0.3;
                indicators.push(format!("Urgent language: '{}'", keyword));
            }
        }

        // Financial keywords (high weight)
        let financial_keywords = [
            "password", "pin", "ssn", "credit card", "bank account",
            "wire transfer", "gift card", "bitcoin", "cryptocurrency",
            "account", "login", "verify account"
        ];
        
        for keyword in &financial_keywords {
            if lower_message.contains(keyword) {
                phishing_score += 0.25;
                indicators.push(format!("Financial request: '{}'", keyword));
            }
        }

        // Suspicious URLs (medium weight)
        if lower_message.contains("http") || lower_message.contains("www.") || lower_message.contains(".com") {
            phishing_score += 0.2;
            indicators.push("Contains URL".to_string());
        }

        // Suspicious sender patterns
        if lower_message.contains("bank") || lower_message.contains("paypal") || lower_message.contains("amazon") {
            phishing_score += 0.15;
            indicators.push("Suspicious sender pattern".to_string());
        }

        // Add some randomness to simulate ML uncertainty
        let random_factor = (message.len() as f32 % 10.0) / 100.0;
        phishing_score += random_factor;
        
        // Cap the score
        phishing_score = phishing_score.min(1.0);
        
        // Determine if phishing based on threshold
        let is_phishing = phishing_score > 0.6;
        
        // Add ML confidence indicator
        if phishing_score > 0.9 {
            indicators.push("Very high ML confidence".to_string());
        } else if phishing_score > 0.8 {
            indicators.push("High ML confidence".to_string());
        } else if phishing_score > 0.7 {
            indicators.push("Moderate ML confidence".to_string());
        }

        (is_phishing, phishing_score, indicators)
    }

    /// Check if the detector is initialized
    pub fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

// Global detector instance
static mut DETECTOR: Option<MockDistilBertPhishingDetector> = None;

/// Initialize the global detector
#[no_mangle]
pub extern "C" fn init_distilbert_detector() -> i32 {
    init_logging();
    
    unsafe {
        match MockDistilBertPhishingDetector::new() {
            Ok(detector) => {
                DETECTOR = Some(detector);
                println!("Mock DistilBERT detector initialized successfully");
                0 // Success
            }
            Err(e) => {
                println!("Failed to initialize Mock DistilBERT detector: {}", e);
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
        println!("Null message pointer provided");
        return std::ptr::null_mut();
    }

    let message_str = unsafe {
        match CStr::from_ptr(message).to_str() {
            Ok(s) => s,
            Err(e) => {
                println!("Invalid UTF-8 in message: {}", e);
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
                                        println!("Failed to create C string: {}", e);
                                        std::ptr::null_mut()
                                    }
                                }
                            }
                            Err(e) => {
                                println!("Failed to serialize result: {}", e);
                                std::ptr::null_mut()
                            }
                        }
                    }
                    Err(e) => {
                        println!("Failed to analyze SMS: {}", e);
                        std::ptr::null_mut()
                    }
                }
            }
            None => {
                println!("Detector not initialized");
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
        "model_type": "Mock DistilBERT",
        "version": "0.1.0",
        "is_initialized": unsafe { DETECTOR.is_some() },
        "max_sequence_length": 512,
        "vocab_size": 30522,
        "note": "Mock implementation for testing - simulates DistilBERT behavior"
    });

    unsafe {
        match CString::new(stats.to_string()) {
            Ok(c_string) => c_string.into_raw(),
            Err(e) => {
                println!("Failed to create stats C string: {}", e);
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
        let detector = MockDistilBertPhishingDetector::new();
        assert!(detector.is_ok());
    }

    #[test]
    fn test_phishing_detection() {
        let detector = MockDistilBertPhishingDetector::new().unwrap();
        
        // Test phishing message
        let phishing_msg = "URGENT: Your account will be suspended. Click here to verify immediately!";
        let result = detector.analyze_sms(phishing_msg).unwrap();
        
        assert!(result.confidence > 0.0);
        assert!(!result.indicators.is_empty());
    }

    #[test]
    fn test_legitimate_detection() {
        let detector = MockDistilBertPhishingDetector::new().unwrap();
        
        // Test legitimate message
        let legitimate_msg = "Hi, how are you doing today? Hope you're well.";
        let result = detector.analyze_sms(legitimate_msg).unwrap();
        
        assert!(result.confidence > 0.0);
    }
}