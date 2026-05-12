"""
Fix issues in auto-generated RDL models:
1. Remove duplicate brand/source_system/ingest_date/ingest_ts lines
2. Fix indentation in history CTE
"""
import os, re, glob

RDL_ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'models', 'rdl'))

def fix_model(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    if 'is_latest' not in ''.join(lines):
        return  # not converted yet
    
    fixed = []
    seen_brand = False
    seen_source = False
    seen_ingest_date = False
    seen_ingest_ts = False
    in_final_select = False
    
    for i, line in enumerate(lines):
        s = line.strip()
        
        # Track if we're in the final SELECT (after FROM versioned block)
        if s.startswith('SELECT') and i > 5:
            in_final_select = True
            seen_brand = False
            seen_source = False
            seen_ingest_date = False
            seen_ingest_ts = False
        
        if in_final_select:
            # Remove duplicate lines
            if "'Unknown' AS brand" in s:
                continue
            if "'unknown' AS source_system" in s:
                continue
            if s == 'ingest_date,' and seen_ingest_date:
                continue
            if s == 'ingest_ts,' and seen_ingest_ts:
                continue
            if 'AS brand' in s and seen_brand:
                continue
            if 'AS source_system' in s and seen_source:
                continue
            
            if 'ingest_date' in s and 'AS' not in s:
                seen_ingest_date = True
            if 'ingest_ts' in s and 'AS' not in s:
                seen_ingest_ts = True
            if 'AS brand' in s:
                seen_brand = True
            if 'AS source_system' in s:
                seen_source = True
        
        # Fix indentation: if line is inside WITH history and not indented
        if not in_final_select and i > 6 and i < 30:
            if s and not line.startswith(' ') and not line.startswith('-') and not line.startswith('WITH') and not line.startswith('FROM') and not line.startswith(')'):
                line = '        ' + s + '\n'
        
        fixed.append(line)
    
    result = ''.join(fixed)
    
    # Fix trailing comma before FROM versioned
    result = re.sub(r',\s*\nFROM versioned', '\nFROM versioned', result)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(result)
    print(f"  FIXED: {os.path.basename(filepath)}")

def main():
    files = sorted(glob.glob(os.path.join(RDL_ROOT, '**', '*.sql'), recursive=True))
    for f in files:
        fix_model(f)
    print("Done.")

if __name__ == '__main__':
    main()
