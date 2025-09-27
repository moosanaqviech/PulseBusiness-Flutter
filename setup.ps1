# Create Flutter project
flutter create pulse_business
cd pulse_business

# Create directory structure
New-Item -ItemType Directory -Force -Path "lib/models"
New-Item -ItemType Directory -Force -Path "lib/providers" 
New-Item -ItemType Directory -Force -Path "lib/screens/auth"
New-Item -ItemType Directory -Force -Path "lib/screens/business_setup"
New-Item -ItemType Directory -Force -Path "lib/screens/main"
New-Item -ItemType Directory -Force -Path "lib/screens/splash"
New-Item -ItemType Directory -Force -Path "lib/widgets"
New-Item -ItemType Directory -Force -Path "lib/utils"

# Remove default files
Remove-Item "lib/main.dart"
Remove-Item "test/widget_test.dart"

Write-Host "Project structure created! Now copy the code from the artifacts."