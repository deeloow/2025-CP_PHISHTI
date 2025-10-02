@echo off
echo ===============================================
echo SMS Phishing Detection Model Training
echo ===============================================

echo Setting up environment...
python setup_training_environment.py

if %ERRORLEVEL% NEQ 0 (
    echo Setup failed! Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo Starting model training...
python train_distilbert_sms_phishing.py

if %ERRORLEVEL% NEQ 0 (
    echo Training failed! Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ===============================================
echo Training completed successfully!
echo ===============================================
echo.
echo Model files have been saved to:
echo - ../assets/models/distilbert_sms_classifier.tflite
echo - ../assets/models/vocab.json
echo.
echo You can now use these models in your Flutter app.
echo.
pause
