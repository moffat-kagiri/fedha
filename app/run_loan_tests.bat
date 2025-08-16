@echo off
REM Run loan calculator tests
cd /d "%~dp0"
flutter test test/loan_calculator_test.dart
pause
