#!/bin/bash

# ATHLETEHUB Test Runner
# 
# This script runs all tests including:
# - Flutter unit tests
# - Flutter integration tests
# - Firebase Emulator tests
# - Cloud Functions tests
# - Security rules tests

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Flutter
    if ! command_exists flutter; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    # Check Firebase CLI
    if ! command_exists firebase; then
        print_error "Firebase CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "This script must be run from the Flutter project root directory."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to run Flutter tests
run_flutter_tests() {
    print_status "Running Flutter unit tests..."
    
    if flutter test; then
        print_success "Flutter unit tests passed!"
    else
        print_error "Flutter unit tests failed!"
        return 1
    fi
}

# Function to run Flutter integration tests
run_flutter_integration_tests() {
    print_status "Running Flutter integration tests..."
    
    if [ -d "integration_test" ]; then
        if flutter test integration_test/; then
            print_success "Flutter integration tests passed!"
        else
            print_error "Flutter integration tests failed!"
            return 1
        fi
    else
        print_warning "No integration tests found. Skipping..."
    fi
}

# Function to run Firebase Emulator tests
run_firebase_emulator_tests() {
    print_status "Starting Firebase emulators..."
    
    # Start emulators in background
    firebase emulators:start --only firestore,functions,auth &
    EMULATOR_PID=$!
    
    # Wait for emulators to be ready
    print_status "Waiting for emulators to be ready..."
    sleep 10
    
    # Check if emulators are running
    for i in {1..30}; do
        if curl -s http://localhost:8080 >/dev/null 2>&1 && \
           curl -s http://localhost:5001 >/dev/null 2>&1 && \
           curl -s http://localhost:9099 >/dev/null 2>&1; then
            print_success "Emulators are ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Emulators failed to start within 30 seconds"
            kill $EMULATOR_PID 2>/dev/null || true
            return 1
        fi
        sleep 1
    done
    
    # Run Cloud Functions tests
    print_status "Running Cloud Functions tests..."
    if node test/functions_test.js; then
        print_success "Cloud Functions tests passed!"
    else
        print_error "Cloud Functions tests failed!"
        kill $EMULATOR_PID 2>/dev/null || true
        return 1
    fi
    
    # Run security rules tests
    print_status "Running security rules tests..."
    if node test/security_rules_test.js; then
        print_success "Security rules tests passed!"
    else
        print_error "Security rules tests failed!"
        kill $EMULATOR_PID 2>/dev/null || true
        return 1
    fi
    
    # Stop emulators
    print_status "Stopping emulators..."
    kill $EMULATOR_PID 2>/dev/null || true
    sleep 2
    
    # Make sure emulators are stopped
    pkill -f firebase 2>/dev/null || true
}

# Function to run all tests
run_all_tests() {
    print_status "Starting ATHLETEHUB test suite..."
    echo "=========================================="
    
    local exit_code=0
    
    # Run Flutter tests
    if ! run_flutter_tests; then
        exit_code=1
    fi
    echo ""
    
    # Run Flutter integration tests
    if ! run_flutter_integration_tests; then
        exit_code=1
    fi
    echo ""
    
    # Run Firebase emulator tests
    if ! run_firebase_emulator_tests; then
        exit_code=1
    fi
    echo ""
    
    # Report results
    if [ $exit_code -eq 0 ]; then
        print_success "All tests passed! 🎉"
        echo "=========================================="
    else
        print_error "Some tests failed! ❌"
        echo "=========================================="
    fi
    
    return $exit_code
}

# Function to show help
show_help() {
    echo "ATHLETEHUB Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --flutter  Run only Flutter tests"
    echo "  -e, --emulator Run only Firebase emulator tests"
    echo "  -a, --all      Run all tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all tests"
    echo "  $0 --flutter       # Run only Flutter tests"
    echo "  $0 --emulator      # Run only emulator tests"
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--flutter)
            check_prerequisites
            run_flutter_tests
            run_flutter_integration_tests
            ;;
        -e|--emulator)
            check_prerequisites
            run_firebase_emulator_tests
            ;;
        -a|--all|"")
            check_prerequisites
            run_all_tests
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"