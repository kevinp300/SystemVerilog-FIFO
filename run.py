import subprocess
import sys
import os
from datetime import datetime

# Configuration
REPORT_DIR = "reports"
DO_FILE = "run.do"

def get_timestamp():
    return datetime.now().strftime("%Y%m%d_%H%M%S")

def run_simulation():
    # 1. Setup Reporting
    if not os.path.exists(REPORT_DIR):
        os.makedirs(REPORT_DIR)
    
    log_filename = os.path.join(REPORT_DIR, f"regression_{get_timestamp()}.log")
    
    print("-" * 50)
    print(f"STARTING: IBM FIFO Regression Test...")
    print(f"LOG FILE: {log_filename}")
    print("-" * 50)

    # 2. Run ModelSim
    cmd = ["vsim", "-c", "-do", "do run.do"]

    try:
        # Run process and capture output
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        combined_output = result.stdout + result.stderr
        
        # 3. Analyze Results (Parsing)
        status = "UNKNOWN"
        if "VIOLATION" in combined_output:
            status = "PASSED"
            summary = "[PASS] SUCCESS: Protocol Violation Detected (Overflow caught)."
        elif "Error" in combined_output:
            status = "FAILED"
            summary = "[FAIL] CRITICAL: Simulation crashed with unexpected errors."
        else:
            status = "WARNING"
            summary = "[WARN] WARNING: Simulation finished but Assertion didn't trigger."

        # 4. Write to Log File
        # We can stick to standard encoding now since there are no special characters
        with open(log_filename, "w") as f:
            f.write("="*60 + "\n")
            f.write(f"IBM STORAGE - DESIGN VERIFICATION REPORT\n")
            f.write(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("="*60 + "\n\n")
            
            f.write("--- SIMULATION LOG ---\n")
            f.write(combined_output)
            
            f.write("\n" + "="*60 + "\n")
            f.write(f"TEST STATUS: {status}\n")
            f.write(f"SUMMARY:     {summary}\n")
            f.write("="*60 + "\n")

        # 5. Print Summary to Console
        print(summary)
        return True if status == "PASSED" else False

    except FileNotFoundError:
        print("\n[ERROR] ModelSim 'vsim' command not found.")
        return False

if __name__ == "__main__":
    success = run_simulation()
    sys.exit(0 if success else 1)