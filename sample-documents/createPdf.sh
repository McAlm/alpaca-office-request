# This script creates a PDF document from a given input file using a specified tool or library.
# Usage: ./createPdf.sh input_file output_file
#!/bin/bash
for f in *.txt; do
  cupsfilter -m application/pdf "$f" > "${f%.txt}.pdf" 2>/dev/null
done