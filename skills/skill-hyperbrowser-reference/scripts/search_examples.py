import argparse
import os
import subprocess

REPO_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "repo")

def search_repo(query, file_extension=None):
    """
    Search the hyperbrowser-app-examples repository for a specific query.
    """
    print(f"Searching for '{query}' in {REPO_DIR}...")
    
    # We use ripgrep (rg) if available, otherwise fallback to python string matching
    # Since this script is meant to be run by the AI, the AI can also just use its native grep_search tool directly.
    # This script is a convenience wrapper if the AI prefers to run a python snippet.
    
    cmd = ["rg", query, REPO_DIR]
    if file_extension:
        cmd.extend(["-g", f"*.{file_extension}"])
        
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        else:
            print("No matches found.")
    except FileNotFoundError:
        print("ripgrep (rg) not found. Please use the AI's internal grep_search tool instead.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Search the Hyperbrowser App Examples repository.")
    parser.add_argument("query", help="The string or regex to search for.")
    parser.add_argument("--ext", help="Optional file extension to filter by (e.g., ts, tsx, md).", default=None)
    args = parser.parse_args()
    
    search_repo(args.query, args.ext)
