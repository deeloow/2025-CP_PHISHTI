use rust_ml::DistilBertPhishingDetector;

fn main() -> anyhow::Result<()> {
    env_logger::init();
    
    println!("Testing DistilBERT SMS Phishing Detection");
    println!("==========================================");
    
    // Initialize detector
    let detector = DistilBertPhishingDetector::new()?;
    
    // Test messages
    let test_messages = vec![
        ("URGENT: Your account will be suspended. Click here to verify immediately!", true),
        ("Hi, how are you doing today? Hope you're well.", false),
        ("Your credit card has been blocked. Verify now: http://fake-bank.com", true),
        ("Thanks for the meeting yesterday. Let's follow up next week.", false),
        ("Congratulations! You've won $1000. Claim now by clicking: http://scam-lottery.com", true),
        ("Don't forget about dinner tonight at 7 PM.", false),
        ("Your PayPal account is limited. Restore access: http://fake-paypal.com/restore", true),
        ("The weather is beautiful today. Perfect for a walk.", false),
        ("Bank security notice: Update your details now: http://scam-bank.com/update", true),
        ("Your package was delivered successfully.", false),
    ];
    
    let mut correct_predictions = 0;
    let mut total_predictions = test_messages.len();
    
    for (i, (message, expected_phishing)) in test_messages.iter().enumerate() {
        println!("\nTest {}: {}", i + 1, message);
        println!("Expected: {}", if *expected_phishing { "Phishing" } else { "Legitimate" });
        
        match detector.analyze_sms(message) {
            Ok(result) => {
                let predicted_phishing = result.is_phishing;
                let is_correct = predicted_phishing == *expected_phishing;
                
                println!("Predicted: {}", if predicted_phishing { "Phishing" } else { "Legitimate" });
                println!("Confidence: {:.4}", result.confidence);
                println!("Processing Time: {}ms", result.processing_time_ms);
                println!("Indicators: {:?}", result.indicators);
                println!("Correct: {}", if is_correct { "✓" } else { "✗" });
                
                if is_correct {
                    correct_predictions += 1;
                }
            }
            Err(e) => {
                println!("Error: {}", e);
            }
        }
    }
    
    let accuracy = (correct_predictions as f32 / total_predictions as f32) * 100.0;
    println!("\n==========================================");
    println!("Test Results:");
    println!("Correct Predictions: {}/{}", correct_predictions, total_predictions);
    println!("Accuracy: {:.2}%", accuracy);
    
    Ok(())
}
